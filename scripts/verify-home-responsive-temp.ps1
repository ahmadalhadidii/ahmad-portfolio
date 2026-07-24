param([int]$Port = 4191)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$profile = Join-Path $env:TEMP ('ahmad-home-responsive-' + [guid]::NewGuid())
$server = $null
$browser = $null
$socket = $null
$script:id = 0

function Receive-Cdp {
  $buffer = New-Object byte[] 65536
  $stream = [System.IO.MemoryStream]::new()
  do {
    $part = [System.ArraySegment[byte]]::new($buffer)
    $read = $socket.ReceiveAsync($part, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
    if ($read.Count) { $stream.Write($buffer, 0, $read.Count) }
  } until ($read.EndOfMessage)
  $result = [System.Text.Encoding]::UTF8.GetString($stream.ToArray())
  $stream.Dispose()
  $result
}

function Invoke-Cdp([string]$method, $params = $null) {
  $script:id++
  $payload = @{ id = $script:id; method = $method }
  if ($null -ne $params) { $payload.params = $params }
  $bytes = [System.Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Depth 20 -Compress))
  $segment = [System.ArraySegment[byte]]::new($bytes)
  $null = $socket.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
  do { $response = (Receive-Cdp) | ConvertFrom-Json } until ($response.id -eq $script:id)
  if ($response.error) { throw "$method failed: $($response.error.message)" }
  $response.result
}

function Evaluate([string]$expression) {
  $result = Invoke-Cdp 'Runtime.evaluate' @{ expression = $expression; returnByValue = $true; awaitPromise = $true }
  if ($result.exceptionDetails) { throw "Browser evaluation failed: $($result.exceptionDetails.exception.description)" }
  $result.result.value
}

function Wait-For([string]$expression) {
  for ($attempt = 0; $attempt -lt 80; $attempt++) {
    if (Evaluate $expression) { return }
    Start-Sleep -Milliseconds 75
  }
  throw "Timed out: $expression"
}

function Test-Viewport([int]$width, [int]$height) {
  $null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = $width; height = $height; deviceScaleFactor = 1; mobile = $true; screenWidth = $width; screenHeight = $height }
  $null = Invoke-Cdp 'Emulation.setTouchEmulationEnabled' @{ enabled = $true; maxTouchPoints = 5 }
  $null = Invoke-Cdp 'Page.navigate' @{ url = "http://127.0.0.1:$Port/" }
  Start-Sleep -Milliseconds 500
  Wait-For 'location.href.indexOf("http://127.0.0.1:4191/") === 0 && document.querySelector(".monitor__screen") && document.querySelector(".showreel__slide--image")'
  Wait-For '!document.documentElement.classList.contains("loader-pending")'
  Wait-For 'document.querySelector("#showreel")?.dataset.showreelInitialized === "true" && document.querySelector(".showreel__slide--image img")?.naturalWidth > 0'
  Start-Sleep -Milliseconds 200
  $state = (Evaluate @'
JSON.stringify((() => {
  const box = node => { const r = node.getBoundingClientRect(); return { left:r.left, top:r.top, right:r.right, width:r.width, height:r.height }; };
  const screen = document.querySelector('.monitor__screen');
  const monitor = document.querySelector('.broadcast-monitor');
  const roles = document.querySelector('.opening__roles');
  const meta = document.querySelector('.opening__meta');
  const imageSlide = document.querySelector('.showreel__slide--image');
  imageSlide.classList.add('is-active');
  const image = imageSlide.querySelector('img');
  return {
    width: innerWidth,
    rootOverflow: document.documentElement.scrollWidth - document.documentElement.clientWidth,
    bodyOverflow: document.body.scrollWidth - document.documentElement.clientWidth,
    monitor: box(monitor),
    screen: box(screen),
    screenRatio: screen.getBoundingClientRect().width / screen.getBoundingClientRect().height,
    roles: box(roles),
    meta: box(meta),
    image: { naturalWidth:image.naturalWidth, naturalHeight:image.naturalHeight, objectFit:getComputedStyle(image).objectFit, ...box(image) },
    parallaxEnabled: Boolean(document.querySelector('[data-parallax]')?.style.getPropertyValue('--parallax-y'))
  };
})())
'@ | ConvertFrom-Json)
  if ($state.rootOverflow -gt 1 -or $state.bodyOverflow -gt 1) { throw "Horizontal overflow at ${width}px: root=$($state.rootOverflow), body=$($state.bodyOverflow)" }
  if ([math]::Abs($state.screenRatio - (16 / 9)) -gt 0.02) { throw "Monitor aspect ratio is incorrect at ${width}px: $($state.screenRatio)" }
  if ($state.monitor.left -lt -1 -or $state.monitor.right -gt ($width + 1)) { throw "Monitor overflows at ${width}px" }
  if ($state.image.naturalWidth -le 0 -or $state.image.objectFit -ne 'cover') { throw "Showreel image does not preserve its cover presentation at ${width}px" }
  if ($width -le 560 -and $state.meta.top -le $state.roles.top) { throw "Mobile opening content order is incorrect at ${width}px" }
  if ($width -gt 560 -and $state.meta.left -le $state.roles.left) { throw "Tablet opening columns are incorrect at ${width}px" }
  [pscustomobject]@{ width = $state.width; overflow = $state.rootOverflow; monitor = "$([math]::Round($state.screen.width))x$([math]::Round($state.screen.height))"; ratio = [math]::Round($state.screenRatio, 3); imageLoaded = $state.image.naturalWidth -gt 0; parallaxEnabled = $state.parallaxEnabled }
}

