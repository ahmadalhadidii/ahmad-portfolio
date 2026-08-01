$ErrorActionPreference = 'Stop'

$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$url = 'http://127.0.0.1:4173/projects/protocol-port/'
$outDir = Join-Path (Resolve-Path '.\runtime-validation').Path 'protocol-port'
$runId = Get-Date -Format 'yyyyMMdd-HHmmssfff'
$profile = Join-Path $env:TEMP "protocol-port-profile-$runId"
$script:cdpId = 0
$script:events = [System.Collections.ArrayList]::new()
$script:assertions = 0
$results = [System.Collections.ArrayList]::new()

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Assert-State([bool]$condition, [string]$message) {
  if (-not $condition) { throw $message }
  $script:assertions++
}

function Receive-CdpMessage {
  $buffer = New-Object byte[] 1048576
  $stream = [System.IO.MemoryStream]::new()
  do {
    $segment = [System.ArraySegment[byte]]::new($buffer)
    $received = $script:ws.ReceiveAsync($segment, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
    if ($received.Count -gt 0) { $stream.Write($buffer, 0, $received.Count) }
  } until ($received.EndOfMessage)
  $text = [System.Text.Encoding]::UTF8.GetString($stream.ToArray())
  $stream.Dispose()
  return $text
}

function Invoke-Cdp([string]$method, $params = $null) {
  $script:cdpId++
  $id = $script:cdpId
  $payload = @{ id = $id; method = $method }
  if ($null -ne $params) { $payload.params = $params }
  $bytes = [System.Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Depth 30 -Compress))
  $segment = [System.ArraySegment[byte]]::new($bytes)
  $null = $script:ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
  while ($true) {
    $response = (Receive-CdpMessage) | ConvertFrom-Json
    if ($response.PSObject.Properties['id'] -and $response.id -eq $id) {
      if ($response.error) { throw "CDP $method failed: $($response.error.message)" }
      return $response.result
    }
    if ($response.method) { $null = $script:events.Add($response) }
  }
}

function Get-Value([string]$expression) {
  $result = Invoke-Cdp 'Runtime.evaluate' @{ expression = $expression; returnByValue = $true; awaitPromise = $true }
  if ($result.exceptionDetails) { throw "Browser evaluation failed: $($result.exceptionDetails.text)" }
  return $result.result.value
}

function Get-Json([string]$expression) {
  $value = Get-Value $expression
  if ($value -is [string]) { return $value | ConvertFrom-Json }
  return $value
}

function Save-Shot([string]$name, [int]$width, [int]$height) {
  $shot = Invoke-Cdp 'Page.captureScreenshot' @{ format = 'png'; fromSurface = $true; captureBeyondViewport = $false }
  $path = Join-Path $outDir "$runId-$name-$width-x-$height.png"
  [System.IO.File]::WriteAllBytes($path, [System.Convert]::FromBase64String($shot.data))
  return $path
}

function Wait-For([string]$expression, [string]$message) {
  for ($i = 0; $i -lt 120; $i++) {
    try { if ([bool](Get-Value $expression)) { return } } catch {}
    Start-Sleep -Milliseconds 100
  }
  throw $message
}

function Set-Viewport($viewport) {
  $null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{
    width = $viewport.Width; height = $viewport.Height; deviceScaleFactor = 1
    mobile = $viewport.Mobile; screenWidth = $viewport.Width; screenHeight = $viewport.Height
  }
}

