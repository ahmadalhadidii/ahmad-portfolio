$ErrorActionPreference = 'Stop'

$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$output = Join-Path (Resolve-Path '.').Path 'runtime-validation\manmatic-regression'
$profile = Join-Path $env:TEMP ('manmatic-regression-' + (Get-Date -Format 'yyyyMMddHHmmssfff'))
$process = $null
$httpProcess = $null
$socket = $null
$script:messageId = 0

New-Item -ItemType Directory -Force -Path $output | Out-Null

function Receive-Message {
  $buffer = New-Object byte[] 1048576
  $stream = [System.IO.MemoryStream]::new()
  do {
    $segment = [System.ArraySegment[byte]]::new($buffer)
    $received = $socket.ReceiveAsync($segment, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
    if ($received.Count -gt 0) { $stream.Write($buffer, 0, $received.Count) }
  } until ($received.EndOfMessage)
  $text = [System.Text.Encoding]::UTF8.GetString($stream.ToArray())
  $stream.Dispose()
  return $text
}

function Invoke-Cdp([string]$method, $params = $null) {
  $script:messageId++
  $id = $script:messageId
  $payload = @{ id = $id; method = $method }
  if ($null -ne $params) { $payload.params = $params }
  $bytes = [System.Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Depth 30 -Compress))
  $segment = [System.ArraySegment[byte]]::new($bytes)
  $null = $socket.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
  do {
    $response = (Receive-Message) | ConvertFrom-Json
  } until ($response.id -eq $id)
  if ($response.error) { throw "$method failed: $($response.error.message)" }
  return $response.result
}

function Evaluate([string]$expression) {
  $result = Invoke-Cdp 'Runtime.evaluate' @{ expression = $expression; returnByValue = $true; awaitPromise = $true }
  return $result.result.value
}

function Wait-ForReady {
  for ($i = 0; $i -lt 120; $i++) {
    if ((Evaluate 'document.readyState') -eq 'complete') { return }
    Start-Sleep -Milliseconds 50
  }
  throw 'Page load timed out.'
}

function Navigate([string]$url) {
  $null = Invoke-Cdp 'Page.navigate' @{ url = $url }
  Wait-ForReady
}

function Screenshot([string]$name) {
  $result = Invoke-Cdp 'Page.captureScreenshot' @{ format = 'png'; fromSurface = $true }
  $path = Join-Path $output $name
  [System.IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($result.data))
  return $path
}

