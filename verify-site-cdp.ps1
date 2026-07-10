$ErrorActionPreference = 'Stop'

$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$outDir = Join-Path $env:TEMP 'ahmad-portfolio-editorial-check'
$runId = Get-Date -Format 'yyyyMMdd-HHmmssfff'
$profile = Join-Path $outDir ("profile-$runId")
$homeUrl = ([System.Uri]::new((Resolve-Path '.\index.html').Path)).AbsoluteUri
$projectBaseUrl = ([System.Uri]::new((Resolve-Path '.\project.html').Path)).AbsoluteUri

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

function Navigate([string]$url) {
  $null = Invoke-Cdp 'Page.navigate' @{ url = $url }
  for ($i = 0; $i -lt 120; $i++) {
    try {
      if ([bool](Evaluate 'document.readyState !== "loading"')) { return }
    } catch {}
    Start-Sleep -Milliseconds 100
  }
  throw "Page did not finish parsing: $url"
}

function Wait-For([string]$expression, [string]$message) {
  for ($i = 0; $i -lt 120; $i++) {
    try {
      if ([bool](Evaluate $expression)) { return }
    } catch {}
    Start-Sleep -Milliseconds 100
  }
  throw $message
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

function Home-State {
  $expression = @'
JSON.stringify({
  width: innerWidth,
  height: innerHeight,
  bodyClass: document.body.className,
  htmlClass: document.documentElement.className,
  introHidden: !document.getElementById("intro") || document.getElementById("intro").hidden || getComputedStyle(document.getElementById("intro")).display === "none",
  introCount: document.getElementById("intro-count") ? document.getElementById("intro-count").textContent : null,
  previews: document.querySelectorAll(".project-preview").length,
  linkedPreviews: document.querySelectorAll('.project-preview__link[href^="project.html?project="]').length,
  methodStages: document.querySelectorAll(".method-stage").length,
  cvGroups: document.querySelectorAll(".cv-group").length,
  cvSupportGroups: document.querySelectorAll(".cv-support-group").length,
  contactLinks: document.querySelectorAll(".contact__links a").length,
  missingMedia: document.querySelectorAll(".media-frame.is-missing").length,
  darkProgress: getComputedStyle(document.documentElement).getPropertyValue("--dark-progress").trim(),
  activeNav: document.querySelector(".site-nav a.is-active") ? document.querySelector(".site-nav a.is-active").dataset.sectionLink : null,
  menuExpanded: document.getElementById("nav-toggle") ? document.getElementById("nav-toggle").getAttribute("aria-expanded") : null,
  focused: document.activeElement ? (document.activeElement.dataset.sectionLink || document.activeElement.id || document.activeElement.tagName) : null,
  scrollWidth: document.documentElement.scrollWidth,
  clientWidth: document.documentElement.clientWidth
})
'@
  return (Evaluate $expression) | ConvertFrom-Json
}

function Project-State {
  $expression = @'
JSON.stringify({
  title: document.title,
  projectKey: document.body.dataset.project || null,
  hero: document.querySelectorAll(".project-hero").length,
  metaItems: document.querySelectorAll(".project-meta__item").length,
  introductionItems: document.querySelectorAll(".project-introduction__item").length,
  narrativeFigures: document.querySelectorAll(".project-narrative .project-detail-figure").length,
  informationItems: document.querySelectorAll(".project-information__item").length,
  paginationLinks: document.querySelectorAll(".project-pagination a").length,
  missingMedia: document.querySelectorAll(".project-detail-media.is-missing").length,
  errorState: document.querySelectorAll(".project-detail__error").length,
  errorHeading: document.querySelector(".project-detail__error-title") ? document.querySelector(".project-detail__error-title").textContent : null,
  scrollWidth: document.documentElement.scrollWidth,
  clientWidth: document.documentElement.clientWidth
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

Navigate $homeUrl
Wait-For 'document.querySelectorAll(".project-preview").length === 6 && document.querySelectorAll(".method-stage").length === 5' 'Home content did not render.'
Start-Sleep -Milliseconds 450
$bootState = Home-State
$bootShot = Save-Screenshot 'desktop-boot'
Start-Sleep -Milliseconds 2050
$desktopHeroState = Home-State
$desktopHeroShot = Save-Screenshot 'desktop-hero'

$null = Evaluate 'document.getElementById("profile").scrollIntoView({block:"start"}); true'
Start-Sleep -Milliseconds 180
$profileShot = Save-Screenshot 'desktop-profile'
$null = Evaluate 'document.getElementById("cv").scrollIntoView({block:"start"}); true'
Start-Sleep -Milliseconds 180
$cvShot = Save-Screenshot 'desktop-cv'
$null = Evaluate 'document.getElementById("work").scrollIntoView({block:"start"}); true'
Start-Sleep -Milliseconds 260
$workState = Home-State
$workShot = Save-Screenshot 'desktop-work'
$null = Evaluate 'document.getElementById("method").scrollIntoView({block:"start"}); true'
Start-Sleep -Milliseconds 220
$methodState = Home-State
$methodShot = Save-Screenshot 'desktop-method'
$null = Evaluate 'document.getElementById("contact").scrollIntoView({block:"start"}); true'
Start-Sleep -Milliseconds 260
$contactState = Home-State
$contactShot = Save-Screenshot 'desktop-contact'

$null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{
  width = 360
  height = 800
  deviceScaleFactor = 1
  mobile = $true
  screenWidth = 360
  screenHeight = 800
}
Navigate $homeUrl
Wait-For 'document.querySelectorAll(".project-preview").length === 6' 'Mobile home content did not render.'
Start-Sleep -Milliseconds 250
$mobileState = Home-State
$mobileHeroShot = Save-Screenshot 'mobile-hero'
$null = Evaluate 'document.getElementById("nav-toggle").click(); true'
Start-Sleep -Milliseconds 120
$menuOpenState = Home-State
$menuShot = Save-Screenshot 'mobile-menu'
$null = Evaluate 'document.dispatchEvent(new KeyboardEvent("keydown", {key:"Escape", bubbles:true})); true'
Start-Sleep -Milliseconds 80
$menuClosedState = Home-State
$null = Evaluate 'document.getElementById("work").scrollIntoView({block:"start"}); true'
Start-Sleep -Milliseconds 220
$mobileWorkState = Home-State
$mobileWorkShot = Save-Screenshot 'mobile-work'

$null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{
  features = @(@{ name = 'prefers-reduced-motion'; value = 'reduce' })
}
$null = Evaluate 'sessionStorage.removeItem("portfolio:intro:v3"); true'
Navigate $homeUrl
Wait-For 'document.querySelectorAll(".project-preview").length === 6' 'Reduced-motion home did not render.'
Start-Sleep -Milliseconds 120
$reducedState = Home-State

$null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{
  features = @(@{ name = 'prefers-reduced-motion'; value = 'no-preference' })
}
Navigate ($projectBaseUrl + '?project=project-01')
Wait-For 'document.querySelectorAll(".project-hero").length === 1 && document.querySelectorAll(".project-information__item").length === 5' 'Valid project did not render.'
Start-Sleep -Milliseconds 220
$validProjectState = Project-State
$validProjectShot = Save-Screenshot 'mobile-project-valid'

Navigate ($projectBaseUrl + '?project=missing')
Wait-For 'document.querySelectorAll(".project-detail__error").length === 1' 'Invalid-project fallback did not render.'
$invalidProjectState = Project-State

Write-Output ("boot`t{0}`t{1}" -f ($bootState | ConvertTo-Json -Compress), $bootShot)
Write-Output ("desktop-hero`t{0}`t{1}" -f ($desktopHeroState | ConvertTo-Json -Compress), $desktopHeroShot)
Write-Output ("work-theme`t{0}`t{1}" -f ($workState | ConvertTo-Json -Compress), $workShot)
Write-Output ("method-theme`t{0}`t{1}" -f ($methodState | ConvertTo-Json -Compress), $methodShot)
Write-Output ("contact-theme`t{0}`t{1}" -f ($contactState | ConvertTo-Json -Compress), $contactShot)
Write-Output ("mobile-home`t{0}`t{1}" -f ($mobileState | ConvertTo-Json -Compress), $mobileHeroShot)
Write-Output ("mobile-menu-open`t{0}`t{1}" -f ($menuOpenState | ConvertTo-Json -Compress), $menuShot)
Write-Output ("mobile-menu-closed`t{0}" -f ($menuClosedState | ConvertTo-Json -Compress))
Write-Output ("mobile-work`t{0}`t{1}" -f ($mobileWorkState | ConvertTo-Json -Compress), $mobileWorkShot)
Write-Output ("reduced`t{0}" -f ($reducedState | ConvertTo-Json -Compress))
Write-Output ("project-valid`t{0}`t{1}" -f ($validProjectState | ConvertTo-Json -Compress), $validProjectShot)
Write-Output ("project-invalid`t{0}" -f ($invalidProjectState | ConvertTo-Json -Compress))
Write-Output ("section-shots`t{0}" -f (($profileShot, $cvShot, $methodShot, $contactShot) -join ','))

try { $null = Invoke-Cdp 'Browser.close' } catch {}
try { $ws.Dispose() } catch {}
if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