try {
  $server = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$root\scripts\serve-static.ps1`" -Root `"$root`" -Port $Port" -PassThru -WindowStyle Hidden
  $ready = $false
  for ($attempt = 0; $attempt -lt 50; $attempt++) {
    try {
      $response = Invoke-WebRequest -UseBasicParsing "http://127.0.0.1:$Port/" -TimeoutSec 1
      if ($response.StatusCode -eq 200 -and $response.Content -match 'monitor__screen') { $ready = $true; break }
    } catch {}
    Start-Sleep -Milliseconds 100
  }
  if (-not $ready) { throw 'The homepage test server did not serve the homepage.' }
  New-Item -ItemType Directory -Path $profile | Out-Null
  $browser = Start-Process $chrome -ArgumentList '--headless=new','--disable-gpu','--no-first-run','--remote-debugging-port=0','--remote-allow-origins=*',"--user-data-dir=$profile",'about:blank' -PassThru -WindowStyle Hidden
  $portFile = Join-Path $profile 'DevToolsActivePort'
  for ($attempt = 0; $attempt -lt 100 -and -not (Test-Path $portFile); $attempt++) { Start-Sleep -Milliseconds 50 }
  if (-not (Test-Path $portFile)) { throw 'Chrome did not start its debugging endpoint.' }
  $debugPort = [int](Get-Content $portFile | Select-Object -First 1)
  $target = Invoke-RestMethod -Method Put -Uri "http://127.0.0.1:$debugPort/json/new?about:blank"
  $socket = [System.Net.WebSockets.ClientWebSocket]::new()
  $webSocketUrl = [string]($target | Select-Object -ExpandProperty webSocketDebuggerUrl -First 1)
  $null = $socket.ConnectAsync([Uri]$webSocketUrl, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
  $null = Invoke-Cdp 'Page.enable'; $null = Invoke-Cdp 'Runtime.enable'
  @(Test-Viewport 390 844; Test-Viewport 768 1024; Test-Viewport 1024 768) | Format-Table -AutoSize
}
finally {
  if ($socket) { $socket.Dispose() }
  foreach ($process in @($browser, $server)) { if ($process) { try { if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force } } catch {} } }
  if (Test-Path $profile) { Start-Sleep -Milliseconds 300; Remove-Item -LiteralPath $profile -Recurse -Force -ErrorAction SilentlyContinue }
}
