$ErrorActionPreference = 'Stop'

$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$outDir = Join-Path $env:TEMP 'ahmad-reference-inspection'
$runId = Get-Date -Format 'yyyyMMdd-HHmmssfff'
$profile = Join-Path $outDir ("cdp-profile-$runId")
$url = 'https://frank-reservation-697225-6f928b65c.framer.app/'
$topShot = Join-Path $outDir ("$runId-cdp-top.png")
$fullShot = Join-Path $outDir ("$runId-cdp-full.png")
$statePath = Join-Path $outDir ("$runId-cdp-state.json")

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$process = Start-Process -FilePath $chrome -ArgumentList @(
  '--headless=new',
  '--disable-gpu',
  '--disable-background-timer-throttling',
  '--disable-backgrounding-occluded-windows',
  '--disable-renderer-backgrounding',
  '--hide-scrollbars',
  '--no-first-run',
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

function Save-Screenshot([string]$path, $clip = $null) {
  $params = @{ format = 'png'; fromSurface = $true; captureBeyondViewport = $true }
  if ($null -ne $clip) { $params.clip = $clip }
  $result = Invoke-Cdp 'Page.captureScreenshot' $params
  [System.IO.File]::WriteAllBytes($path, [System.Convert]::FromBase64String($result.data))
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
$null = Invoke-Cdp 'Page.navigate' @{ url = $url }

$ready = $false
for ($i = 0; $i -lt 150 -and -not $ready; $i++) {
  try {
    $result = Invoke-Cdp 'Runtime.evaluate' @{ expression = 'document.readyState'; returnByValue = $true }
    $ready = $result.result.value -eq 'complete'
  } catch { $ready = $false }
  if (-not $ready) { Start-Sleep -Milliseconds 100 }
}
if (-not $ready) { throw 'Reference page did not finish loading.' }

Start-Sleep -Seconds 8

$stateExpression = @'
JSON.stringify({
  url: location.href,
  title: document.title,
  width: innerWidth,
  height: innerHeight,
  scrollHeight: document.documentElement.scrollHeight,
  bodyText: document.body.innerText.slice(0, 12000),
  fixedElements: Array.from(document.querySelectorAll("*")).filter(function (element) {
    return getComputedStyle(element).position === "fixed";
  }).slice(0, 30).map(function (element) {
    return {
      tag: element.tagName,
      className: typeof element.className === "string" ? element.className : "",
      id: element.id,
      text: element.innerText ? element.innerText.slice(0, 200) : "",
      zIndex: getComputedStyle(element).zIndex,
      display: getComputedStyle(element).display
    };
  })
})
'@
$stateResult = Invoke-Cdp 'Runtime.evaluate' @{ expression = $stateExpression; returnByValue = $true }
$stateResult.result.value | Set-Content -Encoding utf8 -LiteralPath $statePath

$metrics = Invoke-Cdp 'Page.getLayoutMetrics'
$contentSize = $metrics.cssContentSize
$viewportClip = @{
  x = 0
  y = 0
  width = 1440
  height = 900
  scale = 1
}
Save-Screenshot $topShot $viewportClip

$sectionShots = @()
for ($y = 900; $y -lt [double]$contentSize.height; $y += 900) {
  $sectionPath = Join-Path $outDir ("$runId-cdp-y$y.png")
  $height = [Math]::Min(900, [double]$contentSize.height - $y)
  $null = Invoke-Cdp 'Runtime.evaluate' @{
    expression = "window.scrollTo(0, $y); true"
    returnByValue = $true
  }
  Start-Sleep -Milliseconds 650
  Save-Screenshot $sectionPath @{
    x = 0
    y = [double]$y
    width = 1440
    height = [double]$height
    scale = 1
  }
  $sectionShots += $sectionPath
}

$null = Invoke-Cdp 'Runtime.evaluate' @{ expression = 'window.scrollTo(0, 0); true'; returnByValue = $true }
Start-Sleep -Milliseconds 300

$captureHeight = [Math]::Min([double]$contentSize.height, 12000)
Save-Screenshot $fullShot @{
  x = 0
  y = 0
  width = [double]$contentSize.width
  height = $captureHeight
  scale = 1
}

Get-Item -LiteralPath (@($topShot, $fullShot, $statePath) + $sectionShots) | Select-Object Name, Length, FullName

try { $null = Invoke-Cdp 'Browser.close' } catch {}
try { $ws.Dispose() } catch {}
if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
