param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot),
  [int]$Port = 4191
)

$ErrorActionPreference = 'Stop'
$Root = [System.IO.Path]::GetFullPath($Root)
$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$BaseUrl = "http://127.0.0.1:$Port"
$RunId = Get-Date -Format 'yyyyMMdd-HHmmssfff'
$Profile = Join-Path $env:TEMP "ahmad-computational-rail-$RunId"
$Output = Join-Path $env:TEMP "ahmad-computational-rail-evidence-$RunId"
$CdpId = 0
$Events = [System.Collections.ArrayList]::new()
$Ws = $null
$ChromeProcess = $null
$ServerProcess = $null
$Assertions = 0

function Assert-State([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw $Message }
  $script:Assertions++
}

function Receive-CdpMessage {
  $buffer = New-Object byte[] 65536
  $stream = [System.IO.MemoryStream]::new()
  $cancellation = [System.Threading.CancellationTokenSource]::new(20000)
  try {
    do {
      $segment = [System.ArraySegment[byte]]::new($buffer)
      $received = $Ws.ReceiveAsync($segment, $cancellation.Token).GetAwaiter().GetResult()
      if ($received.Count -gt 0) { $stream.Write($buffer, 0, $received.Count) }
    } until ($received.EndOfMessage)
    return [System.Text.Encoding]::UTF8.GetString($stream.ToArray())
  }
  finally {
    $cancellation.Dispose()
    $stream.Dispose()
  }
}

function Invoke-Cdp([string]$Method, $Params = $null) {
  $script:CdpId++
  $id = $script:CdpId
  $payload = @{ id = $id; method = $Method }
  if ($null -ne $Params) { $payload.params = $Params }
  $bytes = [System.Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Depth 30 -Compress))
  $segment = [System.ArraySegment[byte]]::new($bytes)
  $null = $Ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
  while ($true) {
    $response = (Receive-CdpMessage) | ConvertFrom-Json
    if ($null -ne $response.PSObject.Properties['id'] -and [int]$response.id -eq $id) {
      if ($response.error) { throw ("Chrome command {0} failed: {1}" -f $Method, $response.error.message) }
      return $response.result
    }
    if ($response.method) { $null = $Events.Add($response) }
  }
}

function Evaluate([string]$Expression) {
  $result = Invoke-Cdp 'Runtime.evaluate' @{
    expression = $Expression
    returnByValue = $true
    awaitPromise = $true
  }
  if ($result.exceptionDetails) { throw "Browser evaluation failed: $($result.exceptionDetails.text)" }
  return $result.result.value
}

function Evaluate-Json([string]$Expression) {
  return ([string](Evaluate $Expression)) | ConvertFrom-Json
}

function Wait-For([string]$Expression, [string]$Message, [int]$Attempts = 120) {
  for ($attempt = 0; $attempt -lt $Attempts; $attempt++) {
    try { if ([bool](Evaluate $Expression)) { return } } catch {}
    Start-Sleep -Milliseconds 100
  }
  throw $Message
}

function Save-Screenshot([string]$Path) {
  $result = Invoke-Cdp 'Page.captureScreenshot' @{ format = 'png'; fromSurface = $true }
  [System.IO.File]::WriteAllBytes($Path, [System.Convert]::FromBase64String($result.data))
}

function Set-Viewport([int]$Width, [int]$Height, [bool]$Mobile) {
  $null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{
    width = $Width; height = $Height; deviceScaleFactor = 1; mobile = $Mobile
    screenWidth = $Width; screenHeight = $Height
  }
  $null = Invoke-Cdp 'Emulation.setTouchEmulationEnabled' @{ enabled = $Mobile; maxTouchPoints = $(if ($Mobile) { 5 } else { 1 }) }
}

