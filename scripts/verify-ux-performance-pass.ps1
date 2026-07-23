$ErrorActionPreference = 'Stop'

$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$output = Join-Path (Resolve-Path '.').Path 'runtime-validation\ux-performance-pass'
$profile = Join-Path $env:TEMP ('ux-performance-pass-' + (Get-Date -Format 'yyyyMMddHHmmssfff'))
$process = $null
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
  do { $response = (Receive-Message) | ConvertFrom-Json } until ($response.id -eq $id)
  if ($response.error) { throw "$method failed: $($response.error.message)" }
  return $response.result
}

function Evaluate([string]$expression) {
  $result = Invoke-Cdp 'Runtime.evaluate' @{ expression = $expression; returnByValue = $true; awaitPromise = $true }
  return $result.result.value
}

function Wait-For([string]$expression, [int]$attempts = 120) {
  for ($i = 0; $i -lt $attempts; $i++) {
    if (Evaluate $expression) { return }
    Start-Sleep -Milliseconds 50
  }
  throw "Condition timed out: $expression"
}

function Navigate([string]$url) {
  $null = Invoke-Cdp 'Page.navigate' @{ url = $url }
  Wait-For 'document.readyState === "complete"'
}

function Set-Viewport([int]$width, [int]$height, [bool]$mobile) {
  $null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{
    width = $width; height = $height; deviceScaleFactor = 1; mobile = $mobile
    screenWidth = $width; screenHeight = $height
  }
}

function Screenshot([string]$name, [bool]$fullPage = $false) {
  $params = @{ format = 'png'; fromSurface = $true; captureBeyondViewport = $true }
  if ($fullPage) {
    $metrics = Invoke-Cdp 'Page.getLayoutMetrics'
    $params.clip = @{
      x = 0
      y = 0
      width = [Math]::Ceiling($metrics.cssContentSize.width)
      height = [Math]::Ceiling($metrics.cssContentSize.height)
      scale = 1
    }
  }
  $result = Invoke-Cdp 'Page.captureScreenshot' $params
  $path = Join-Path $output $name
  [System.IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($result.data))
  return $path
}