try {
  Assert-State (Test-Path -LiteralPath $chrome) 'Google Chrome was not found.'
  $script:process = Start-Process -FilePath $chrome -ArgumentList @(
    '--headless=new', '--disable-gpu', '--hide-scrollbars', '--no-first-run',
    '--remote-debugging-port=0', '--remote-allow-origins=*', "--user-data-dir=$profile", 'about:blank'
  ) -PassThru -WindowStyle Hidden

  $portFile = Join-Path $profile 'DevToolsActivePort'
  $deadline = (Get-Date).AddSeconds(15)
  while (-not (Test-Path -LiteralPath $portFile) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 100 }
  Assert-State (Test-Path -LiteralPath $portFile) 'Chrome DevTools endpoint did not start.'

  $port = [int](Get-Content -LiteralPath $portFile | Select-Object -First 1)
  $targets = Invoke-RestMethod -Uri "http://127.0.0.1:$port/json/list"
  $target = $targets | Where-Object { $_.type -eq 'page' } | Select-Object -First 1
  Assert-State ($null -ne $target) 'No browser page target was available.'
  $script:ws = [System.Net.WebSockets.ClientWebSocket]::new()
  $null = $script:ws.ConnectAsync([System.Uri]$target.webSocketDebuggerUrl, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
  $null = Invoke-Cdp 'Page.enable'
  $null = Invoke-Cdp 'Runtime.enable'
  $null = Invoke-Cdp 'Log.enable'
  $null = Invoke-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{ source = 'window.__protocolErrors=[];addEventListener("error",e=>__protocolErrors.push(String(e.message||e.error)));addEventListener("unhandledrejection",e=>__protocolErrors.push(String(e.reason)));' }

  $viewports = @(
    @{ Name='desktop'; Width=1440; Height=900; Mobile=$false },
    @{ Name='tablet-landscape'; Width=1024; Height=768; Mobile=$true },
    @{ Name='tablet-portrait'; Width=768; Height=1024; Mobile=$true },
    @{ Name='mobile'; Width=390; Height=844; Mobile=$true }
  )

  foreach ($viewport in $viewports) {
    Set-Viewport $viewport
    $null = Invoke-Cdp 'Page.navigate' @{ url = $url }
    Wait-For 'document.readyState === "complete" && document.documentElement.classList.contains("loader-complete")' "Page did not become ready at $($viewport.Name)."
    $null = Get-Value 'window.scrollTo(0,0); true'
    Start-Sleep -Milliseconds 450
    $topShot = Save-Shot "$($viewport.Name)-top" $viewport.Width $viewport.Height

    $null = Get-Value @'
(async()=>{for(let y=0;y<document.documentElement.scrollHeight;y+=Math.max(500,innerHeight*.75)){scrollTo(0,y);await new Promise(r=>setTimeout(r,70));}scrollTo(0,0);return true})()
'@
    $null = Get-Value @'
(async()=>{const sources=[...new Set(Array.from(document.querySelectorAll(".protocol-port-board img")).map(img=>img.src))];window.__assetFailures=(await Promise.all(sources.map(async src=>{try{const r=await fetch(src);return r.ok?null:src}catch{return src}}))).filter(Boolean);return true})()
'@
    Wait-For 'document.querySelector(".protocol-port-hero img").complete && document.querySelector(".protocol-port-hero img").naturalWidth > 0' "The hero image failed to load at $($viewport.Name)."

    $state = Get-Json @'
JSON.stringify((()=>{
  const qs=s=>document.querySelector(s), rect=s=>{const r=qs(s).getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,bottom:r.bottom,right:r.right}};
  return {
    title:document.title,
    h1:qs(".protocol-port-identity h1").textContent.trim(),
    subtitle:qs(".protocol-port-subtitle").textContent.trim(),
    width:innerWidth,
    scrollWidth:document.documentElement.scrollWidth,
    imageSources:Array.from(document.querySelectorAll(".protocol-port-board img")).filter(img=>!img.closest("[data-gallery-clone]")).map(img=>new URL(img.src).pathname),
    failedImages:(window.__assetFailures||[]).length,
    overviewCopy:rect(".protocol-port-overview .protocol-port-copy"),
    overviewImage:rect(".protocol-port-overview figure"),
    siteMap:rect(".protocol-port-site__map"),
    siteAnalysis:rect(".protocol-port-site__analysis"),
    narrativeStatement:rect(".protocol-port-narrative__statement"),
    narrativeGallery:rect(".protocol-port-gallery--narrative"),
    plansCounter:qs(".protocol-port-gallery--plans [data-gallery-counter]").textContent.trim(),
    narrativeCounter:qs(".protocol-port-gallery--narrative [data-gallery-counter]").textContent.trim(),
    touchAction:getComputedStyle(qs(".protocol-port-gallery .shila-gallery__viewport")).touchAction,
    errors:window.__protocolErrors||[]
  };
})())
'@

    Assert-State ($state.title -eq 'THE PROTOCOL PORT | Ahmad Alhadidii') "Title mismatch at $($viewport.Name)."
    Assert-State ($state.h1 -eq 'THE PROTOCOL PORT') "H1 mismatch at $($viewport.Name)."
    Assert-State ($state.subtitle -eq 'A Thermodynamic Protocol Port for Algorithmic Logistics in Aqaba') "Subtitle mismatch at $($viewport.Name)."
    Assert-State ($state.imageSources.Count -eq 17) "Expected 17 project images at $($viewport.Name), found $($state.imageSources.Count)."
    Assert-State ($state.failedImages -eq 0) "Failed images remain at $($viewport.Name)."
    Assert-State ($state.scrollWidth -le ($state.width + 1)) "Horizontal overflow at $($viewport.Name): $($state.scrollWidth) > $($state.width)."
    Assert-State ($state.plansCounter -eq '01 / 02') "Plan counter is incorrect at $($viewport.Name)."
    Assert-State ($state.narrativeCounter -eq '01 / 04') "Narrative counter is incorrect at $($viewport.Name)."
    Assert-State ($state.touchAction -eq 'pan-y') "Gallery does not preserve vertical scrolling at $($viewport.Name)."
    Assert-State ($state.errors.Count -eq 0) "Runtime errors at $($viewport.Name): $($state.errors -join '; ')."

    if ($viewport.Width -gt 700) {
      Assert-State ($state.overviewImage.x -gt $state.overviewCopy.x) "Overview is not two-column at $($viewport.Name)."
      Assert-State ($state.siteAnalysis.x -gt $state.siteMap.x) "Site analysis is not nested beside image 3 at $($viewport.Name)."
      Assert-State ($state.narrativeGallery.x -gt $state.narrativeStatement.x) "Narrative is not two-column at $($viewport.Name)."
    } else {
      Assert-State ($state.overviewImage.y -ge ($state.overviewCopy.bottom - 1)) 'Mobile overview order is incorrect.'
      Assert-State ($state.siteAnalysis.y -ge ($state.siteMap.bottom - 1)) 'Mobile site-analysis order is incorrect.'
      Assert-State ($state.narrativeGallery.y -ge ($state.narrativeStatement.bottom - 1)) 'Mobile narrative order is incorrect.'
    }

    $null = Get-Value 'document.querySelector(".protocol-port-gallery--plans [data-gallery-next]").click(); true'
    Wait-For 'document.querySelector(".protocol-port-gallery--plans [data-gallery-counter]").textContent.trim()==="02 / 02"' 'Plan next control did not advance.'
    $null = Get-Value 'document.querySelector(".protocol-port-gallery--plans").dispatchEvent(new KeyboardEvent("keydown",{key:"ArrowLeft",bubbles:true})); true'
    Wait-For 'document.querySelector(".protocol-port-gallery--plans [data-gallery-counter]").textContent.trim()==="01 / 02"' 'Plan keyboard control did not return.'
    $null = Get-Value 'document.querySelector(".protocol-port-gallery--narrative").dispatchEvent(new KeyboardEvent("keydown",{key:"ArrowRight",bubbles:true})); true'
    Wait-For 'document.querySelector(".protocol-port-gallery--narrative [data-gallery-counter]").textContent.trim()==="02 / 04"' 'Narrative keyboard control did not advance.'

    $null = $results.Add([ordered]@{ viewport=$viewport.Name; width=$viewport.Width; height=$viewport.Height; scrollWidth=$state.scrollWidth; images=$state.imageSources.Count; topScreenshot=$topShot })
  }

  Set-Viewport $viewports[0]
  $null = Invoke-Cdp 'Page.navigate' @{ url = $url }
  Wait-For 'document.readyState === "complete" && document.documentElement.classList.contains("loader-complete")' 'Desktop evidence page did not become ready.'
  foreach ($entry in @(
    @{Name='desktop-overview'; Selector='.protocol-port-overview'},
    @{Name='desktop-site'; Selector='.protocol-port-site'},
    @{Name='desktop-methodology'; Selector='.protocol-port-methodology'},
    @{Name='desktop-plans'; Selector='.protocol-port-plans'},
    @{Name='desktop-system'; Selector='.protocol-port-system'},
    @{Name='desktop-thermodynamic'; Selector='.protocol-port-thermodynamic'},
    @{Name='desktop-narrative'; Selector='.protocol-port-narrative'}
  )) {
    $selector = $entry.Selector | ConvertTo-Json -Compress
    $null = Get-Value "document.querySelector($selector).scrollIntoView({block:'start'}); true"
    Wait-For "Array.from(document.querySelectorAll($selector+' img')).filter(img=>!img.closest('[data-gallery-clone]')&&(!img.closest('.shila-gallery__slide')||img.closest('.shila-gallery__slide').getAttribute('aria-hidden')!=='true')).every(img=>img.complete&&img.naturalWidth>0)" "Evidence images did not load for $($entry.Name)."
    Start-Sleep -Milliseconds 800
    $null = Save-Shot $entry.Name 1440 900
  }

  $logErrors = @($script:events | Where-Object { $_.method -eq 'Log.entryAdded' -and $_.params.entry.level -eq 'error' })
  Assert-State ($logErrors.Count -eq 0) "Browser console errors: $($logErrors.params.entry.text -join '; ')"

  $report = [ordered]@{ passed=$true; assertions=$script:assertions; url=$url; viewports=$results; consoleErrors=$logErrors.Count }
  $reportPath = Join-Path $outDir "$runId-verification.json"
  $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding utf8
  $report | ConvertTo-Json -Depth 8
}
finally {
  try { if ($script:ws) { $null = Invoke-Cdp 'Browser.close' } } catch {}
  try { if ($script:ws) { $script:ws.Dispose() } } catch {}
  try { if ($script:process -and -not $script:process.HasExited) { Stop-Process -Id $script:process.Id -Force } } catch {}
}
