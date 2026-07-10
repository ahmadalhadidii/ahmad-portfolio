$ErrorActionPreference = 'Stop'

$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$outDir = Join-Path $env:TEMP 'ahmad-portfolio-rebuild-check'
$runId = Get-Date -Format 'yyyyMMdd-HHmmssfff'
$profile = Join-Path $outDir ("profile-$runId")
$url = ([System.Uri]::new((Resolve-Path '.\index.html').Path)).AbsoluteUri

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$process = Start-Process -FilePath $chrome -ArgumentList @(
  '--headless=new',
  '--disable-gpu',
  '--disable-background-timer-throttling',
  '--disable-backgrounding-occluded-windows',
  '--disable-renderer-backgrounding',
  '--hide-scrollbars',
  '--no-first-run',
  '--allow-file-access-from-files',
  '--remote-debugging-port=0',
  '--remote-allow-origins=*',
  "--user-data-dir=$profile",
  'about:blank'
) -PassThru -WindowStyle Hidden

$portFile = Join-Path $profile 'DevToolsActivePort'
$deadline = (Get-Date).AddSeconds(15)
while (-not (Test-Path -LiteralPath $portFile) -and (Get-Date) -lt $deadline) {
  Start-Sleep -Milliseconds 100
}
if (-not (Test-Path -LiteralPath $portFile)) { throw 'Chrome DevTools endpoint did not start.' }

$port = [int](Get-Content -LiteralPath $portFile | Select-Object -First 1)
$targets = Invoke-RestMethod -Uri "http://127.0.0.1:$port/json/list"
$target = $targets | Where-Object { $_.type -eq 'page' } | Select-Object -First 1
if (-not $target) { throw 'No page target was available.' }

