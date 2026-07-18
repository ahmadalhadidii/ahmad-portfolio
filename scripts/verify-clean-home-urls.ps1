param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot),
  [int]$Port = 4175
)

$ErrorActionPreference = 'Stop'
$Root = [System.IO.Path]::GetFullPath($Root)
$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$BaseUrl = "http://127.0.0.1:$Port"
$Assertions = 0
$CdpId = 0
$Events = [System.Collections.ArrayList]::new()
$Ws = $null
$ChromeProcess = $null
$ServerProcess = $null
$BrowserProfilePath = Join-Path $env:TEMP ("ahmad-clean-home-urls-" + (Get-Date -Format 'yyyyMMdd-HHmmssfff'))

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
      if ($received.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) {
        throw 'Chrome closed its browser-test connection unexpectedly.'
      }
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
      if ($response.error) { throw ("Chrome test command {0} failed: {1}" -f $Method, $response.error.message) }
      return $response.result
    }
    if ($response.method) { $null = $Events.Add($response) }
  }
}

function Get-BrowserValue([string]$Expression) {
  $result = Invoke-Cdp 'Runtime.evaluate' @{
    expression = $Expression
    returnByValue = $true
    awaitPromise = $true
  }
  if ($result.exceptionDetails) {
    $description = [string]$result.exceptionDetails.text
    if ($result.exceptionDetails.exception.description) { $description = [string]$result.exceptionDetails.exception.description }
    throw "Browser evaluation failed: $description"
  }
  return $result.result.value
}

function Get-BrowserJson([string]$Expression) {
  $value = Get-BrowserValue $Expression
  if ($null -eq $value -or $value -eq '') { return $null }
  return ([string]$value) | ConvertFrom-Json
}

function Wait-For([string]$Expression, [string]$Message, [int]$Attempts = 160) {
  for ($attempt = 0; $attempt -lt $Attempts; $attempt++) {
    try {
      if ([bool](Get-BrowserValue $Expression)) { return }
    } catch {}
    Start-Sleep -Milliseconds 100
  }
  throw $Message
}

function Navigate([string]$Url) {
  $null = Invoke-Cdp 'Page.navigate' @{ url = $Url }
  Wait-For 'document.readyState !== "loading"' "Page did not load: $Url"
}

function Wait-For-Location([string]$Pathname, [string]$Hash = '', [string]$Search = '') {
  $pathLiteral = ConvertTo-Json -InputObject $Pathname -Compress
  $hashLiteral = ConvertTo-Json -InputObject $Hash -Compress
  $searchLiteral = ConvertTo-Json -InputObject $Search -Compress
  Wait-For "location.pathname === $pathLiteral && location.hash === $hashLiteral && location.search === $searchLiteral && document.readyState !== 'loading'" "The browser did not reach $Pathname$Search$Hash."
}

function Wait-For-Home([string]$Hash = '', [string]$Search = '') {
  Wait-For-Location '/' $Hash $Search
  Wait-For 'document.body?.classList.contains("home-page") && document.querySelector("#index")' 'The homepage document did not load.'
}

function Click([string]$Selector, [string]$Message) {
  $selectorLiteral = ConvertTo-Json -InputObject $Selector -Compress
  Assert-State ([int](Get-BrowserValue "document.querySelectorAll($selectorLiteral).length") -eq 1) $Message
  $null = Get-BrowserValue "document.querySelector($selectorLiteral).click(); true"
}

function Assert-Clean-Home([string]$RequestedPath) {
  $search = '?legacy=1'
  $hash = '#work'
  Navigate "$BaseUrl$RequestedPath$search$hash"
  Wait-For-Home $hash $search
  $timeOrigin = [double](Get-BrowserValue 'performance.timeOrigin')
  Start-Sleep -Milliseconds 350
  Assert-State ([double](Get-BrowserValue 'performance.timeOrigin') -eq $timeOrigin) "Legacy homepage normalization looped for $RequestedPath."
  $state = Get-BrowserJson @'
JSON.stringify({
  pathname: location.pathname,
  search: location.search,
  hash: location.hash,
  canonical: document.querySelector('link[rel="canonical"]')?.href || '',
  ogUrl: document.querySelector('meta[property="og:url"]')?.content || ''
})
'@
  Assert-State ($state.pathname -eq '/' -and $state.search -eq $search -and $state.hash -eq $hash) "Legacy homepage URL remained visible for $RequestedPath."
  Assert-State ($state.canonical -eq 'https://www.ahmadalhadidii.manmatic.institute/' -and $state.ogUrl -eq 'https://www.ahmadalhadidii.manmatic.institute/') 'Homepage canonical or Open Graph URL changed.'
}