function Assert-NoErrors([string]$Label) {
  $null = Evaluate 'true'
  $problems = [System.Collections.Generic.List[string]]::new()
  foreach ($event in @($Events)) {
    if ($event.method -eq 'Runtime.exceptionThrown') { $problems.Add('runtime exception') }
    if ($event.method -eq 'Runtime.consoleAPICalled' -and [string]$event.params.type -eq 'error') { $problems.Add('console.error') }
    if ($event.method -eq 'Network.responseReceived' -and [double]$event.params.response.status -ge 400 -and [string]$event.params.response.url -like "$BaseUrl*") {
      $problems.Add("HTTP $($event.params.response.status) $($event.params.response.url)")
    }
  }
  Assert-State ($problems.Count -eq 0) ("{0} emitted browser errors: {1}" -f $Label, ($problems -join ' | '))
}

function Test-Viewport([string]$Name, [int]$Width, [int]$Height, [bool]$Mobile) {
  $Events.Clear()
  Set-Viewport $Width $Height $Mobile
  $null = Invoke-Cdp 'Page.navigate' @{ url = "$BaseUrl/" }
  Wait-For 'document.readyState === "complete"' "$Name did not load."
  Wait-For 'document.documentElement.classList.contains("loader-complete")' "$Name loader did not complete."
  $null = Evaluate 'document.documentElement.style.scrollBehavior = "auto"; document.querySelector("#computation").scrollIntoView(); true'
  Start-Sleep -Milliseconds 1400

  $state = Evaluate-Json @'
JSON.stringify((() => {
  const rail = document.querySelector("[data-computational-rail]");
  const panels = Array.from(document.querySelectorAll(".computational-panel"));
  const first = panels[0]?.getBoundingClientRect();
  return {
    panelCount: panels.length,
    labels: panels.map(panel => panel.querySelector(".computational-panel__index, .computational-panel__label")?.textContent.trim() || ""),
    railWidth: rail?.clientWidth || 0,
    railScrollWidth: rail?.scrollWidth || 0,
    railCursor: rail ? getComputedStyle(rail).cursor : "",
    peek: rail && first ? rail.clientWidth - first.width : 0,
    pageOverflow: document.documentElement.scrollWidth - document.documentElement.clientWidth,
    writingImageCount: document.querySelectorAll('[src*="equation-source"], [src*="writing"]').length,
    equationText: document.querySelector(".computational-equation")?.textContent.replace(/\s+/g, " ").trim() || "",
    descriptionCount: Array.from(document.querySelectorAll(".computational-opening__description")).filter(element => element.textContent.includes("The equation is evaluated across a defined parameter range")).length,
    openingMediaCount: panels[0]?.querySelectorAll("img").length || 0,
    graphCount: document.querySelectorAll('img[src$="graph.webp"]').length,
    architectureCount: document.querySelectorAll('img[src$="architectural-output-1600.webp"]').length,
    scriptCount: document.querySelectorAll('img[src$="grasshopper-definition-full.webp"]').length,
    redundantMediaCount: document.querySelectorAll('img[src*="parameter-definition"], img[src*="coordinate-generation"], img[src*="generated-curve"], img[src*="grasshopper-definition-3600"], img[src*="architectural-output-2600"]').length,
    scriptHeight: document.querySelector(".computational-panel__media--script img")?.getBoundingClientRect().height || 0,
    videoMuted: document.querySelector("[data-computation-video]")?.muted || false,
    videoLoop: document.querySelector("[data-computation-video]")?.loop || false,
    videoInline: document.querySelector("[data-computation-video]")?.playsInline || false,
    videoIsLast: document.querySelector("[data-computation-video]")?.closest(".computational-panel") === panels[panels.length - 1],
    draggableMediaCount: document.querySelectorAll('.computational-panel img:not([draggable="false"]), .computational-panel video:not([draggable="false"])').length,
    panelHeight: panels[0]?.getBoundingClientRect().height || 0
  };
})())
'@
  Assert-State ($state.panelCount -eq 3) "$Name does not use the concise three-panel source sequence."
  Assert-State (($state.labels -join '|') -match '^COMPUTATIONAL DESIGN\|GRASSHOPPER SCRIPT\|$') "$Name sequence or direct labels are incorrect."
  Assert-State ($state.railScrollWidth -gt $state.railWidth -and $state.peek -ge 30) "$Name does not expose a scrollable rail with a next-panel peek."
  Assert-State ($state.railCursor -eq 'grab') "$Name rail does not expose the intended grab cursor."
  Assert-State ([Math]::Abs([double]$state.pageOverflow) -le 1) "$Name introduces page-level horizontal overflow."
  Assert-State ($state.writingImageCount -eq 0 -and $state.equationText -match 'X\(t\).*Y\(t\).*2') ("{0} does not keep the equation as real text (writing images: {1}; equation: {2})." -f $Name, $state.writingImageCount, $state.equationText)
  Assert-State ($state.descriptionCount -eq 1) "$Name does not contain exactly one operational explanation."
  Assert-State ($state.openingMediaCount -eq 2) "$Name opening does not establish Equation to Graph to Architecture immediately."
  Assert-State ($state.graphCount -eq 1 -and $state.architectureCount -eq 1 -and $state.scriptCount -eq 1 -and $state.redundantMediaCount -eq 0) "$Name repeats supplied media or still references redundant derivative crops."
  Assert-State ($state.scriptHeight -ge $(if ($Mobile) { 340 } else { 430 })) ("{0} Grasshopper script is not large enough to inspect ({1}px high)." -f $Name, [Math]::Round([double]$state.scriptHeight))
  Assert-State ($state.videoMuted -and $state.videoLoop -and $state.videoInline -and $state.videoIsLast) "$Name video attributes or final-stage placement are incomplete."
  Assert-State ($state.draggableMediaCount -eq 0) "$Name contains natively draggable process media."
  Assert-State ($state.panelHeight -le 550) "$Name rail is taller than the compact layout contract."
  $null = Evaluate 'document.querySelector("#computation").scrollIntoView({ block: "start" }); true'
  Start-Sleep -Milliseconds 250
  Save-Screenshot (Join-Path $Output "$Name.png")
  $null = Evaluate '(async () => { const rail = document.querySelector("[data-computational-rail]"); const script = document.querySelector(".computational-panel--script"); rail.scrollLeft += script.getBoundingClientRect().left - rail.getBoundingClientRect().left; await new Promise(resolve => setTimeout(resolve, 250)); return true; })()'
  Save-Screenshot (Join-Path $Output "$Name-script.png")
  $null = Evaluate 'document.querySelector("[data-computational-rail]").scrollLeft = 0; true'

  $null = Evaluate 'document.querySelector("[data-computational-rail]").scrollIntoView({ block: "center" }); true'
  Start-Sleep -Milliseconds 100
  $railRect = Evaluate-Json 'JSON.stringify((() => { const rect = document.querySelector("[data-computational-rail]").getBoundingClientRect(); return { left: rect.left, right: rect.right, top: rect.top, bottom: rect.bottom }; })())'
  $dragY = [Math]::Round(($railRect.top + $railRect.bottom) / 2)
  if (-not $Mobile) {
    $null = Invoke-Cdp 'Input.dispatchMouseEvent' @{ type = 'mousePressed'; x = [Math]::Round($railRect.right - 70); y = $dragY; button = 'left'; buttons = 1; clickCount = 1 }
    $null = Invoke-Cdp 'Input.dispatchMouseEvent' @{ type = 'mouseMoved'; x = [Math]::Round($railRect.left + 120); y = $dragY; button = 'left'; buttons = 1 }
    $null = Invoke-Cdp 'Input.dispatchMouseEvent' @{ type = 'mouseReleased'; x = [Math]::Round($railRect.left + 120); y = $dragY; button = 'left'; buttons = 0; clickCount = 1 }
    Start-Sleep -Milliseconds 350
    Assert-State ([double](Evaluate 'document.querySelector("[data-computational-rail]").scrollLeft') -gt 20) "$Name mouse drag did not move the rail."
    Assert-State (-not [bool](Evaluate 'document.querySelector("[data-computational-rail]").classList.contains("is-dragging")')) "$Name retained its active drag state after release."

    $wheelStart = Evaluate-Json 'JSON.stringify((() => { const rail = document.querySelector("[data-computational-rail]"); rail.scrollLeft = 0; rail.scrollIntoView({ block: "center" }); return { pageY: scrollY, railX: rail.scrollLeft }; })())'
    $null = Invoke-Cdp 'Input.dispatchMouseEvent' @{ type = 'mouseWheel'; x = [Math]::Round(($railRect.left + $railRect.right) / 2); y = $dragY; deltaX = 0; deltaY = 180 }
    Start-Sleep -Milliseconds 250
    $wheelInside = Evaluate-Json 'JSON.stringify({ pageY: scrollY, railX: document.querySelector("[data-computational-rail]").scrollLeft })'
    Assert-State ($wheelInside.railX -gt 40 -and [Math]::Abs([double]$wheelInside.pageY - [double]$wheelStart.pageY) -lt 5) "$Name wheel input did not stay horizontal while rail movement remained."

    $wheelEnd = Evaluate-Json 'JSON.stringify((() => { const rail = document.querySelector("[data-computational-rail]"); rail.scrollLeft = rail.scrollWidth; return { pageY: scrollY, railX: rail.scrollLeft }; })())'
    $null = Invoke-Cdp 'Input.dispatchMouseEvent' @{ type = 'mouseWheel'; x = [Math]::Round(($railRect.left + $railRect.right) / 2); y = $dragY; deltaX = 0; deltaY = 180 }
    Start-Sleep -Milliseconds 250
    Assert-State ([double](Evaluate 'scrollY') -gt [double]$wheelEnd.pageY + 20) "$Name trapped vertical page scrolling at the end of the rail."
  }

  $null = Evaluate '(async () => { const rail = document.querySelector("[data-computational-rail]"); const panels = document.querySelectorAll(".computational-panel"); rail.scrollIntoView({ block: "center" }); rail.scrollLeft += panels[panels.length - 1].getBoundingClientRect().left - rail.getBoundingClientRect().left; await new Promise(resolve => setTimeout(resolve, 700)); return true; })()'
  Start-Sleep -Milliseconds 700
  $videoState = Evaluate-Json @'
JSON.stringify((() => {
  const video = document.querySelector("[data-computation-video]");
  const rail = document.querySelector("[data-computational-rail]");
  const rect = video.getBoundingClientRect();
  return { paused: video.paused, readyState: video.readyState, error: video.error?.message || "", left: rect.left, right: rect.right, top: rect.top, bottom: rect.bottom, railLeft: rail.scrollLeft, reduced: matchMedia("(prefers-reduced-motion: reduce)").matches };
})())
'@
  Assert-State (-not $videoState.paused) ("{0} video did not autoplay when visible: {1}" -f $Name, ($videoState | ConvertTo-Json -Compress))
  $null = Evaluate '(async () => { const rail = document.querySelector("[data-computational-rail]"); const panels = document.querySelectorAll(".computational-panel"); for (const panel of panels) { rail.scrollLeft += panel.getBoundingClientRect().left - rail.getBoundingClientRect().left; await new Promise(resolve => setTimeout(resolve, 240)); } return true; })()'
  Wait-For 'Array.from(document.querySelectorAll(".computational-panel img")).every(image => image.complete && image.naturalWidth > 0)' "$Name did not load every supplied process image." 80
  $null = Evaluate '(async () => { const rail = document.querySelector("[data-computational-rail]"); rail.scrollLeft = 0; await new Promise(resolve => setTimeout(resolve, 500)); return true; })()'
  Assert-State ([bool](Evaluate 'document.querySelector("[data-computation-video]").paused')) "$Name video continued playing offscreen."

  if ($Mobile) {
    $null = Evaluate 'const mobileRail = document.querySelector("[data-computational-rail]"); mobileRail.scrollLeft = 0; mobileRail.scrollIntoView({ block: "center" }); true'
    Start-Sleep -Milliseconds 100
    $mobileRect = Evaluate-Json 'JSON.stringify((() => { const rect = document.querySelector("[data-computational-rail]").getBoundingClientRect(); return { left: rect.left, right: rect.right, top: rect.top, bottom: rect.bottom }; })())'
    $touchY = [Math]::Round(($mobileRect.top + $mobileRect.bottom) / 2)
    $null = Invoke-Cdp 'Input.dispatchTouchEvent' @{ type = 'touchStart'; touchPoints = @(@{ x = [Math]::Round($mobileRect.right - 36); y = $touchY }) }
    $null = Invoke-Cdp 'Input.dispatchTouchEvent' @{ type = 'touchMove'; touchPoints = @(@{ x = [Math]::Round($mobileRect.left + 70); y = $touchY }) }
    $null = Invoke-Cdp 'Input.dispatchTouchEvent' @{ type = 'touchEnd'; touchPoints = @() }
    Start-Sleep -Milliseconds 350
    Assert-State ([double](Evaluate 'document.querySelector("[data-computational-rail]").scrollLeft') -gt 20) "$Name touch swipe did not move the rail."
  }

  Assert-NoErrors $Name
}