$ws = [System.Net.WebSockets.ClientWebSocket]::new()
$null = $ws.ConnectAsync([System.Uri]$target.webSocketDebuggerUrl, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
$script:cdpId = 0

function Receive-CdpMessage {
  $buffer = New-Object byte[] 1048576
  $stream = [System.IO.MemoryStream]::new()
  do {
    $segment = [System.ArraySegment[byte]]::new($buffer)
    $received = $ws.ReceiveAsync($segment, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
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
  $json = $payload | ConvertTo-Json -Depth 30 -Compress
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  $segment = [System.ArraySegment[byte]]::new($bytes)
  $null = $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
  do {
    $message = Receive-CdpMessage
    $response = $message | ConvertFrom-Json
  } until ($response.id -eq $id)
  if ($response.error) { throw ("CDP {0} failed: {1}" -f $method, $response.error.message) }
  return $response.result
}

function Evaluate([string]$expression) {
  $result = Invoke-Cdp 'Runtime.evaluate' @{
    expression = $expression
    returnByValue = $true
  }
  return $result.result.value
}

function Wait-ForRenderedSite {
  $ready = $false
  for ($i = 0; $i -lt 120 -and -not $ready; $i++) {
    try {
      $ready = [bool](Evaluate 'document.readyState !== "loading" && document.querySelectorAll(".project-item").length === 6')
    } catch { $ready = $false }
    if (-not $ready) { Start-Sleep -Milliseconds 100 }
  }
  if (-not $ready) { throw 'Portfolio did not render six project rows.' }
}

function Save-Screenshot([string]$name) {
  $path = Join-Path $outDir ("$runId-$name.png")
  $result = Invoke-Cdp 'Page.captureScreenshot' @{
    format = 'png'
    fromSurface = $true
    captureBeyondViewport = $false
  }
  [System.IO.File]::WriteAllBytes($path, [System.Convert]::FromBase64String($result.data))
  return $path
}

function Get-SiteState {
  $expression = @'
JSON.stringify({
  width: innerWidth,
  height: innerHeight,
  bodyClass: document.body.className,
  loaderPresent: Boolean(document.getElementById("binary-loader")),
  progress: document.getElementById("binary-loader-progress") ? document.getElementById("binary-loader-progress").textContent : null,
  projectRows: document.querySelectorAll(".project-item").length,
  openProjects: document.querySelectorAll(".project-item.is-open").length,
  expandedValue: document.querySelector(".project-trigger") ? document.querySelector(".project-trigger").getAttribute("aria-expanded") : null,
  firstAction: document.querySelector(".project-trigger__action") ? document.querySelector(".project-trigger__action").textContent : null,
  imageCodes: Array.from(document.querySelectorAll(".project-item:first-child .project-image__code")).map(function (element) { return element.textContent; }),
  missingImages: document.querySelectorAll(".project-item:first-child .project-image.is-missing").length,
  firstImagePath: document.querySelector(".project-item:first-child .project-image__path") ? document.querySelector(".project-item:first-child .project-image__path").textContent : null,
  activeNav: document.querySelector(".nav-link.is-active") ? document.querySelector(".nav-link.is-active").textContent : null,
  focusedId: document.activeElement ? document.activeElement.id : null,
  scrollWidth: document.documentElement.scrollWidth,
  clientWidth: document.documentElement.clientWidth,
  mobileNavInert: document.getElementById("mainNav").hasAttribute("inert")
})
'@
  return (Evaluate $expression) | ConvertFrom-Json
}

$null = Invoke-Cdp 'Page.enable'
$null = Invoke-Cdp 'Runtime.enable'
$null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{
  width = 1440
  height = 900
  deviceScaleFactor = 1
  mobile = $false
  screenWidth = 1440
  screenHeight = 900
}
$null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{
  features = @(@{ name = 'prefers-reduced-motion'; value = 'no-preference' })
}
$null = Invoke-Cdp 'Page.navigate' @{ url = $url }
Wait-ForRenderedSite
Start-Sleep -Milliseconds 450
$desktopIntroState = Get-SiteState
$desktopIntroShot = Save-Screenshot 'desktop-intro'
Start-Sleep -Milliseconds 1950
$desktopHeroState = Get-SiteState
$desktopHeroShot = Save-Screenshot 'desktop-hero'

$null = Evaluate 'document.getElementById("work").scrollIntoView({block:"start"}); true'
Start-Sleep -Milliseconds 500
$desktopWorkShot = Save-Screenshot 'desktop-work-closed'
$null = Evaluate 'document.querySelector(".project-trigger").click(); true'
Start-Sleep -Milliseconds 500
$desktopOpenState = Get-SiteState
$desktopOpenShot = Save-Screenshot 'desktop-work-open'
$null = Evaluate 'document.querySelector(".project-image-grid").scrollIntoView({block:"start"}); true'
Start-Sleep -Milliseconds 300
$desktopImagesShot = Save-Screenshot 'desktop-images'

$null = Evaluate 'document.getElementById("project-trigger-01").focus(); true'
$null = Evaluate 'document.getElementById("project-trigger-01").dispatchEvent(new KeyboardEvent("keydown", {key:"ArrowDown", bubbles:true})); true'
$keyboardState = Get-SiteState

$null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{
  width = 360
  height = 800
  deviceScaleFactor = 1
  mobile = $true
  screenWidth = 360
  screenHeight = 800
}
$null = Invoke-Cdp 'Page.navigate' @{ url = $url }
Wait-ForRenderedSite
Start-Sleep -Milliseconds 2350
$mobileHeroState = Get-SiteState
$mobileHeroShot = Save-Screenshot 'mobile-hero'
$null = Evaluate 'document.getElementById("work").scrollIntoView({block:"start"}); true'
Start-Sleep -Milliseconds 400
$mobileWorkShot = Save-Screenshot 'mobile-work-closed'
$null = Evaluate 'document.querySelector(".project-trigger").click(); true'
Start-Sleep -Milliseconds 500
$mobileOpenState = Get-SiteState
$mobileOpenShot = Save-Screenshot 'mobile-work-open'
$null = Evaluate 'document.querySelector(".project-image-grid").scrollIntoView({block:"start"}); true'
Start-Sleep -Milliseconds 300
$mobileImagesShot = Save-Screenshot 'mobile-images'

$null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{
  features = @(@{ name = 'prefers-reduced-motion'; value = 'reduce' })
}
$null = Invoke-Cdp 'Page.navigate' @{ url = $url }
Wait-ForRenderedSite
Start-Sleep -Milliseconds 200
$reducedState = Get-SiteState

Write-Output ("desktop-intro`t{0}`t{1}" -f ($desktopIntroState | ConvertTo-Json -Compress), $desktopIntroShot)
Write-Output ("desktop-hero`t{0}`t{1}" -f ($desktopHeroState | ConvertTo-Json -Compress), $desktopHeroShot)
Write-Output ("desktop-open`t{0}`t{1}" -f ($desktopOpenState | ConvertTo-Json -Compress), $desktopOpenShot)
Write-Output ("keyboard`t{0}" -f ($keyboardState | ConvertTo-Json -Compress))
Write-Output ("mobile-hero`t{0}`t{1}" -f ($mobileHeroState | ConvertTo-Json -Compress), $mobileHeroShot)
Write-Output ("mobile-open`t{0}`t{1}" -f ($mobileOpenState | ConvertTo-Json -Compress), $mobileOpenShot)
Write-Output ("reduced`t{0}" -f ($reducedState | ConvertTo-Json -Compress))
Write-Output ("screenshots`t{0}" -f (($desktopWorkShot, $desktopImagesShot, $mobileWorkShot, $mobileImagesShot) -join ','))

try { $null = Invoke-Cdp 'Browser.close' } catch {}
try { $ws.Dispose() } catch {}
if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