function Assert-NoBrowserErrors {
  $null = Get-BrowserValue 'true'
  $problems = [System.Collections.Generic.List[string]]::new()
  foreach ($CdpEvent in @($Events)) {
    if ($CdpEvent.method -eq 'Runtime.exceptionThrown') {
      $detail = [string]$CdpEvent.params.exceptionDetails.text
      if ($CdpEvent.params.exceptionDetails.exception.description) { $detail = [string]$CdpEvent.params.exceptionDetails.exception.description }
      $problems.Add("runtime exception: $detail")
    }
    if ($CdpEvent.method -eq 'Runtime.consoleAPICalled' -and [string]$CdpEvent.params.type -eq 'error') {
      $problems.Add('console.error was emitted')
    }
  }
  Assert-State ($problems.Count -eq 0) ("Clean-home navigation emitted browser errors: {0}" -f ($problems -join ' | '))
}

$failure = $null
try {
  Assert-State (Test-Path -LiteralPath $Chrome -PathType Leaf) 'Google Chrome is unavailable for clean-home URL validation.'
  New-Item -ItemType Directory -Force -Path $BrowserProfilePath | Out-Null

  $serverScript = Join-Path $Root 'scripts\serve-static.ps1'
  $serverArguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Root "{1}" -Port {2}' -f $serverScript, $Root, $Port
  $ServerProcess = Start-Process -FilePath 'powershell.exe' -ArgumentList $serverArguments -PassThru -WindowStyle Hidden
  $deadline = (Get-Date).AddSeconds(10)
  do {
    try { $ready = (Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/" -TimeoutSec 1).StatusCode -eq 200 } catch { $ready = $false }
    if (-not $ready) { Start-Sleep -Milliseconds 100 }
  } until ($ready -or (Get-Date) -ge $deadline)
  Assert-State $ready 'The local clean-home URL test server did not start.'

  $ChromeProcess = Start-Process -FilePath $Chrome -ArgumentList @(
    '--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
    '--remote-debugging-port=0', '--remote-allow-origins=*', "--user-data-dir=$BrowserProfilePath", 'about:blank'
  ) -PassThru -WindowStyle Hidden
  $portFile = Join-Path $BrowserProfilePath 'DevToolsActivePort'
  $deadline = (Get-Date).AddSeconds(15)
  while (-not (Test-Path -LiteralPath $portFile) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 100 }
  Assert-State (Test-Path -LiteralPath $portFile -PathType Leaf) 'Chrome did not expose its browser-test endpoint.'
  $debugPort = [int](Get-Content -LiteralPath $portFile | Select-Object -First 1)
  $targets = Invoke-RestMethod -Uri "http://127.0.0.1:$debugPort/json/list"
  $target = $targets | Where-Object { $_.type -eq 'page' } | Select-Object -First 1
  Assert-State ($null -ne $target) 'Chrome did not create a page target.'
  $Ws = [System.Net.WebSockets.ClientWebSocket]::new()
  $null = $Ws.ConnectAsync([System.Uri]$target.webSocketDebuggerUrl, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
  foreach ($method in @('Page.enable', 'Runtime.enable', 'Log.enable', 'Network.enable')) { $null = Invoke-Cdp $method }
  $null = Invoke-Cdp 'Network.setCacheDisabled' @{ cacheDisabled = $true }

  Navigate "$BaseUrl/"
  Wait-For-Home
  $homeOrigin = [double](Get-BrowserValue 'performance.timeOrigin')
  $null = Invoke-Cdp 'Page.reload' @{ ignoreCache = $true }
  Wait-For "performance.timeOrigin !== $homeOrigin" 'Refreshing the homepage did not create a new document.'
  Wait-For-Home

  foreach ($legacyPath in @('/index', '/index/', '/index.html')) { Assert-Clean-Home $legacyPath }

  Navigate "$BaseUrl/#work"
  Wait-For-Home '#work'
  Click '.project-row__link[href="/projects/manmatic/"]' 'The homepage ManMaTIC project link is missing or duplicated.'
  Wait-For-Location '/projects/manmatic/'
  $null = Get-BrowserValue 'history.back(); true'
  Wait-For-Home '#work'

  Navigate "$BaseUrl/#visual-studies"
  Wait-For-Home '#visual-studies'
  Click '.visual-slide__open[href="/visuals/architecture-of-elsewhere/"]' 'The homepage Visual link is missing or duplicated.'
  Wait-For-Location '/visuals/architecture-of-elsewhere/'
  $null = Get-BrowserValue 'history.back(); true'
  Wait-For-Home '#visual-studies'

  Navigate "$BaseUrl/projects/protocol-port/"
  Wait-For-Location '/projects/protocol-port/'
  Click '.project-header__system-nav a[href="/projects/manmatic/"]' 'The Protocol Port return-to-ManMaTIC link is missing or duplicated.'
  Wait-For-Location '/projects/manmatic/'
  $null = Get-BrowserValue 'history.back(); true'
  Wait-For-Location '/projects/protocol-port/'

  Navigate "$BaseUrl/visuals/architecture-of-elsewhere/"
  Wait-For-Location '/visuals/architecture-of-elsewhere/'
  Click '.visual-record__all[href="/#visual-studies"]' 'The Visual return-to-Visuals link is missing or duplicated.'
  Wait-For-Home '#visual-studies'

  Navigate "$BaseUrl/projects/manmatic/"
  Wait-For-Location '/projects/manmatic/'
  Click '.project-navigation__top a[href="/#work"]' 'The Project return-to-Work link is missing or duplicated.'
  Wait-For-Home '#work'

  $null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 1; mobile = $true; screenWidth = 390; screenHeight = 844 }
  $null = Invoke-Cdp 'Emulation.setTouchEmulationEnabled' @{ enabled = $true; maxTouchPoints = 5 }
  Navigate "$BaseUrl/projects/dabouq/"
  Wait-For-Location '/projects/dabouq/'
  Click '#nav-toggle' 'The mobile menu toggle is missing or duplicated.'
  Wait-For 'document.querySelector("#nav-toggle")?.getAttribute("aria-expanded") === "true"' 'The mobile menu did not open.'
  Click '#primary-navigation a[href="/"]' 'The mobile-menu Home link is missing or duplicated.'
  Wait-For-Home

  Navigate "$BaseUrl/visuals/stone-by-moonlight/"
  Wait-For-Location '/visuals/stone-by-moonlight/'
  Click '.site-header__name[href="/"]' 'The detail-page logo Home link is missing or duplicated.'
  Wait-For-Home

  foreach ($projectPath in @('/projects/shila/', '/projects/manmatic/', '/projects/protocol-port/', '/projects/dabouq/', '/projects/concrete-fatigue/')) {
    Navigate "$BaseUrl$projectPath"
    Wait-For-Location $projectPath
    $projectState = Get-BrowserJson 'JSON.stringify({ path: location.pathname, canonical: document.querySelector("link[rel=canonical]")?.href || "" })'
    Assert-State ($projectState.path -eq $projectPath -and $projectState.canonical -eq "https://www.ahmadalhadidii.manmatic.institute$projectPath") "Direct Project loading exposed an incorrect URL or canonical for $projectPath."
  }

  Navigate "$BaseUrl/visuals/architecture-of-elsewhere/"
  Wait-For-Location '/visuals/architecture-of-elsewhere/'
  $visualState = Get-BrowserJson 'JSON.stringify({ path: location.pathname, canonical: document.querySelector("link[rel=canonical]")?.href || "" })'
  Assert-State ($visualState.path -eq '/visuals/architecture-of-elsewhere/' -and $visualState.canonical -eq 'https://www.ahmadalhadidii.manmatic.institute/visuals/architecture-of-elsewhere/') 'Direct Visual loading exposed an incorrect URL or canonical.'

  Assert-NoBrowserErrors
  Write-Output ("Clean homepage URL verification PASS: {0} assertions." -f $Assertions)
}
catch {
  $failure = $_
}
finally {
  if ($null -ne $Ws) { try { $Ws.Dispose() } catch {} }
  foreach ($process in @($ChromeProcess, $ServerProcess)) {
    if ($null -ne $process) {
      try { if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force } } catch {}
    }
  }
  if (Test-Path -LiteralPath $BrowserProfilePath) {
    try {
      $profileFull = [System.IO.Path]::GetFullPath($BrowserProfilePath).TrimEnd('\')
      $tempFull = [System.IO.Path]::GetFullPath($env:TEMP).TrimEnd('\')
      $safePrefix = $tempFull + [System.IO.Path]::DirectorySeparatorChar
      $safeProfile = $profileFull.StartsWith($safePrefix, [System.StringComparison]::OrdinalIgnoreCase) -and [System.IO.Path]::GetFileName($profileFull).StartsWith('ahmad-clean-home-urls-', [System.StringComparison]::OrdinalIgnoreCase)
      if ($safeProfile) { Remove-Item -LiteralPath $profileFull -Recurse -Force }
    } catch {}
  }
}

if ($null -ne $failure) { throw $failure }