try {
  $null = Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:4173/' -TimeoutSec 2
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
  $socket = [System.Net.WebSockets.ClientWebSocket]::new()
  $null = $socket.ConnectAsync([Uri]$target.webSocketDebuggerUrl, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
  $null = Invoke-Cdp 'Page.enable'
  $null = Invoke-Cdp 'Runtime.enable'
  $null = Invoke-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{
    source = 'window.__uxErrors=[];addEventListener("error",e=>window.__uxErrors.push(String(e.message||e.error)));addEventListener("unhandledrejection",e=>window.__uxErrors.push(String(e.reason)));'
  }

  Set-Viewport 1440 900 $false
  Navigate 'http://127.0.0.1:4173/'
  Wait-For '!document.documentElement.classList.contains("loader-pending")'
  $semanticState = Evaluate 'JSON.stringify({cards:[...document.querySelectorAll(".project-index > .project-row")].map(r=>({id:r.dataset.projectId||r.id,anchors:r.querySelectorAll(":scope > a.project-row__link").length,buttons:r.querySelectorAll(".project-row__action").length})),branches:[...document.querySelectorAll(".manmatic-category__record")].map(r=>r.querySelectorAll(":scope > a.manmatic-branch").length),elma:(()=>{const i=document.querySelector(".project-row--elma img"),r=i.getBoundingClientRect();return {natural:[i.naturalWidth,i.naturalHeight],rendered:[r.width,r.height],ratio:r.width/r.height,src:i.currentSrc}})()})'

  $null = Evaluate 'document.querySelector(".project-row--shila > a").click();true'
  Start-Sleep -Milliseconds 500
  $entryState = Evaluate 'JSON.stringify({path:location.pathname,loaderCount:document.querySelectorAll(".loader").length,contentVisible:getComputedStyle(document.querySelector("main")).visibility!=="hidden",transitionLayers:document.querySelectorAll(".manmatic-transition").length})'
  $entryShot = Screenshot '01-project-entry.png'
  $entryResolvedShot = Screenshot '02-project-entry-resolved.png'

  $null = Evaluate 'document.querySelector(".site-header__name").click();true'
  Start-Sleep -Milliseconds 90
  $exitState = Evaluate 'JSON.stringify({path:location.pathname,loaderCount:document.querySelectorAll(".loader").length,homeVisible:Boolean(document.querySelector("main")),transitionLayers:document.querySelectorAll(".manmatic-transition").length})'
  $exitShot = Screenshot '03-project-exit-glitch.png'
  Wait-For 'location.pathname === "/"'

  $null = Evaluate 'document.querySelector(".project-row--elma > a").click();true'
  Wait-For 'location.pathname === "/projects/concrete-fatigue/"'
  $null = Evaluate 'history.back();true'
  Wait-For 'location.pathname === "/"'
  $backState = Evaluate 'JSON.stringify({path:location.pathname,loaderCount:document.querySelectorAll(".loader").length,transitionLayers:document.querySelectorAll(".manmatic-transition").length,transientState:document.documentElement.classList.contains("is-system-switching")})'
  $null = Evaluate 'history.forward();true'
  Wait-For 'location.pathname === "/projects/concrete-fatigue/"'
  $forwardState = Evaluate 'JSON.stringify({path:location.pathname,loaderCount:document.querySelectorAll(".loader").length,transitionLayers:document.querySelectorAll(".manmatic-transition").length})'

  Navigate 'http://127.0.0.1:4173/projects/shila/'
  $directState = Evaluate 'JSON.stringify({loaderCount:document.querySelectorAll(".loader").length,pending:document.documentElement.classList.contains("loader-pending"),contentVisible:getComputedStyle(document.querySelector("main")).visibility!=="hidden"})'
  $null = Evaluate 'document.querySelector("a[href=\"/projects/manmatic/\"]").click();true'
  Wait-For 'location.pathname === "/projects/manmatic/"'
  Start-Sleep -Milliseconds 350
  $projectToProjectState = Evaluate 'JSON.stringify({path:location.pathname,loaderCount:document.querySelectorAll(".loader").length,pending:document.documentElement.classList.contains("loader-pending"),transitionLayers:document.querySelectorAll(".manmatic-transition").length})'

  $null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{ features = @(@{ name = 'prefers-reduced-motion'; value = 'reduce' }) }
  Navigate 'http://127.0.0.1:4173/'
  $null = Evaluate 'document.querySelector(".project-row--elma > a").click();true'
  Wait-For 'location.pathname === "/projects/concrete-fatigue/"'
  $reducedMotionState = Evaluate 'JSON.stringify({pending:document.documentElement.classList.contains("loader-pending"),loaderCount:document.querySelectorAll(".loader").length,transitionLayers:document.querySelectorAll(".manmatic-transition").length})'
  $null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{ features = @() }

  $viewports = @(
    @{ width = 360; height = 800 },
    @{ width = 390; height = 844 },
    @{ width = 430; height = 932 },
    @{ width = 768; height = 1024 },
    @{ width = 820; height = 1180 },
    @{ width = 1440; height = 900 }
  )
  $viewportResults = @()
  foreach ($viewport in $viewports) {
    $mobile = $viewport.width -lt 960
    Set-Viewport $viewport.width $viewport.height $mobile
    Navigate 'http://127.0.0.1:4173/'
    $viewportResults += Evaluate "JSON.stringify({width:$($viewport.width),height:$($viewport.height),overflow:document.documentElement.scrollWidth>document.documentElement.clientWidth,cardAnchors:document.querySelectorAll('.project-row > a.project-row__link').length,elmaRatio:(()=>{const r=document.querySelector('.project-row--elma img').getBoundingClientRect();return r.width/r.height})()})"
  }

  Set-Viewport 1440 900 $false
  Navigate 'http://127.0.0.1:4173/'
  $null = Evaluate 'new Promise(async resolve=>{for(const row of document.querySelectorAll(".project-row")){row.scrollIntoView({block:"center"});await new Promise(done=>setTimeout(done,180));for(const image of row.querySelectorAll("img")){if(image.decode){try{await image.decode()}catch(error){}}}}document.querySelector("#work").scrollIntoView();requestAnimationFrame(()=>requestAnimationFrame(resolve));})'
  $workShot = Screenshot '04-selected-work-desktop.png' $true

  Navigate 'http://127.0.0.1:4173/projects/manmatic/'
  Wait-For '!document.documentElement.classList.contains("loader-pending")'
  $null = Evaluate 'new Promise(async resolve=>{for(const image of document.querySelectorAll("main img")){image.scrollIntoView({block:"center"});await new Promise(done=>setTimeout(done,120));if(image.decode){try{await image.decode()}catch(error){}}}document.querySelectorAll("[data-image-reveal]").forEach(node=>node.classList.add("is-visible"));document.querySelectorAll(".heading-motion").forEach(node=>node.classList.add("is-heading-visible","is-heading-settled"));if(document.activeElement&&document.activeElement.blur)document.activeElement.blur();scrollTo(0,0);setTimeout(resolve,400);})'
  $manmaticDesktop = Screenshot '05-manmatic-desktop-full.png' $true

  Set-Viewport 820 1180 $true
  Navigate 'http://127.0.0.1:4173/projects/manmatic/'
  Wait-For '!document.documentElement.classList.contains("loader-pending")'
  $null = Evaluate 'new Promise(async resolve=>{for(const image of document.querySelectorAll("main img")){image.scrollIntoView({block:"center"});await new Promise(done=>setTimeout(done,120));if(image.decode){try{await image.decode()}catch(error){}}}document.querySelectorAll("[data-image-reveal]").forEach(node=>node.classList.add("is-visible"));document.querySelectorAll(".heading-motion").forEach(node=>node.classList.add("is-heading-visible","is-heading-settled"));if(document.activeElement&&document.activeElement.blur)document.activeElement.blur();scrollTo(0,0);setTimeout(resolve,400);})'
  $manmaticTablet = Screenshot '06-manmatic-tablet-full.png' $true

  Set-Viewport 390 844 $true
  Navigate 'about:blank'
  Navigate 'http://127.0.0.1:4173/projects/manmatic/?verification=field-hash#the-manmatic-field'
  Wait-For '!document.documentElement.classList.contains("loader-pending")'
  Start-Sleep -Milliseconds 180
  $hashShot = Screenshot '07-field-hash-mobile.png'
  $hashState = Evaluate 'JSON.stringify({top:document.querySelector("#the-manmatic-field").getBoundingClientRect().top,label:document.querySelector("#the-manmatic-field .mm-index").innerText,title:document.querySelector("#the-manmatic-field h2").innerText,overflow:document.documentElement.scrollWidth>document.documentElement.clientWidth})'

  $errors = Evaluate 'JSON.stringify(window.__uxErrors)'
  [ordered]@{
    semantics = $semanticState | ConvertFrom-Json
    projectEntry = $entryState | ConvertFrom-Json
    projectExit = $exitState | ConvertFrom-Json
    browserBack = $backState | ConvertFrom-Json
    browserForward = $forwardState | ConvertFrom-Json
    directProject = $directState | ConvertFrom-Json
    projectToProject = $projectToProjectState | ConvertFrom-Json
    reducedMotion = $reducedMotionState | ConvertFrom-Json
    viewports = $viewportResults | ForEach-Object { $_ | ConvertFrom-Json }
    fieldHash = $hashState | ConvertFrom-Json
    consoleErrors = $errors | ConvertFrom-Json
    screenshots = @($entryShot, $entryResolvedShot, $exitShot, $workShot, $manmaticDesktop, $manmaticTablet, $hashShot)
  } | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 (Join-Path $output 'verification.json')

  Get-Content (Join-Path $output 'verification.json')
} finally {
  if ($socket) {
    try { $null = Invoke-Cdp 'Browser.close' } catch {}
    $socket.Dispose()
  }
  if ($process -and -not $process.HasExited) { Stop-Process -Id $process.Id -Force }
}
