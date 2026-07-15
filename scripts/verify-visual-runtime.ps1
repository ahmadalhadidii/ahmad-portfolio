param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot),
  [int]$Port = 4174
)

$ErrorActionPreference = 'Stop'
$Root = [System.IO.Path]::GetFullPath($Root)
$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$BaseUrl = "http://127.0.0.1:$Port"
$Slugs = @(
  'architecture-of-elsewhere',
  'drawn-out-of-red',
  'stone-by-moonlight',
  'the-mechanics-of-becoming',
  'the-last-room-before-tomorrow'
)
$Titles = @(
  'Architecture of Elsewhere',
  'Drawn Out of Red',
  'Stone by Moonlight',
  'The Mechanics of Becoming',
  'The Last Room Before Tomorrow'
)
$Assertions = 0
$CdpId = 0
$Events = [System.Collections.ArrayList]::new()
$Ws = $null
$ChromeProcess = $null
$ServerProcess = $null
$Profile = Join-Path $env:TEMP ("ahmad-visual-runtime-" + (Get-Date -Format 'yyyyMMdd-HHmmssfff'))

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

function Evaluate([string]$Expression) {
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

function Evaluate-Json([string]$Expression) {
  $value = Evaluate $Expression
  if ($null -eq $value -or $value -eq '') { return $null }
  return ([string]$value) | ConvertFrom-Json
}

function Wait-For([string]$Expression, [string]$Message, [int]$Attempts = 160) {
  for ($attempt = 0; $attempt -lt $Attempts; $attempt++) {
    try {
      if ([bool](Evaluate $Expression)) { return }
    } catch {}
    Start-Sleep -Milliseconds 100
  }
  throw $Message
}

function Navigate([string]$Url) {
  $null = Invoke-Cdp 'Page.navigate' @{ url = $Url }
  $literal = ConvertTo-Json -InputObject $Url -Compress
  Wait-For "location.href === $literal && document.readyState !== 'loading'" "Page did not load: $Url"
}

function Reload-Page {
  $origin = Evaluate 'performance.timeOrigin'
  $literal = ConvertTo-Json -InputObject $origin -Compress
  $null = Invoke-Cdp 'Page.reload' @{ ignoreCache = $true }
  Wait-For "performance.timeOrigin !== $literal && document.readyState !== 'loading'" 'The Visual did not reload.'
}

function Set-MobileViewport {
  $null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{
    width = 390
    height = 844
    deviceScaleFactor = 1
    mobile = $true
    screenWidth = 390
    screenHeight = 844
  }
  $null = Invoke-Cdp 'Emulation.setTouchEmulationEnabled' @{ enabled = $true; maxTouchPoints = 5 }
}

function Clear-Events {
  $Events.Clear()
}

function Assert-NoBrowserErrors([string]$Label) {
  $null = Evaluate 'true'
  Start-Sleep -Milliseconds 60
  $null = Evaluate 'true'
  $requests = @{}
  $problems = [System.Collections.Generic.List[string]]::new()
  foreach ($event in @($Events)) {
    switch ($event.method) {
      'Network.requestWillBeSent' {
        $requests[[string]$event.params.requestId] = [string]$event.params.request.url
      }
      'Runtime.exceptionThrown' {
        $detail = [string]$event.params.exceptionDetails.text
        if ($event.params.exceptionDetails.exception.description) { $detail = [string]$event.params.exceptionDetails.exception.description }
        $problems.Add("runtime exception: $detail")
      }
      'Runtime.consoleAPICalled' {
        if ([string]$event.params.type -eq 'error') { $problems.Add('console.error was emitted') }
      }
      'Network.responseReceived' {
        $url = [string]$event.params.response.url
        $status = [double]$event.params.response.status
        if ($url.StartsWith($BaseUrl) -and $status -ge 400) { $problems.Add("HTTP $status $url") }
      }
      'Network.loadingFailed' {
        $url = $requests[[string]$event.params.requestId]
        $error = [string]$event.params.errorText
        if ($url -and $url.StartsWith($BaseUrl) -and -not [bool]$event.params.canceled -and $error -ne 'net::ERR_ABORTED') {
          $problems.Add("resource failed: $url ($error)")
        }
      }
    }
  }
  Assert-State ($problems.Count -eq 0) ("{0} emitted browser errors: {1}" -f $Label, ($problems -join ' | '))
}

function Assert-VisualPage([int]$Index, [string]$Context) {
  $slug = $Slugs[$Index]
  $title = $Titles[$Index]
  $previous = $Slugs[($Index - 1 + $Slugs.Count) % $Slugs.Count]
  $next = $Slugs[($Index + 1) % $Slugs.Count]
  $expectedPath = "/visuals/$slug/"
  $expectedTitle = "$title | Ahmad Alhadidii"
  Wait-For "document.body.dataset.visualSlug === '$slug' && document.querySelector('.visual-record__media img')?.complete && document.querySelector('.visual-record__media img')?.naturalWidth > 0" "$Context did not retain and load $title."
  $state = Evaluate-Json @'
JSON.stringify((() => {
  const slug = document.body.dataset.visualSlug || "";
  const visual = window.siteContent.visuals.find(item => item.slug === slug);
  const image = document.querySelector(".visual-record__media img");
  const previous = document.querySelector('a[rel="prev"]');
  const next = document.querySelector('a[rel="next"]');
  const canonical = document.querySelector('link[rel="canonical"]');
  const jsonLd = JSON.parse(document.querySelector('script[type="application/ld+json"]').textContent);
  return {
    pathname: location.pathname,
    title: document.title,
    h1: document.querySelector("main h1")?.textContent.trim() || "",
    h1Count: document.querySelectorAll("main h1").length,
    description: document.querySelector(".visual-record__description")?.textContent.trim() || "",
    dataDescription: visual?.description || "",
    image: image?.getAttribute("src") || "",
    dataImage: visual ? "/" + visual.src.replace(/^\//, "") : "",
    imageLoaded: Boolean(image?.complete && image.naturalWidth > 0 && image.naturalHeight > 0),
    imageAlt: image?.getAttribute("alt") || "",
    canonical: canonical?.href || "",
    metaDescription: document.querySelector('meta[name="description"]')?.content || "",
    ogTitle: document.querySelector('meta[property="og:title"]')?.content || "",
    ogDescription: document.querySelector('meta[property="og:description"]')?.content || "",
    ogImage: document.querySelector('meta[property="og:image"]')?.content || "",
    twitterTitle: document.querySelector('meta[name="twitter:title"]')?.content || "",
    twitterDescription: document.querySelector('meta[name="twitter:description"]')?.content || "",
    twitterImage: document.querySelector('meta[name="twitter:image"]')?.content || "",
    jsonName: jsonLd.name || "",
    jsonImage: jsonLd.image?.url || "",
    previousHref: previous?.getAttribute("href") || "",
    nextHref: next?.getAttribute("href") || "",
    allHref: document.querySelector(".visual-record__all")?.getAttribute("href") || "",
    semanticLinks: previous?.tagName === "A" && next?.tagName === "A",
    overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth
  };
})())
'@
  Assert-State ($state.pathname -eq $expectedPath -and $state.pathname -notmatch 'index\.html') "$Context exposed an incorrect URL for $title."
  Assert-State ($state.title -eq $expectedTitle -and $state.h1 -eq $title -and $state.h1Count -eq 1) "$Context exposed an incorrect title or heading for $title."
  Assert-State ($state.description -eq $state.dataDescription -and -not [string]::IsNullOrWhiteSpace([string]$state.metaDescription)) "$Context loaded an incorrect description for $title."
  Assert-State ($state.image -eq $state.dataImage -and $state.imageLoaded -and -not [string]::IsNullOrWhiteSpace([string]$state.imageAlt)) "$Context loaded an incorrect or broken image for $title."
  Assert-State ($state.canonical -eq "https://www.ahmadalhadidii.manmatic.institute$expectedPath") "$Context exposed an incorrect canonical for $title."
  Assert-State ($state.ogTitle -eq $expectedTitle -and $state.twitterTitle -eq $expectedTitle) "$Context exposed an incorrect social title for $title."
  Assert-State (-not [string]::IsNullOrWhiteSpace([string]$state.ogDescription) -and -not [string]::IsNullOrWhiteSpace([string]$state.twitterDescription) -and $state.ogImage -eq $state.twitterImage) "$Context exposed incomplete social metadata for $title."
  Assert-State ($state.jsonName -eq $title -and $state.jsonImage -eq $state.ogImage) "$Context exposed mismatched structured data for $title."
  Assert-State ($state.previousHref -eq "/visuals/$previous/" -and $state.nextHref -eq "/visuals/$next/" -and $state.allHref -eq '/#visual-studies' -and $state.semanticLinks) "$Context exposed incorrect navigation for $title."
  Assert-State ([double]$state.overflow -le 1) "$Context introduced horizontal overflow for $title."
}

$failure = $null
try {
  Assert-State (Test-Path -LiteralPath $Chrome -PathType Leaf) 'Google Chrome is unavailable for Visual runtime validation.'
  New-Item -ItemType Directory -Force -Path $Profile | Out-Null
  $serverScript = Join-Path $Root 'scripts\serve-static.ps1'
  $serverArguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Root "{1}" -Port {2}' -f $serverScript, $Root, $Port
  $ServerProcess = Start-Process -FilePath 'powershell.exe' -ArgumentList $serverArguments -PassThru -WindowStyle Hidden
  $deadline = (Get-Date).AddSeconds(10)
  do {
    try { $ready = (Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/" -TimeoutSec 1).StatusCode -eq 200 } catch { $ready = $false }
    if (-not $ready) { Start-Sleep -Milliseconds 100 }
  } until ($ready -or (Get-Date) -ge $deadline)
  Assert-State $ready 'The local Visual test server did not start.'

  $ChromeProcess = Start-Process -FilePath $Chrome -ArgumentList @(
    '--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
    '--remote-debugging-port=0', '--remote-allow-origins=*', "--user-data-dir=$Profile", 'about:blank'
  ) -PassThru -WindowStyle Hidden
  $portFile = Join-Path $Profile 'DevToolsActivePort'
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
  Set-MobileViewport

  for ($index = 0; $index -lt $Slugs.Count; $index++) {
    Clear-Events
    Navigate "$BaseUrl/#visual-studies"
    Wait-For 'document.querySelector("[data-visual-slider]")?.dataset.visualInitialized === "true"' 'The Visual slider did not initialize.'
    for ($step = 0; $step -lt $index; $step++) { $null = Evaluate 'document.querySelector("[data-visual-next]").click(); true' }
    $number = ($index + 1).ToString('00')
    Wait-For "document.querySelector('[data-visual-current]').textContent.trim() === '$number'" "Visual card $number did not become active."
    $card = Evaluate-Json @'
JSON.stringify((() => {
  const slide = document.querySelector(".visual-slide.is-active");
  const visual = window.siteContent.visuals[Number(document.querySelector("[data-visual-current]").textContent) - 1];
  const link = slide?.querySelector(".visual-slide__open");
  const image = slide?.querySelector("img");
  return {
    title: slide?.querySelector("h3")?.textContent.trim() || "",
    dataTitle: visual?.title || "",
    href: link?.getAttribute("href") || "",
    isAnchor: link?.tagName === "A",
    image: image?.getAttribute("src") || "",
    dataImage: visual?.src || ""
  };
})())
'@
    Assert-State ($card.title -eq $card.dataTitle -and $card.title -eq $Titles[$index]) "Visual card $number has the wrong title."
    Assert-State ($card.href -eq "/visuals/$($Slugs[$index])/" -and $card.isAnchor) "Visual card $number does not have its own clean anchor URL."
    Assert-State ($card.image -eq $card.dataImage) "Visual card $number has the wrong image."
    $null = Evaluate 'document.querySelector(".visual-slide.is-active .visual-slide__open").click(); true'
    Wait-For "location.pathname === '/visuals/$($Slugs[$index])/'" "Visual card $number opened the wrong Visual."
    Assert-VisualPage $index "Visual card $number"
    Assert-NoBrowserErrors "Visual card $number"

    Clear-Events
    Reload-Page
    Assert-VisualPage $index "Refresh of Visual $number"
    Assert-NoBrowserErrors "Refresh of Visual $number"

    $null = Evaluate 'document.querySelector(".visual-record__next").click(); true'
    $nextIndex = ($index + 1) % $Slugs.Count
    Wait-For "location.pathname === '/visuals/$($Slugs[$nextIndex])/'" "Next Visual from $number opened the wrong record."
    Assert-VisualPage $nextIndex "Next navigation from Visual $number"
    $null = Evaluate 'history.back(); true'
    Wait-For "location.pathname === '/visuals/$($Slugs[$index])/' && document.body.dataset.visualSlug === '$($Slugs[$index])' && document.querySelector('.visual-record__all')" "Browser Back did not restore Visual $number after next navigation."

    $null = Evaluate 'document.querySelector(".visual-record__previous").click(); true'
    $previousIndex = ($index - 1 + $Slugs.Count) % $Slugs.Count
    Wait-For "location.pathname === '/visuals/$($Slugs[$previousIndex])/'" "Previous Visual from $number opened the wrong record."
    Assert-VisualPage $previousIndex "Previous navigation from Visual $number"
    $null = Evaluate 'history.back(); true'
    Wait-For "location.pathname === '/visuals/$($Slugs[$index])/' && document.body.dataset.visualSlug === '$($Slugs[$index])' && document.querySelector('.visual-record__all')" "Browser Back did not restore Visual $number after previous navigation."

    $null = Evaluate 'document.querySelector(".visual-record__all").click(); true'
    Wait-For 'location.pathname === "/" && location.hash === "#visual-studies"' "Back to Visuals from $number did not return to the archive."
    $null = Evaluate 'history.back(); true'
    Wait-For "location.pathname === '/visuals/$($Slugs[$index])/' && document.body.dataset.visualSlug === '$($Slugs[$index])'" "Browser Back did not return from the archive to Visual $number."
  }

  Write-Output ("Visual runtime verification PASS: {0} Visuals, {1} assertions." -f $Slugs.Count, $Assertions)
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
  if (Test-Path -LiteralPath $Profile) { try { Remove-Item -LiteralPath $Profile -Recurse -Force } catch {} }
}

if ($null -ne $failure) { throw $failure }