try {
  try {
    $null = Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:4173/' -TimeoutSec 1
  } catch {
    $serverOut = Join-Path $output 'verification-server.log'
    $serverErr = Join-Path $output 'verification-server-error.log'
    $httpProcess = Start-Process -FilePath python -ArgumentList @('-m','http.server','4173','--bind','127.0.0.1') -WorkingDirectory (Resolve-Path '.').Path -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr -PassThru -WindowStyle Hidden
    for ($i = 0; $i -lt 40; $i++) {
      try {
        $null = Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:4173/' -TimeoutSec 1
        break
      } catch {
        Start-Sleep -Milliseconds 100
      }
    }
  }

  $process = Start-Process -FilePath $chrome -ArgumentList @(
    '--headless=new',
    '--disable-gpu',
    '--disable-background-timer-throttling',
    '--disable-backgrounding-occluded-windows',
    '--disable-renderer-backgrounding',
    '--no-first-run',
    '--remote-debugging-port=0',
    '--remote-allow-origins=*',
    "--user-data-dir=$profile",
    'about:blank'
  ) -PassThru -WindowStyle Hidden

  $portFile = Join-Path $profile 'DevToolsActivePort'
  $deadline = (Get-Date).AddSeconds(15)
  while (-not (Test-Path $portFile) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 50 }
  if (-not (Test-Path $portFile)) { throw 'Chrome DevTools endpoint did not start.' }

  $port = [int](Get-Content $portFile | Select-Object -First 1)
  $targets = Invoke-RestMethod "http://127.0.0.1:$port/json/list"
  $target = $targets | Where-Object { $_.type -eq 'page' } | Select-Object -First 1
  if (-not $target) { throw 'No page target was available.' }
  $socket = [System.Net.WebSockets.ClientWebSocket]::new()
  $null = $socket.ConnectAsync([Uri]$target.webSocketDebuggerUrl, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()

  $null = Invoke-Cdp 'Page.enable'
  $null = Invoke-Cdp 'Runtime.enable'
  $null = Invoke-Cdp 'Network.enable'
  $null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{
    width = 1440; height = 900; deviceScaleFactor = 1; mobile = $false
    screenWidth = 1440; screenHeight = 900
  }
  $null = Invoke-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{
    source = 'window.__verificationErrors=[];addEventListener("error",e=>window.__verificationErrors.push(String(e.message||e.error)));addEventListener("unhandledrejection",e=>window.__verificationErrors.push(String(e.reason)));'
  }

  Navigate 'http://127.0.0.1:4173/'
  Start-Sleep -Milliseconds 180
  $loaderState = Evaluate 'JSON.stringify({background:getComputedStyle(document.querySelector("#loader")).backgroundColor,pending:document.documentElement.classList.contains("loader-pending"),hidden:document.querySelector("#loader").hidden})'
  $loaderShot = Screenshot '00-white-initial-loader.png'
  Start-Sleep -Milliseconds 2200
  $null = Invoke-Cdp 'Page.reload' @{ ignoreCache = $false }
  Wait-ForReady
  Start-Sleep -Milliseconds 160
  $homeNormalRefreshLoader = Evaluate 'JSON.stringify({background:getComputedStyle(document.querySelector("#loader")).backgroundColor,pending:document.documentElement.classList.contains("loader-pending"),hidden:document.querySelector("#loader").hidden,transitionLayers:document.querySelectorAll(".manmatic-transition").length})' | ConvertFrom-Json
  Start-Sleep -Milliseconds 2200
  $null = Invoke-Cdp 'Network.clearBrowserCache'
  $null = Invoke-Cdp 'Page.reload' @{ ignoreCache = $true }
  Wait-ForReady
  Start-Sleep -Milliseconds 160
  $homeHardRefreshLoader = Evaluate 'JSON.stringify({background:getComputedStyle(document.querySelector("#loader")).backgroundColor,pending:document.documentElement.classList.contains("loader-pending"),hidden:document.querySelector("#loader").hidden,transitionLayers:document.querySelectorAll(".manmatic-transition").length})' | ConvertFrom-Json
  Start-Sleep -Milliseconds 2200

  $null = Invoke-Cdp 'Page.navigate' @{
    url = 'http://127.0.0.1:4173/projects/manmatic/'
    referrer = 'https://external.example/'
  }
  Wait-ForReady
  Start-Sleep -Milliseconds 160
  $directManmaticLoader = Evaluate 'JSON.stringify({pending:document.documentElement.classList.contains("loader-pending"),hidden:document.querySelector("#loader").hidden,display:getComputedStyle(document.querySelector("#loader")).display,background:getComputedStyle(document.querySelector("#loader")).backgroundColor,theme:document.documentElement.dataset.siteTheme,transitionLayers:document.querySelectorAll(".manmatic-transition").length})' | ConvertFrom-Json
  $directLoaderShot = Screenshot '01-direct-manmatic-loader.png'
  Start-Sleep -Milliseconds 2200
  $before = Screenshot '01-opening-scramble.png'
  $scrambleText = Evaluate 'document.querySelector(".mm-opening [data-scramble]").textContent'
  Start-Sleep -Milliseconds 1000
  $after = Screenshot '02-opening-resolved.png'
  $settledText = Evaluate 'document.querySelector(".mm-opening [data-scramble]").textContent'
  $scrambleCount = Evaluate 'document.querySelectorAll(".mm-opening [data-scramble]").length'
  $directManmaticResting = Evaluate 'JSON.stringify((()=>{const ambient=document.querySelector(".ambient-signal"),material=document.querySelector(".material-texture"),main=document.querySelector("main"),shell=document.querySelector(".site-shell"),a=getComputedStyle(ambient),m=getComputedStyle(material);return{pending:document.documentElement.classList.contains("loader-pending"),loaderHidden:document.querySelector("#loader").hidden,theme:document.documentElement.dataset.siteTheme,bodyBackground:getComputedStyle(document.body).backgroundColor,mainBackground:getComputedStyle(main).backgroundColor,ambientDisplay:a.display,ambientOpacity:a.opacity,ambientPattern:a.backgroundImage,materialDisplay:m.display,materialOpacity:m.opacity,shellBefore:getComputedStyle(shell,"::before").content,shellAfter:getComputedStyle(shell,"::after").content,transitionLayers:document.querySelectorAll(".manmatic-transition").length}})())' | ConvertFrom-Json

  $null = Invoke-Cdp 'Page.reload' @{ ignoreCache = $false }
  Wait-ForReady
  Start-Sleep -Milliseconds 160
  $normalRefreshLoader = Evaluate 'JSON.stringify({pending:document.documentElement.classList.contains("loader-pending"),hidden:document.querySelector("#loader").hidden,background:getComputedStyle(document.querySelector("#loader")).backgroundColor,transitionLayers:document.querySelectorAll(".manmatic-transition").length})' | ConvertFrom-Json
  Start-Sleep -Milliseconds 3200
  $normalRefreshResting = Evaluate 'JSON.stringify((()=>{const material=getComputedStyle(document.querySelector(".material-texture"));return{theme:document.documentElement.dataset.siteTheme,bodyBackground:getComputedStyle(document.body).backgroundColor,materialDisplay:material.display,materialOpacity:material.opacity,transitionLayers:document.querySelectorAll(".manmatic-transition").length}})())' | ConvertFrom-Json

  $null = Invoke-Cdp 'Network.clearBrowserCache'
  $null = Invoke-Cdp 'Page.reload' @{ ignoreCache = $true }
  Wait-ForReady
  Start-Sleep -Milliseconds 160
  $hardRefreshLoader = Evaluate 'JSON.stringify({pending:document.documentElement.classList.contains("loader-pending"),hidden:document.querySelector("#loader").hidden,background:getComputedStyle(document.querySelector("#loader")).backgroundColor,transitionLayers:document.querySelectorAll(".manmatic-transition").length})' | ConvertFrom-Json
  Start-Sleep -Milliseconds 3200
  $hardRefreshResting = Evaluate 'JSON.stringify((()=>{const material=getComputedStyle(document.querySelector(".material-texture"));return{theme:document.documentElement.dataset.siteTheme,bodyBackground:getComputedStyle(document.body).backgroundColor,materialDisplay:material.display,materialOpacity:material.opacity,transitionLayers:document.querySelectorAll(".manmatic-transition").length}})())' | ConvertFrom-Json

  Navigate 'http://127.0.0.1:4173/'
  Start-Sleep -Milliseconds 2500
  $homeThemeBeforeEntry = Evaluate 'JSON.stringify((()=>{const row=document.querySelector("[data-manmatic-system]");return{theme:document.documentElement.dataset.siteTheme,bodyBackground:getComputedStyle(document.body).backgroundColor,previewBackground:getComputedStyle(row).backgroundColor,transitionLayers:document.querySelectorAll(".manmatic-transition").length}})())' | ConvertFrom-Json
  $null = Evaluate '(()=>{const key="manmatic-enter-samples",samples=[],started=performance.now();function sample(now){const shell=document.querySelector(".site-shell"),style=getComputedStyle(shell);samples.push({elapsed:Math.round(now-started),path:location.pathname,active:shell.classList.contains("is-manmatic-route-transitioning"),direction:document.documentElement.dataset.manmaticRouteTransition||"",theme:document.documentElement.dataset.siteTheme,bodyBackground:getComputedStyle(document.body).backgroundColor,filter:style.filter,transform:style.transform,transitionLayers:document.querySelectorAll(".manmatic-transition").length});sessionStorage.setItem(key,JSON.stringify({samples}));if(now-started<430)requestAnimationFrame(sample)}requestAnimationFrame(sample);document.querySelector(".project-row--manmatic > .project-row__link").click();return true})()'
  Start-Sleep -Milliseconds 560
  Wait-ForReady
  $manmaticRouteResult = Evaluate 'sessionStorage.getItem("manmatic-enter-samples")' | ConvertFrom-Json
  $manmaticRouteSamples = @($manmaticRouteResult.samples)
  $manmaticThemeAfterEntry = Evaluate 'JSON.stringify((()=>{const ambient=document.querySelector(".ambient-signal"),a=getComputedStyle(ambient);return{path:location.pathname,theme:document.documentElement.dataset.siteTheme,bodyBackground:getComputedStyle(document.body).backgroundColor,textColor:getComputedStyle(document.body).color,loaderDisplay:getComputedStyle(document.querySelector("#loader")).display,active:document.querySelector(".site-shell").classList.contains("is-manmatic-route-transitioning"),ambientDisplay:a.display,ambientOpacity:a.opacity,ambientPattern:a.backgroundImage,transitionLayers:document.querySelectorAll(".manmatic-transition").length}})())' | ConvertFrom-Json
  $null = Evaluate '(()=>{const key="manmatic-exit-samples",samples=[],started=performance.now();function sample(now){const shell=document.querySelector(".site-shell"),style=getComputedStyle(shell);samples.push({elapsed:Math.round(now-started),path:location.pathname,active:shell.classList.contains("is-manmatic-route-transitioning"),direction:document.documentElement.dataset.manmaticRouteTransition||"",theme:document.documentElement.dataset.siteTheme,bodyBackground:getComputedStyle(document.body).backgroundColor,filter:style.filter,transform:style.transform,transitionLayers:document.querySelectorAll(".manmatic-transition").length});sessionStorage.setItem(key,JSON.stringify({samples}));if(now-started<430)requestAnimationFrame(sample)}requestAnimationFrame(sample);document.querySelector(".site-header__name").click();return true})()'
  Start-Sleep -Milliseconds 560
  Wait-ForReady
  $homeRouteResult = Evaluate 'sessionStorage.getItem("manmatic-exit-samples")' | ConvertFrom-Json
  $homeRouteSamples = @($homeRouteResult.samples)
  $homeThemeAfterExit = Evaluate 'JSON.stringify((()=>{const row=document.querySelector("[data-manmatic-system]");return{path:location.pathname,theme:document.documentElement.dataset.siteTheme,bodyBackground:getComputedStyle(document.body).backgroundColor,previewBackground:getComputedStyle(row).backgroundColor,active:document.querySelector(".site-shell").classList.contains("is-manmatic-route-transitioning"),transitionLayers:document.querySelectorAll(".manmatic-transition").length}})())' | ConvertFrom-Json
  $null = Evaluate 'document.querySelector(".project-row--manmatic > .project-row__link").click();true'
  Wait-ForReady
  Start-Sleep -Milliseconds 500
  $repeatedManmaticEntry = Evaluate 'JSON.stringify({path:location.pathname,theme:document.documentElement.dataset.siteTheme,bodyBackground:getComputedStyle(document.body).backgroundColor,active:document.querySelector(".site-shell").classList.contains("is-manmatic-route-transitioning"),transitionLayers:document.querySelectorAll(".manmatic-transition").length})' | ConvertFrom-Json
  $null = Evaluate 'document.querySelector(".mm-action[href=''/projects/protocol-port/'']").click();true'
  Wait-ForReady
  Start-Sleep -Milliseconds 500
  $protocolPortTheme = Evaluate 'JSON.stringify((()=>{const ambient=getComputedStyle(document.querySelector(".ambient-signal"));return{path:location.pathname,theme:document.documentElement.dataset.siteTheme,initialTheme:document.documentElement.dataset.initialTheme,bodyBackground:getComputedStyle(document.body).backgroundColor,textColor:getComputedStyle(document.body).color,projectTheme:document.querySelector(".project-header").dataset.projectTheme,ambientPattern:ambient.backgroundImage,transitionLayers:document.querySelectorAll(".manmatic-transition").length}})())' | ConvertFrom-Json
  $null = Evaluate 'history.back();true'
  Start-Sleep -Milliseconds 650
  $backToManmaticTheme = Evaluate 'JSON.stringify({path:location.pathname,theme:document.documentElement.dataset.siteTheme,bodyBackground:getComputedStyle(document.body).backgroundColor,active:document.querySelector(".site-shell").classList.contains("is-manmatic-route-transitioning"),transitionLayers:document.querySelectorAll(".manmatic-transition").length})' | ConvertFrom-Json
  $null = Evaluate 'history.forward();true'
  Start-Sleep -Milliseconds 650
  $forwardToProtocolTheme = Evaluate 'JSON.stringify({path:location.pathname,theme:document.documentElement.dataset.siteTheme,bodyBackground:getComputedStyle(document.body).backgroundColor,active:document.querySelector(".site-shell").classList.contains("is-manmatic-route-transitioning"),transitionLayers:document.querySelectorAll(".manmatic-transition").length})' | ConvertFrom-Json
  $activeEnterFrames = @($manmaticRouteSamples | Where-Object {
    $_.active -and $_.direction -eq 'enter' -and
    ($_.filter -ne 'none' -or $_.transform -ne 'none')
  })
  $activeExitFrames = @($homeRouteSamples | Where-Object {
    $_.active -and $_.direction -eq 'exit' -and
    ($_.filter -ne 'none' -or $_.transform -ne 'none')
  })
  if (
    -not $homeNormalRefreshLoader.pending -or
    $homeNormalRefreshLoader.hidden -or
    $homeNormalRefreshLoader.background -ne 'rgb(255, 255, 255)' -or
    $homeNormalRefreshLoader.transitionLayers -ne 0 -or
    -not $homeHardRefreshLoader.pending -or
    $homeHardRefreshLoader.hidden -or
    $homeHardRefreshLoader.background -notin @('rgb(255, 255, 255)', 'rgb(8, 8, 8)') -or
    $homeHardRefreshLoader.transitionLayers -ne 0 -or
    -not $directManmaticLoader.pending -or
    $directManmaticLoader.hidden -or
    $directManmaticLoader.background -ne 'rgb(255, 255, 255)' -or
    $directManmaticLoader.transitionLayers -ne 0 -or
    -not $normalRefreshLoader.pending -or
    $normalRefreshLoader.hidden -or
    $normalRefreshLoader.background -ne 'rgb(255, 255, 255)' -or
    $normalRefreshLoader.transitionLayers -ne 0 -or
    -not $hardRefreshLoader.pending -or
    $hardRefreshLoader.hidden -or
    $hardRefreshLoader.background -ne 'rgb(255, 255, 255)' -or
    $hardRefreshLoader.transitionLayers -ne 0 -or
    $normalRefreshResting.theme -ne 'manmatic' -or
    $normalRefreshResting.bodyBackground -ne 'rgb(39, 39, 39)' -or
    $normalRefreshResting.materialDisplay -ne 'block' -or
    [double]$normalRefreshResting.materialOpacity -lt 0.15 -or
    $normalRefreshResting.transitionLayers -ne 0 -or
    $hardRefreshResting.theme -ne 'manmatic' -or
    $hardRefreshResting.bodyBackground -ne 'rgb(39, 39, 39)' -or
    $hardRefreshResting.materialDisplay -ne 'block' -or
    [double]$hardRefreshResting.materialOpacity -lt 0.15 -or
    $hardRefreshResting.transitionLayers -ne 0 -or
    $directManmaticResting.pending -or
    -not $directManmaticResting.loaderHidden -or
    $directManmaticResting.theme -ne 'manmatic' -or
    $directManmaticResting.bodyBackground -ne 'rgb(39, 39, 39)' -or
    $directManmaticResting.mainBackground -notin @('rgba(0, 0, 0, 0)', 'rgb(39, 39, 39)') -or
    $directManmaticResting.ambientDisplay -ne 'block' -or
    $directManmaticResting.ambientPattern -eq 'none' -or
    $directManmaticResting.materialDisplay -ne 'block' -or
    $directManmaticResting.materialOpacity -ne '0.16' -or
    $directManmaticResting.transitionLayers -ne 0 -or
    $homeThemeBeforeEntry.theme -ne 'light' -or
    $homeThemeBeforeEntry.bodyBackground -ne 'rgb(255, 255, 255)' -or
    $homeThemeBeforeEntry.previewBackground -ne 'rgb(255, 255, 255)' -or
    $homeThemeBeforeEntry.transitionLayers -ne 0 -or
    $activeEnterFrames.Count -eq 0 -or
    $manmaticThemeAfterEntry.theme -ne 'manmatic' -or
    $manmaticThemeAfterEntry.bodyBackground -ne 'rgb(39, 39, 39)' -or
    $manmaticThemeAfterEntry.loaderDisplay -ne 'none' -or
    $manmaticThemeAfterEntry.ambientDisplay -ne 'block' -or
    $manmaticThemeAfterEntry.ambientPattern -eq 'none' -or
    $manmaticThemeAfterEntry.active -or
    $manmaticThemeAfterEntry.transitionLayers -ne 0 -or
    $activeExitFrames.Count -eq 0 -or
    $homeThemeAfterExit.theme -ne 'light' -or
    $homeThemeAfterExit.bodyBackground -ne 'rgb(255, 255, 255)' -or
    $homeThemeAfterExit.previewBackground -ne 'rgb(255, 255, 255)' -or
    $homeThemeAfterExit.active -or
    $homeThemeAfterExit.transitionLayers -ne 0 -or
    $repeatedManmaticEntry.path -ne '/projects/manmatic/' -or
    $repeatedManmaticEntry.theme -ne 'manmatic' -or
    $repeatedManmaticEntry.bodyBackground -ne 'rgb(39, 39, 39)' -or
    $repeatedManmaticEntry.active -or
    $repeatedManmaticEntry.transitionLayers -ne 0 -or
    $protocolPortTheme.theme -ne 'light' -or
    $protocolPortTheme.bodyBackground -ne 'rgb(255, 255, 255)' -or
    $protocolPortTheme.projectTheme -ne 'light' -or
    $protocolPortTheme.ambientPattern -eq 'none' -or
    $protocolPortTheme.transitionLayers -ne 0 -or
    $backToManmaticTheme.path -ne '/projects/manmatic/' -or
    $backToManmaticTheme.theme -ne 'manmatic' -or
    $backToManmaticTheme.bodyBackground -ne 'rgb(39, 39, 39)' -or
    $backToManmaticTheme.active -or
    $backToManmaticTheme.transitionLayers -ne 0 -or
    $forwardToProtocolTheme.path -ne '/projects/protocol-port/' -or
    $forwardToProtocolTheme.theme -ne 'light' -or
    $forwardToProtocolTheme.bodyBackground -ne 'rgb(255, 255, 255)' -or
    $forwardToProtocolTheme.active -or
    $forwardToProtocolTheme.transitionLayers -ne 0
  ) {
    $routeDiagnostics = [ordered]@{
      homeNormalRefreshLoader = $homeNormalRefreshLoader
      homeHardRefreshLoader = $homeHardRefreshLoader
      directEntryLoader = $directManmaticLoader
      normalRefreshLoader = $normalRefreshLoader
      hardRefreshLoader = $hardRefreshLoader
      normalRefreshResting = $normalRefreshResting
      hardRefreshResting = $hardRefreshResting
      directEntryResting = $directManmaticResting
      homeBeforeEntry = $homeThemeBeforeEntry
      activeEnterFrames = $activeEnterFrames.Count
      manmaticAfterEntry = $manmaticThemeAfterEntry
      activeExitFrames = $activeExitFrames.Count
      homeAfterExit = $homeThemeAfterExit
      repeatedManmaticEntry = $repeatedManmaticEntry
      protocolPort = $protocolPortTheme
      backToManmatic = $backToManmaticTheme
      forwardToProtocolPort = $forwardToProtocolTheme
    } | ConvertTo-Json -Depth 5 -Compress
    throw "The ManMaTIC route theme transition did not enter dark, remain dark, or restore light cleanly. $routeDiagnostics"
  }
  Navigate 'http://127.0.0.1:4173/'
  Start-Sleep -Milliseconds 500
  $null = Evaluate 'document.documentElement.style.scrollBehavior="auto";const t=document.querySelector(".manmatic-threshold");window.scrollTo(0,t.getBoundingClientRect().top+scrollY-(innerHeight-t.offsetHeight)/2);true'
  Start-Sleep -Milliseconds 1000
  $threshold = Screenshot '03-threshold-connected.png'
  $thresholdSurface = Evaluate 'getComputedStyle(document.querySelector(".manmatic-threshold")).backgroundColor'

  $null = Evaluate 'const f=document.querySelector(".manmatic-field-window");window.scrollTo(0,f.getBoundingClientRect().top+scrollY-(innerHeight-f.offsetHeight)/2);true'
  Start-Sleep -Milliseconds 3500
  $field = Screenshot '04-field-window.png'
  $fieldState = Evaluate 'JSON.stringify((()=>{const w=document.querySelector(".manmatic-field-window"),f=w.querySelector("iframe"),ws=getComputedStyle(w),fs=getComputedStyle(f),before=getComputedStyle(w,"::before"),after=getComputedStyle(w,"::after");return{bar:w.querySelector(".manmatic-field-window__bar").innerText,iframeCount:w.querySelectorAll("iframe").length,rect:w.getBoundingClientRect().toJSON(),href:w.closest("a").getAttribute("href"),styles:{windowOpacity:ws.opacity,windowFilter:ws.filter,iframeOpacity:fs.opacity,iframeFilter:fs.filter,beforeContent:before.content,afterContent:after.content}}})())'

  $fieldResponsive = @{}
  foreach ($viewport in @(
    @{ Name = '1024-tablet'; Width = 1024; Height = 1366; Mobile = $false },
    @{ Name = '820-tablet'; Width = 820; Height = 1180; Mobile = $false },
    @{ Name = '390-mobile'; Width = 390; Height = 844; Mobile = $true }
  )) {
    $null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{
      width = $viewport.Width; height = $viewport.Height; deviceScaleFactor = 1; mobile = $viewport.Mobile
      screenWidth = $viewport.Width; screenHeight = $viewport.Height
    }
    Navigate 'http://127.0.0.1:4173/'
    Start-Sleep -Milliseconds 500
    $null = Evaluate 'document.documentElement.style.scrollBehavior="auto";const f=document.querySelector(".manmatic-field-window");window.scrollTo(0,f.getBoundingClientRect().top+scrollY-(innerHeight-f.offsetHeight)/2);true'
    Start-Sleep -Milliseconds 3500
    $fieldResponsive[$viewport.Name] = $fieldViewportState = Evaluate 'JSON.stringify({width:innerWidth,height:innerHeight,iframeCount:document.querySelectorAll(".manmatic-field-window iframe").length,rect:document.querySelector(".manmatic-field-window").getBoundingClientRect().toJSON(),overflow:document.documentElement.scrollWidth>innerWidth})' | ConvertFrom-Json
    $null = Screenshot ("04-field-window-{0}.png" -f $viewport.Name)
  }

  $null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{
    width = 1440; height = 900; deviceScaleFactor = 1; mobile = $false
    screenWidth = 1440; screenHeight = 900
  }

  Navigate 'http://127.0.0.1:4173/'
  $null = Evaluate 'document.querySelector(".manmatic-field-window").closest("a").click();true'
  Start-Sleep -Milliseconds 200
  Wait-ForReady
  Start-Sleep -Milliseconds 700
  $landing = Screenshot '05-field-hash-landing.png'
  $landingState = Evaluate 'JSON.stringify({hash:location.hash,top:document.querySelector("#the-manmatic-field").getBoundingClientRect().top,label:document.querySelector("#the-manmatic-field .mm-index").innerText,title:document.querySelector("#the-manmatic-field h2").innerText})'

  Navigate 'http://127.0.0.1:4173/#work'
  $null = Evaluate 'history.back();true'
  Start-Sleep -Milliseconds 900
  $backState = Evaluate 'JSON.stringify({url:location.href,title:document.querySelector(".mm-opening [data-scramble]")?.textContent||"",scrambleTargets:document.querySelectorAll(".mm-opening [data-scramble]").length})'

  Navigate 'http://127.0.0.1:4173/projects/manmatic/'
  Start-Sleep -Milliseconds 2500
  $null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{
    width = 820; height = 1180; deviceScaleFactor = 1; mobile = $false
    screenWidth = 820; screenHeight = 1180
  }
  $null = Evaluate 'window.scrollTo(0,0);true'
  Start-Sleep -Milliseconds 520
  $tabletManmatic = Evaluate 'JSON.stringify((()=>{const ambient=getComputedStyle(document.querySelector(".ambient-signal")),material=getComputedStyle(document.querySelector(".material-texture"));return{width:innerWidth,theme:document.documentElement.dataset.siteTheme,bodyBackground:getComputedStyle(document.body).backgroundColor,ambientDisplay:ambient.display,ambientOpacity:ambient.opacity,ambientPattern:ambient.backgroundImage,materialDisplay:material.display,materialOpacity:material.opacity,materialPattern:material.backgroundImage,overflow:document.documentElement.scrollWidth>innerWidth,transitionLayers:document.querySelectorAll(".manmatic-transition").length}})())' | ConvertFrom-Json

  $null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{
    width = 390; height = 844; deviceScaleFactor = 1; mobile = $true
    screenWidth = 390; screenHeight = 844
  }
  $null = Evaluate 'window.scrollTo(0,0);true'
  Start-Sleep -Milliseconds 520
  $mobile = Screenshot '06-mobile-opening-resolved.png'
  $mobileManmatic = Evaluate 'JSON.stringify((()=>{const ambient=getComputedStyle(document.querySelector(".ambient-signal")),material=getComputedStyle(document.querySelector(".material-texture"));return{width:innerWidth,theme:document.documentElement.dataset.siteTheme,bodyBackground:getComputedStyle(document.body).backgroundColor,ambientDisplay:ambient.display,ambientOpacity:ambient.opacity,ambientPattern:ambient.backgroundImage,materialDisplay:material.display,materialOpacity:material.opacity,materialPattern:material.backgroundImage,overflow:document.documentElement.scrollWidth>innerWidth,transitionLayers:document.querySelectorAll(".manmatic-transition").length}})())' | ConvertFrom-Json
  if (
    $tabletManmatic.theme -ne 'manmatic' -or
    $tabletManmatic.bodyBackground -ne 'rgb(39, 39, 39)' -or
    $tabletManmatic.ambientDisplay -ne 'block' -or
    $tabletManmatic.ambientPattern -eq 'none' -or
    $tabletManmatic.materialDisplay -ne 'block' -or
    [double]$tabletManmatic.materialOpacity -lt 0.13 -or
    $tabletManmatic.materialPattern -eq 'none' -or
    $tabletManmatic.overflow -or
    $tabletManmatic.transitionLayers -ne 0 -or
    $mobileManmatic.theme -ne 'manmatic' -or
    $mobileManmatic.bodyBackground -ne 'rgb(39, 39, 39)' -or
    $mobileManmatic.ambientDisplay -ne 'block' -or
    $mobileManmatic.ambientPattern -eq 'none' -or
    $mobileManmatic.materialDisplay -ne 'block' -or
    [double]$mobileManmatic.materialOpacity -lt 0.13 -or
    $mobileManmatic.materialPattern -eq 'none' -or
    $mobileManmatic.overflow -or
    $mobileManmatic.transitionLayers -ne 0
  ) {
    $responsiveDiagnostics = [ordered]@{
      tablet = $tabletManmatic
      mobile = $mobileManmatic
    } | ConvertTo-Json -Depth 5 -Compress
    throw "The ManMaTIC dark route or reused background pattern failed on tablet or mobile. $responsiveDiagnostics"
  }
  $mobileScroll = Evaluate 'new Promise(resolve=>{const gaps=[];let start=performance.now(),last=start;function step(now){gaps.push(now-last);last=now;scrollBy(0,56);if(now-start<1200){requestAnimationFrame(step)}else{resolve(JSON.stringify({frames:gaps.length,maxFrameGap:Math.max(...gaps),averageFrameGap:gaps.reduce((sum,value)=>sum+value,0)/gaps.length,scrollY}))}}requestAnimationFrame(step)})'
  $errors = Evaluate 'JSON.stringify(window.__verificationErrors)'

  [ordered]@{
    beforeScrambleText = $scrambleText
    settledTitle = $settledText
    scrambleTargetCount = $scrambleCount
    loader = $loaderState | ConvertFrom-Json
    routeTheme = [ordered]@{
      homeNormalRefreshLoader = $homeNormalRefreshLoader
      homeHardRefreshLoader = $homeHardRefreshLoader
      directEntryLoader = $directManmaticLoader
      normalRefreshLoader = $normalRefreshLoader
      hardRefreshLoader = $hardRefreshLoader
      normalRefreshResting = $normalRefreshResting
      hardRefreshResting = $hardRefreshResting
      directEntryResting = $directManmaticResting
      homeBeforeEntry = $homeThemeBeforeEntry
      enterTransition = [ordered]@{
        activeMotionFrameCount = $activeEnterFrames.Count
        firstActiveFrame = $activeEnterFrames | Select-Object -First 1
        finalFrame = $manmaticRouteSamples | Select-Object -Last 1
      }
      manmaticAfterEntry = $manmaticThemeAfterEntry
      exitTransition = [ordered]@{
        activeMotionFrameCount = $activeExitFrames.Count
        firstActiveFrame = $activeExitFrames | Select-Object -First 1
        finalFrame = $homeRouteSamples | Select-Object -Last 1
      }
      homeAfterExit = $homeThemeAfterExit
      repeatedManmaticEntry = $repeatedManmaticEntry
      protocolPort = $protocolPortTheme
      backToManmatic = $backToManmaticTheme
      forwardToProtocolPort = $forwardToProtocolTheme
    }
    thresholdSurface = $thresholdSurface
    fieldWindow = $fieldState | ConvertFrom-Json
    fieldResponsive = $fieldResponsive
    hashLanding = $landingState | ConvertFrom-Json
    backNavigation = $backState | ConvertFrom-Json
    manmaticResponsive = [ordered]@{
      tablet = $tabletManmatic
      mobile = $mobileManmatic
    }
    mobileFastScroll = $mobileScroll | ConvertFrom-Json
    consoleErrors = $errors | ConvertFrom-Json
    screenshots = @($loaderShot, $directLoaderShot, $before, $after, $threshold, $field, $landing, $mobile)
  } | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $output 'verification.json')

  Get-Content (Join-Path $output 'verification.json')
} finally {
  if ($socket) {
    try { $null = Invoke-Cdp 'Browser.close' } catch {}
    $socket.Dispose()
  }
  if ($process -and -not $process.HasExited) { Stop-Process -Id $process.Id -Force }
  if ($httpProcess -and -not $httpProcess.HasExited) { Stop-Process -Id $httpProcess.Id }
}