$failure = $null
try {
  Assert-State (Test-Path -LiteralPath $Chrome -PathType Leaf) 'Google Chrome is unavailable.'
  New-Item -ItemType Directory -Force -Path $Profile,$Output | Out-Null
  $serverScript = Join-Path $Root 'scripts\serve-static.ps1'
  $serverArguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Root "{1}" -Port {2}' -f $serverScript, $Root, $Port
  $ServerProcess = Start-Process -FilePath 'powershell.exe' -ArgumentList $serverArguments -PassThru -WindowStyle Hidden
  $deadline = (Get-Date).AddSeconds(10)
  do {
    try { $ready = (Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/" -TimeoutSec 1).StatusCode -eq 200 } catch { $ready = $false }
    if (-not $ready) { Start-Sleep -Milliseconds 100 }
  } until ($ready -or (Get-Date) -ge $deadline)
  Assert-State $ready 'The local server did not start.'

  $ChromeProcess = Start-Process -FilePath $Chrome -ArgumentList @(
    '--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
    '--autoplay-policy=no-user-gesture-required', '--remote-debugging-port=0', '--remote-allow-origins=*',
    "--user-data-dir=$Profile", 'about:blank'
  ) -PassThru -WindowStyle Hidden
  $portFile = Join-Path $Profile 'DevToolsActivePort'
  $deadline = (Get-Date).AddSeconds(15)
  while (-not (Test-Path -LiteralPath $portFile) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 100 }
  Assert-State (Test-Path -LiteralPath $portFile -PathType Leaf) 'Chrome did not expose its test endpoint.'
  $debugPort = [int](Get-Content -LiteralPath $portFile | Select-Object -First 1)
  $target = (Invoke-RestMethod -Uri "http://127.0.0.1:$debugPort/json/list") | Where-Object { $_.type -eq 'page' } | Select-Object -First 1
  $Ws = [System.Net.WebSockets.ClientWebSocket]::new()
  $null = $Ws.ConnectAsync([System.Uri]$target.webSocketDebuggerUrl, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
  foreach ($method in @('Page.enable', 'Runtime.enable', 'Network.enable')) { $null = Invoke-Cdp $method }
  $null = Invoke-Cdp 'Network.setCacheDisabled' @{ cacheDisabled = $true }

  Test-Viewport 'desktop-1440x900' 1440 900 $false
  Test-Viewport 'mobile-390x844' 390 844 $true
  Write-Output ("Computational rail verification PASS: {0} assertions." -f $Assertions)
  Write-Output ("Evidence: {0}" -f $Output)
}
catch { $failure = $_ }
finally {
  if ($null -ne $Ws) { try { $Ws.Dispose() } catch {} }
  foreach ($process in @($ChromeProcess, $ServerProcess)) {
    if ($null -ne $process) { try { if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force } } catch {} }
  }
}

if ($null -ne $failure) { throw $failure }
