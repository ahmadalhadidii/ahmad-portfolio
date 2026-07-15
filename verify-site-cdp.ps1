$ErrorActionPreference = 'Stop'

$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$repoRoot = (Resolve-Path '.').Path
$outDir = Join-Path $env:TEMP 'ahmad-portfolio-contract-check'
$runId = Get-Date -Format 'yyyyMMdd-HHmmssfff'
$profile = Join-Path $outDir ("profile-$runId")
$homeUrl = ([System.Uri]::new((Resolve-Path '.\index.html').Path)).AbsoluteUri
$projectBaseUrl = ([System.Uri]::new((Resolve-Path '.\project.html').Path)).AbsoluteUri
$visualBaseUrl = ([System.Uri]::new((Resolve-Path '.\visual.html').Path)).AbsoluteUri
$process = $null
$ws = $null
$profileCreated = $false
$script:assertionCount = 0
$script:cdpId = 0
$script:cdpEvents = [System.Collections.ArrayList]::new()

function Assert-State([bool]$condition, [string]$message) {
  if (-not $condition) { throw $message }
  $script:assertionCount++
}

function Assert-SourceContract {
  $sourceFiles = @(
    '.\index.html',
    '.\project.html',
    '.\visual.html',
    '.\content.js',
    '.\site.webmanifest',
    '.\assets\css\style.css',
    '.\assets\js\main.js',
    '.\assets\js\project.js',
    '.\assets\js\visual.js',
    '.\assets\icons\ad-mark-v1-16.png',
    '.\assets\icons\ad-mark-v1-32.png',
    '.\assets\icons\ad-mark-v1-180.png',
    '.\assets\icons\ad-mark-v1-192.png',
    '.\assets\icons\ad-mark-v1-512.png'
  )
  $missing = @($sourceFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
  Assert-State ($missing.Count -eq 0) ("Missing source files: {0}" -f ($missing -join ', '))

  $sourceText = ($sourceFiles | ForEach-Object {
    Get-Content -Raw -LiteralPath $_
  }) -join [Environment]::NewLine

  $forbiddenPatterns = @(
    'portfolio:monitor-boot',
    '\bsessionStorage\b',
    '\blocalStorage\b',
    'Source\s+Serif',
    '\bArchitecture\s+student\b',
    '\bArchitectural\s+student\b',
    '\bStudent\s+architect\b',
    '\bComputational\s+Design\s+Explorer\b',
    'Bachelor\s+of\s+Architecture.{0,24}\bCandidate\b'
  )
  foreach ($pattern in $forbiddenPatterns) {
    Assert-State (-not [regex]::IsMatch($sourceText, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) ("Forbidden source text remains: {0}" -f $pattern)
  }

  foreach ($htmlPath in @('.\index.html', '.\project.html', '.\visual.html')) {
    $html = Get-Content -Raw -LiteralPath $htmlPath
    Assert-State ($html -match 'IBM\+Plex\+Sans' -and $html -match 'IBM\+Plex\+Mono') ("The two-font import is incomplete in {0}." -f $htmlPath)
    Assert-State ($html -match 'id="loader-progress"[^>]*>000<' -and $html -match 'id="loader-progress-secondary"[^>]*>000<') ("The loader does not begin at 000 in {0}." -f $htmlPath)
    Assert-State ($html -match 'rel="icon"[^>]+sizes="16x16"[^>]+ad-mark-v1-16\.png' -and $html -match 'rel="icon"[^>]+sizes="32x32"[^>]+ad-mark-v1-32\.png') ("The AD favicon links are incomplete in {0}." -f $htmlPath)
    Assert-State ($html -match 'rel="apple-touch-icon"[^>]+sizes="180x180"[^>]+ad-mark-v1-180\.png' -and $html -match 'rel="manifest"[^>]+site\.webmanifest') ("The AD touch icon or manifest link is incomplete in {0}." -f $htmlPath)
  }

  $manifest = Get-Content -Raw -LiteralPath '.\site.webmanifest'
  Assert-State ($manifest -match 'ad-mark-v1-192\.png' -and $manifest -match '"sizes"\s*:\s*"192x192"') 'The 192px AD manifest icon is missing.'
  Assert-State ($manifest -match 'ad-mark-v1-512\.png' -and $manifest -match '"sizes"\s*:\s*"512x512"') 'The 512px AD manifest icon is missing.'
  foreach ($iconPath in @('.\assets\icons\ad-mark-v1-16.png', '.\assets\icons\ad-mark-v1-32.png', '.\assets\icons\ad-mark-v1-180.png', '.\assets\icons\ad-mark-v1-192.png', '.\assets\icons\ad-mark-v1-512.png')) {
    Assert-State ((Get-Item -LiteralPath $iconPath).Length -gt 100) ("The generated AD icon is empty or invalid: {0}." -f $iconPath)
  }

  $css = Get-Content -Raw -LiteralPath '.\assets\css\style.css'
  Assert-State ($css -match '--font-sans\s*:\s*"IBM Plex Sans"' -and $css -match '--font-mono\s*:\s*"IBM Plex Mono"') 'The CSS font tokens do not resolve to IBM Plex Sans and IBM Plex Mono.'
  $fontDeclarations = [regex]::Matches($css, 'font-family\s*:\s*([^;}{]+)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  $badFontDeclarations = @($fontDeclarations | Where-Object {
    $value = $_.Groups[1].Value
    $value -notmatch 'var\(--font-(?:sans|mono)\)' -and
    $value -notmatch 'IBM Plex (?:Sans|Mono)' -and
    $value -notmatch 'inherit'
  } | ForEach-Object { $_.Value.Trim() })
  Assert-State ($badFontDeclarations.Count -eq 0) ("Unexpected font-family declarations: {0}" -f ($badFontDeclarations -join '; '))

  $index = Get-Content -Raw -LiteralPath '.\index.html'
  Assert-State ($index -match '<title>Ahmad Alhadidii — Architecture &amp; Design Portfolio</title>') 'The homepage SEO title is missing from the initial HTML.'
  Assert-State ($index -match '<meta name="robots" content="index, follow, max-image-preview:large">' -and $index -notmatch 'noindex') 'The homepage robots directive is missing or blocks indexing.'
  Assert-State ($index -match '<link rel="canonical" href="https://www\.ahmad\.manmatic\.institute/">') 'The homepage canonical URL is incorrect.'
  Assert-State ($index -notmatch 'opening__name-arabic') 'The Arabic display name should not appear in the visible homepage identity.'
  $jsonLdMatch = [regex]::Match($index, '<script type="application/ld\+json">\s*(\{.*?\})\s*</script>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
  Assert-State $jsonLdMatch.Success 'Homepage JSON-LD is missing.'
  $jsonLd = $jsonLdMatch.Groups[1].Value | ConvertFrom-Json
  Assert-State ($jsonLd.'@graph'.Count -eq 2 -and $jsonLd.'@graph'[1].mainEntity.name -eq 'Ahmad Alhadidii') 'Homepage JSON-LD graph is invalid or incomplete.'
  Assert-State (Test-Path -LiteralPath '.\robots.txt' -PathType Leaf) 'robots.txt is missing.'
  Assert-State (Test-Path -LiteralPath '.\sitemap.xml' -PathType Leaf) 'sitemap.xml is missing.'
  $robots = Get-Content -Raw -LiteralPath '.\robots.txt'
  $sitemap = Get-Content -Raw -LiteralPath '.\sitemap.xml'
  Assert-State ($robots -match 'Allow:\s*/' -and $robots -match 'https://www\.ahmad\.manmatic\.institute/sitemap\.xml') 'robots.txt is blocking crawling or references the wrong sitemap.'
  $sitemapXml = [xml]$sitemap
  Assert-State ($null -ne $sitemapXml.urlset -and [regex]::Matches($sitemap, '<url>').Count -eq 14 -and $sitemap -notmatch 'project=project-03' -and $sitemap -match 'project=manmatic-field' -and $sitemap -match 'project=protocol-port') 'The XML sitemap is invalid, incomplete, or missing the ManMaTIC child routes.'
  $projectRows = [regex]::Matches($index, 'data-project-id="([^"]+)"')
  $rowIds = @($projectRows | ForEach-Object { $_.Groups[1].Value })
  Assert-State (($rowIds -join ',') -eq 'project-05,project-01,project-02,dabouq-residential-building,project-03') 'The homepage project source records are incomplete.'
  Assert-State ([regex]::Matches($index, 'data-manmatic-system').Count -eq 1) 'The homepage must contain one ManMaTIC system boundary.'
  Assert-State ($index -match 'data-visual-slider' -and $index -match 'data-visual-prev' -and $index -match 'data-visual-next') 'The Visuals slider controls are missing from the source.'
  Assert-State ($index -notmatch 'data-visual-viewer' -and $index -notmatch 'class="visual-viewer') 'The obsolete modal visual viewer remains in the homepage source.'
  Assert-State ($index -match 'visual\.html\?visual=architecture-of-elsewhere') 'The initial Open Visual control is not a semantic routed link.'

  $mainScript = Get-Content -Raw -LiteralPath '.\assets\js\main.js'
  Assert-State ($mainScript -match 'prefers-reduced-motion' -and $mainScript -match 'data-reading-text' -and $mainScript -match 'reading-word') 'Reduced-motion or word-level reading logic is missing.'
  Assert-State ($mainScript -match 'data-showreel-slide' -and $mainScript -match 'data-visual-slider') 'Showreel or Visuals behavior is missing.'

  $visualScript = Get-Content -Raw -LiteralPath '.\assets\js\visual.js'
  Assert-State ($visualScript -match 'visual\.html\?visual=' -and $visualScript -match 'rel\s*=\s*"prev"' -and $visualScript -match 'rel\s*=\s*"next"') 'Visual route generation or semantic previous/next relations are missing.'
}

$viewports = @(
  @{ Name = '320x568'; Width = 320; Height = 568; Mobile = $true; Touch = $true },
  @{ Name = '360x640'; Width = 360; Height = 640; Mobile = $true; Touch = $true },
  @{ Name = '360x800'; Width = 360; Height = 800; Mobile = $true; Touch = $true },
  @{ Name = '375x667'; Width = 375; Height = 667; Mobile = $true; Touch = $true },
  @{ Name = '375x812'; Width = 375; Height = 812; Mobile = $true; Touch = $true },
  @{ Name = '390x844'; Width = 390; Height = 844; Mobile = $true; Touch = $true },
  @{ Name = '393x852'; Width = 393; Height = 852; Mobile = $true; Touch = $true },
  @{ Name = '412x915'; Width = 412; Height = 915; Mobile = $true; Touch = $true },
  @{ Name = '428x926'; Width = 428; Height = 926; Mobile = $true; Touch = $true },
  @{ Name = '430x932'; Width = 430; Height = 932; Mobile = $true; Touch = $true },
  @{ Name = '768x1024'; Width = 768; Height = 1024; Mobile = $true; Touch = $true },
  @{ Name = '810x1080'; Width = 810; Height = 1080; Mobile = $true; Touch = $true },
  @{ Name = '820x1180'; Width = 820; Height = 1180; Mobile = $true; Touch = $true },
  @{ Name = '1024x1366'; Width = 1024; Height = 1366; Mobile = $true; Touch = $true },
  @{ Name = '667x375'; Width = 667; Height = 375; Mobile = $true; Touch = $true },
  @{ Name = '844x390'; Width = 844; Height = 390; Mobile = $true; Touch = $true },
  @{ Name = '915x412'; Width = 915; Height = 412; Mobile = $true; Touch = $true },
  @{ Name = '1024x768'; Width = 1024; Height = 768; Mobile = $true; Touch = $true },
  @{ Name = '1366x1024'; Width = 1366; Height = 1024; Mobile = $true; Touch = $true },
  @{ Name = '1280x720'; Width = 1280; Height = 720; Mobile = $false; Touch = $false },
  @{ Name = '1280x800'; Width = 1280; Height = 800; Mobile = $false; Touch = $false },
  @{ Name = '1366x768'; Width = 1366; Height = 768; Mobile = $false; Touch = $false },
  @{ Name = '1440x900'; Width = 1440; Height = 900; Mobile = $false; Touch = $false },
  @{ Name = '1536x864'; Width = 1536; Height = 864; Mobile = $false; Touch = $false },
  @{ Name = '1920x1080'; Width = 1920; Height = 1080; Mobile = $false; Touch = $false },
  @{ Name = '2560x1440'; Width = 2560; Height = 1440; Mobile = $false; Touch = $false }
)

$desktopViewport = $viewports | Where-Object { $_.Name -eq '1440x900' } | Select-Object -First 1
$phoneViewport = $viewports | Where-Object { $_.Name -eq '390x844' } | Select-Object -First 1
$smallPhoneViewport = $viewports | Where-Object { $_.Name -eq '320x568' } | Select-Object -First 1
$expectedSlugs = @('project-05', 'project-01', 'dabouq-residential-building', 'project-02')
$expectedRowIds = @('project-05', 'project-01', 'dabouq-residential-building', 'project-02')
$expectedNumbers = @('001', '002', '003', '004')
$expectedVisualSlugs = @('architecture-of-elsewhere', 'drawn-out-of-red', 'stone-by-moonlight', 'the-mechanics-of-becoming', 'the-last-room-before-tomorrow')

function Receive-CdpMessage {
  $buffer = New-Object byte[] 65536
  $stream = [System.IO.MemoryStream]::new()
  $cancellation = [System.Threading.CancellationTokenSource]::new(20000)
  try {
    do {
      $segment = [System.ArraySegment[byte]]::new($buffer)
      $received = $ws.ReceiveAsync($segment, $cancellation.Token).GetAwaiter().GetResult()
      if ($received.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) {
        throw 'Chrome closed the DevTools connection unexpectedly.'
      }
      if ($received.Count -gt 0) { $stream.Write($buffer, 0, $received.Count) }
    } until ($received.EndOfMessage)
    return [System.Text.Encoding]::UTF8.GetString($stream.ToArray())
  }
  catch [System.OperationCanceledException] {
    throw 'Timed out waiting for a Chrome DevTools response.'
  }
  finally {
    $cancellation.Dispose()
    $stream.Dispose()
  }
}

function Invoke-Cdp([string]$method, $params = $null) {
  $script:cdpId++
  $id = $script:cdpId
  $payload = @{ id = $id; method = $method }
  if ($null -ne $params) { $payload.params = $params }
  $json = $payload | ConvertTo-Json -Depth 40 -Compress
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  $segment = [System.ArraySegment[byte]]::new($bytes)
  $null = $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()

  while ($true) {
    $message = Receive-CdpMessage
    $response = $message | ConvertFrom-Json
    $idProperty = $response.PSObject.Properties['id']
    if ($null -ne $idProperty -and [int]$response.id -eq $id) {
      if ($response.error) { throw ("CDP {0} failed: {1}" -f $method, $response.error.message) }
      return $response.result
    }
    if ($response.method) {
      $null = $script:cdpEvents.Add($response)
    }
  }
}

function Evaluate([string]$expression) {
  $result = Invoke-Cdp 'Runtime.evaluate' @{
    expression = $expression
    returnByValue = $true
    awaitPromise = $true
  }
  if ($result.exceptionDetails) {
    $description = $result.exceptionDetails.text
    if ($result.exceptionDetails.exception.description) {
      $description = $result.exceptionDetails.exception.description
    }
    throw ("Browser evaluation failed: {0}" -f $description)
  }
  return $result.result.value
}

function Evaluate-Json([string]$expression) {
  $value = Evaluate $expression
  if ($null -eq $value -or $value -eq '') { return $null }
  if ($value -is [string]) { return $value | ConvertFrom-Json }
  return $value
}

function Navigate([string]$url) {
  $urlLiteral = ConvertTo-Json -InputObject $url -Compress
  $null = Invoke-Cdp 'Page.navigate' @{ url = $url }
  for ($i = 0; $i -lt 160; $i++) {
    try {
      if ([bool](Evaluate "location.href === $urlLiteral && document.readyState !== 'loading'")) { return }
    } catch {}
    Start-Sleep -Milliseconds 100
  }
  throw "Page did not finish parsing: $url"
}

function Reload-Page {
  $previousTimeOrigin = Evaluate 'performance.timeOrigin'
  $timeOriginLiteral = ConvertTo-Json -InputObject $previousTimeOrigin -Compress
  $null = Invoke-Cdp 'Page.reload' @{ ignoreCache = $true }
  for ($i = 0; $i -lt 160; $i++) {
    try {
      if ([bool](Evaluate "performance.timeOrigin !== $timeOriginLiteral && document.readyState !== 'loading'")) { return }
    } catch {}
    Start-Sleep -Milliseconds 100
  }
  throw 'Page did not finish parsing after reload.'
}

function Wait-For([string]$expression, [string]$message, [int]$attempts = 160) {
  for ($i = 0; $i -lt $attempts; $i++) {
    try {
      if ([bool](Evaluate $expression)) { return }
    } catch {}
    Start-Sleep -Milliseconds 100
  }
  throw $message
}

function Capture-Viewport([string]$name) {
  $capture = Invoke-Cdp 'Page.captureScreenshot' @{ format = 'png'; fromSurface = $true }
  $path = Join-Path $outDir ("evidence-{0}.png" -f $name)
  [System.IO.File]::WriteAllBytes($path, [Convert]::FromBase64String([string]$capture.data))
}

function Capture-ManmaticEvidence {
  Set-Viewport $desktopViewport
  Navigate $homeUrl
  Wait-For-AppReady 'ManMaTIC screenshot pass'
  $null = Evaluate 'document.documentElement.style.scrollBehavior = "auto"; true'
  $null = Evaluate 'window.scrollTo(0, 0); true'
  Start-Sleep -Milliseconds 500
  foreach ($frame in 2..6) {
    $frameCode = $frame.ToString('00')
    $null = Evaluate "(() => { const slides = [...document.querySelectorAll('[data-showreel-slide]')]; slides.forEach(slide => { const active = slide.dataset.frame === '$frameCode'; slide.classList.toggle('is-active', active); slide.setAttribute('aria-hidden', active ? 'false' : 'true'); }); return true; })()"
    Start-Sleep -Milliseconds 180
    Capture-Viewport ("showreel-{0}-desktop" -f $frameCode)
  }
  Set-Viewport @{ Name = 'mobile-showreel-evidence'; Width = 390; Height = 844; Mobile = $true; Touch = $true }
  foreach ($frameCode in @('03', '05', '06')) {
    $null = Evaluate "(() => { const slides = [...document.querySelectorAll('[data-showreel-slide]')]; slides.forEach(slide => { const active = slide.dataset.frame === '$frameCode'; slide.classList.toggle('is-active', active); slide.setAttribute('aria-hidden', active ? 'false' : 'true'); }); return true; })()"
    Start-Sleep -Milliseconds 180
    Capture-Viewport ("showreel-{0}-mobile" -f $frameCode)
  }
  Set-Viewport $desktopViewport
  $null = Evaluate '(() => { const target = document.querySelector("[data-manmatic-system]"); window.scrollTo(0, scrollY + target.getBoundingClientRect().top - innerHeight - 40); return true; })()'
  Start-Sleep -Milliseconds 500
  Capture-Viewport '01-before-glitch-desktop'
  $null = Evaluate 'window.scrollBy(0, 180); true'
  Start-Sleep -Milliseconds 100
  Capture-Viewport '02-white-flash-desktop'
  Start-Sleep -Milliseconds 1450
  Capture-Viewport '03-symbol-desktop'
  Center-Element '.project-row--manmatic > .project-row__link'
  Start-Sleep -Milliseconds 850
  Capture-Viewport '04-introduction-desktop'
  Center-Element '.manmatic-category__record:first-child'
  Start-Sleep -Milliseconds 900
  Capture-Viewport '05-field-live-window-desktop'
  Center-Element '.manmatic-category__record:nth-child(2)'
  Capture-Viewport '06-protocol-port-desktop'
  Center-Element '.project-row[data-project-id="dabouq-residential-building"]'
  Capture-Viewport '07-next-project-desktop'
  Set-Viewport @{ Name = 'mobile-evidence'; Width = 390; Height = 844; Mobile = $true; Touch = $true }
  Center-Element '.manmatic-threshold'
  Start-Sleep -Milliseconds 1500
  Capture-Viewport '08-symbol-mobile'
  Center-Element '.manmatic-category__record:first-child'
  Start-Sleep -Milliseconds 900
  Capture-Viewport '09-field-live-window-mobile'
}

function Set-Viewport($viewport) {
  $null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{
    width = [int]$viewport.Width
    height = [int]$viewport.Height
    deviceScaleFactor = 1
    mobile = [bool]$viewport.Mobile
    screenWidth = [int]$viewport.Width
    screenHeight = [int]$viewport.Height
  }
  $null = Invoke-Cdp 'Emulation.setTouchEmulationEnabled' @{
    enabled = [bool]$viewport.Touch
    maxTouchPoints = $(if ($viewport.Touch) { 5 } else { 1 })
  }
}

function Clear-CdpEvents {
  $script:cdpEvents.Clear()
}

function Flush-CdpEvents {
  $null = Evaluate 'true'
  Start-Sleep -Milliseconds 40
  $null = Evaluate 'true'
}

function Test-LocalPageUrl([string]$url) {
  if ([string]::IsNullOrWhiteSpace($url)) { return $false }
  try {
    $uri = [System.Uri]$url
    return $uri.IsFile -or $uri.Scheme -eq 'data' -or $uri.Scheme -eq 'blob'
  } catch {
    return $false
  }
}

function Assert-No-PageErrors([string]$label) {
  Flush-CdpEvents
  $requestUrls = @{}
  $problems = [System.Collections.Generic.List[string]]::new()
  foreach ($event in @($script:cdpEvents)) {
    switch ($event.method) {
      'Network.requestWillBeSent' {
        $requestUrls[[string]$event.params.requestId] = [string]$event.params.request.url
      }
      'Runtime.exceptionThrown' {
        $details = [string]$event.params.exceptionDetails.text
        if ($event.params.exceptionDetails.exception.description) {
          $details = [string]$event.params.exceptionDetails.exception.description
        }
        $problems.Add("runtime exception: $details")
      }
      'Runtime.consoleAPICalled' {
        if ([string]$event.params.type -eq 'error') {
          $parts = @($event.params.args | ForEach-Object {
            if ($null -ne $_.value) { [string]$_.value } elseif ($_.description) { [string]$_.description } else { [string]$_.type }
          })
          $problems.Add("console.error: $($parts -join ' ')")
        }
      }
      'Log.entryAdded' {
        if ([string]$event.params.entry.level -eq 'error') {
          $entryUrl = [string]$event.params.entry.url
          $entrySource = [string]$event.params.entry.source
          if ($entrySource -ne 'network' -or (Test-LocalPageUrl $entryUrl)) {
            $problems.Add("browser log: $([string]$event.params.entry.text)")
          }
        }
      }
      'Network.loadingFailed' {
        if (-not [bool]$event.params.canceled -and [string]$event.params.errorText -ne 'net::ERR_ABORTED') {
          $url = $requestUrls[[string]$event.params.requestId]
          if (Test-LocalPageUrl $url) {
            $problems.Add("resource failed: $url ($([string]$event.params.errorText))")
          }
        }
      }
      'Network.responseReceived' {
        $status = [double]$event.params.response.status
        if ($status -ge 400 -and (Test-LocalPageUrl ([string]$event.params.response.url))) {
          $problems.Add("HTTP ${status}: $([string]$event.params.response.url)")
        }
      }
    }
  }
  Assert-State ($problems.Count -eq 0) ("{0} emitted browser errors: {1}" -f $label, ($problems -join ' | '))
}

function Install-DocumentProbe {
  $probeScript = @'
(() => {
  const state = {
    timeOrigin: performance.timeOrigin,
    loader: [],
    blackFlashCount: 0,
    windowErrors: [],
    unhandledRejections: []
  };
  Object.defineProperty(window, "__portfolioContractProbe", {
    value: state,
    configurable: false,
    enumerable: false,
    writable: false
  });

  let lastLoaderKey = "";
  let blackFlashActive = false;
  const sampleLoader = () => {
    const loader = document.getElementById("loader");
    const progress = document.getElementById("loader-progress");
    if (!loader || !progress) return;
    const value = String(progress.textContent || "").trim();
    if (!/^\d{3}$/.test(value)) return;
    const bar = document.getElementById("loader-progress-bar");
    const nextBlackFlashActive = loader.classList.contains("is-black-flash");
    if (nextBlackFlashActive && !blackFlashActive) state.blackFlashCount += 1;
    blackFlashActive = nextBlackFlashActive;
    const entry = {
      value,
      hidden: Boolean(loader.hidden),
      ariaHidden: loader.getAttribute("aria-hidden") || "",
      pending: document.documentElement.classList.contains("loader-pending"),
      bar: bar ? bar.style.transform || "" : "",
      at: Math.round(performance.now())
    };
    const key = [entry.value, entry.hidden, entry.ariaHidden, entry.pending, entry.bar].join("|");
    if (key !== lastLoaderKey) {
      state.loader.push(entry);
      lastLoaderKey = key;
    }
  };

  new MutationObserver(sampleLoader).observe(document, {
    subtree: true,
    childList: true,
    characterData: true,
    attributes: true,
    attributeFilter: ["class", "hidden", "aria-hidden", "style"]
  });
  document.addEventListener("readystatechange", sampleLoader, true);
  document.addEventListener("DOMContentLoaded", sampleLoader, true);
  window.addEventListener("load", sampleLoader, true);
  window.addEventListener("error", (event) => {
    if (event.target !== window) return;
    state.windowErrors.push(String(event.error && event.error.stack || event.message || "window error"));
  }, true);
  window.addEventListener("unhandledrejection", (event) => {
    state.unhandledRejections.push(String(event.reason && event.reason.stack || event.reason || "unhandled rejection"));
  });
})();
'@
  $null = Invoke-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{ source = $probeScript }
}

function Wait-For-AppReady([string]$label) {
  $expression = @'
(() => {
  const loader = document.getElementById("loader");
  return document.documentElement.classList.contains("loader-complete") &&
    document.documentElement.classList.contains("motion-ready") &&
    loader && loader.hidden && loader.getAttribute("aria-hidden") === "true";
})()
'@
  Wait-For $expression ("{0} did not leave the loader and become motion-ready." -f $label) 180
}

function Assert-LoaderCycle([string]$label, [int]$minimumDistinctSamples = 5) {
  Wait-For 'window.__portfolioContractProbe && window.__portfolioContractProbe.loader.length > 0' ("{0} did not expose loader samples." -f $label) 40
  Wait-For-AppReady $label
  $probe = Evaluate-Json 'JSON.stringify(window.__portfolioContractProbe)'
  $samples = @($probe.loader)
  Assert-State ($samples.Count -ge $minimumDistinctSamples) ("{0} produced too few loader samples ({1})." -f $label, $samples.Count)
  Assert-State ([string]$samples[0].value -eq '000') ("{0} did not begin at 000; first sample was {1}." -f $label, $samples[0].value)

  $numericValues = @($samples | ForEach-Object { [int]$_.value })
  $distinctValues = @($numericValues | Select-Object -Unique)
  Assert-State ($distinctValues.Count -ge $minimumDistinctSamples) ("{0} did not visibly stage loader progress." -f $label)
  Assert-State ($numericValues -contains 100) ("{0} never reached 100." -f $label)
  Assert-State (@($numericValues | Where-Object { $_ -gt 0 -and $_ -lt 100 }).Count -gt 0) ("{0} jumped directly from 000 to 100." -f $label)

  for ($index = 1; $index -lt $numericValues.Count; $index++) {
    Assert-State ($numericValues[$index] -ge $numericValues[$index - 1]) ("{0} loader progress moved backward at sample {1}." -f $label, $index)
  }

  $zeroVisible = @($samples | Where-Object { [string]$_.value -eq '000' -and -not [bool]$_.hidden -and [string]$_.ariaHidden -ne 'true' })
  $hundredVisible = @($samples | Where-Object { [string]$_.value -eq '100' -and -not [bool]$_.hidden })
  Assert-State ($zeroVisible.Count -gt 0) ("{0} did not visibly present 000." -f $label)
  Assert-State ($hundredVisible.Count -gt 0) ("{0} hid the loader before visibly presenting 100." -f $label)
  Assert-State (@($samples | Where-Object { [string]$_.value -eq '100' -and [string]$_.bar -match 'scaleX\(1(?:\.0+)?\)' }).Count -gt 0) ("{0} progress line did not reach 100%." -f $label)
  Assert-State (@($probe.windowErrors).Count -eq 0 -and @($probe.unhandledRejections).Count -eq 0) ("{0} recorded an uncaught window error or rejection." -f $label)

  $finalState = Evaluate-Json @'
JSON.stringify({
  progress: document.getElementById("loader-progress").textContent.trim(),
  secondary: document.getElementById("loader-progress-secondary").textContent.trim(),
  state: document.getElementById("loader-state").textContent.trim(),
  phase: document.getElementById("loader-phase").textContent.trim(),
  hidden: document.getElementById("loader").hidden,
  pending: document.documentElement.classList.contains("loader-pending"),
  complete: document.documentElement.classList.contains("loader-complete")
})
'@
  Assert-State ($finalState.progress -eq '100' -and $finalState.secondary -eq '100') ("{0} final counters are not 100." -f $label)
  Assert-State ($finalState.state -eq 'FIELD ACTIVE' -and $finalState.phase -eq 'SYSTEM READY') ("{0} did not reach its final ready labels." -f $label)
  Assert-State ($finalState.hidden -and -not $finalState.pending -and $finalState.complete) ("{0} did not settle into the complete state." -f $label)
  return $probe
}

function Center-Element([string]$selector) {
  $selectorLiteral = ConvertTo-Json -InputObject $selector -Compress
  $scrollExpression = @"
(() => {
  const target = document.querySelector($selectorLiteral);
  if (!target) return false;
  document.documentElement.style.scrollBehavior = "auto";
  target.scrollIntoView({ block: "center", inline: "nearest", behavior: "auto" });
  return true;
})()
"@
  $found = [bool](Evaluate $scrollExpression)
  Assert-State $found ("Could not find scroll target: {0}." -f $selector)
  $centeredExpression = @"
(() => {
  const target = document.querySelector($selectorLiteral);
  if (!target) return false;
  const bounds = target.getBoundingClientRect();
  return bounds.bottom > innerHeight * 0.2 && bounds.top < innerHeight * 0.8;
})()
"@
  Wait-For $centeredExpression ("Could not center scroll target: {0}." -f $selector) 40
}

function Place-Element([string]$selector, [double]$viewportFraction) {
  $selectorLiteral = ConvertTo-Json -InputObject $selector -Compress
  $fractionLiteral = $viewportFraction.ToString([System.Globalization.CultureInfo]::InvariantCulture)
  $scrollExpression = @"
(() => {
  const target = document.querySelector($selectorLiteral);
  if (!target) return false;
  document.documentElement.style.scrollBehavior = "auto";
  const documentTop = target.getBoundingClientRect().top + scrollY;
  scrollTo({ top: Math.max(0, documentTop - innerHeight * $fractionLiteral), behavior: "auto" });
  return true;
})()
"@
  $found = [bool](Evaluate $scrollExpression)
  Assert-State $found ("Could not find positioned scroll target: {0}." -f $selector)
  $positionedExpression = @"
(() => {
  const target = document.querySelector($selectorLiteral);
  if (!target) return false;
  return Math.abs(target.getBoundingClientRect().top - innerHeight * $fractionLiteral) < 8;
})()
"@
  Wait-For $positionedExpression ("Scroll position did not settle for {0}." -f $selector) 50
  Start-Sleep -Milliseconds 80
}

function Assert-HomeStructure {
  $expression = @'
JSON.stringify((() => {
  const rows = Array.from(document.querySelectorAll(".project-row[data-project-id]:not([hidden])"));
  const projects = window.siteContent && Array.isArray(window.siteContent.projects)
    ? window.siteContent.projects.filter(project => project.featured !== false).sort((a, b) => (a.displayOrder || 999) - (b.displayOrder || 999))
    : [];
  const studies = window.siteContent && Array.isArray(window.siteContent.visuals)
    ? window.siteContent.visuals
    : [];
  const ids = Array.from(document.querySelectorAll("[id]"), node => node.id);
  const internalLinks = Array.from(document.querySelectorAll('a[href^="#"]'));
  const externalLinks = Array.from(document.querySelectorAll('a[target="_blank"]'));
  const restoredRecords = Array.from(document.querySelectorAll(
    ".profile__layout, .profile__meta, .cv__identity, .cv-group, .support-group, .contact__intro, .contact__band"
  ));
  return {
    home: document.body.classList.contains("home-page"),
    h1Count: document.querySelectorAll("main h1").length,
    rowIds: rows.map(row => row.dataset.projectId || ""),
    rowNumbers: rows.map(row => (row.querySelector(".project-row__number")?.textContent || "").trim()),
    rowHrefs: rows.map(row => row.querySelector(".project-row__link")?.getAttribute("href") || ""),
    rowImages: rows.map(row => Boolean(row.querySelector(".project-row__media img, .project-row__media-status"))),
    dataIds: projects.map(project => project.slug || project.id || ""),
    dataNumbers: projects.map(project => String(project.number || "")),
    duplicateIds: ids.filter((id, index) => ids.indexOf(id) !== index),
    brokenInternalLinks: internalLinks.filter(link => {
      const href = link.getAttribute("href");
      return href !== "#" && !document.querySelector(href);
    }).map(link => link.getAttribute("href")),
    emptyLinks: Array.from(document.querySelectorAll("a")).filter(link =>
      !(link.textContent || "").trim() && !link.getAttribute("aria-label")
    ).length,
    unsafeExternalLinks: externalLinks.filter(link => {
      const rel = (link.getAttribute("rel") || "").toLowerCase().split(/\s+/);
      return !rel.includes("noopener") || !rel.includes("noreferrer");
    }).length,
    showreelSlides: document.querySelectorAll("[data-showreel-slide]").length,
    showreelActive: document.querySelectorAll("[data-showreel-slide].is-active").length,
    sliderDataCount: studies.length,
    loaderBinaryRemoved: !document.querySelector(".loader__binary"),
    restoredRecordCount: restoredRecords.length,
    visibleRestoredRecords: restoredRecords.filter(record => {
      const style = getComputedStyle(record);
      return Number(style.opacity) > 0.9 && style.visibility !== "hidden" &&
        !String(style.clipPath).includes("100%") && record.getBoundingClientRect().height > 0;
    }).length,
    profileMetaCount: document.querySelectorAll(".profile__meta > div").length,
    cvGroupCount: document.querySelectorAll(".cv-group, .support-group").length,
    contactLinkCount: document.querySelectorAll(".contact__links a").length
  };
})())
'@
  $state = Evaluate-Json $expression
  Assert-State $state.home 'The homepage body contract is missing.'
  Assert-State ($state.h1Count -eq 1) 'The homepage must have one main h1.'
  Assert-State ((@($state.rowIds) -join ',') -eq ($expectedRowIds -join ',')) 'Homepage project IDs are out of archive order.'
  Assert-State ((@($state.rowNumbers) -join ',') -eq ($expectedNumbers -join ',')) 'Homepage project numbers are out of archive order.'
  $expectedHrefs = @($expectedSlugs | ForEach-Object { "project.html?project=$_" })
  Assert-State ((@($state.rowHrefs) -join ',') -eq ($expectedHrefs -join ',')) 'Homepage project routes do not match the archive.'
  Assert-State ((@($state.dataIds) -join ',') -eq ($expectedSlugs -join ',') -and (@($state.dataNumbers) -join ',') -eq ($expectedNumbers -join ',')) 'Central project data does not match homepage order and numbering.'
  Assert-State ((@($state.rowImages | Where-Object { -not $_ })).Count -eq 1) 'The text-only ManMaTIC introduction is not the only homepage project without a cover image.'
  Assert-State (@($state.duplicateIds).Count -eq 0 -and $state.emptyLinks -eq 0 -and @($state.brokenInternalLinks).Count -eq 0) 'The homepage contains duplicate IDs, empty links, or broken internal fragments.'
  Assert-State ($state.unsafeExternalLinks -eq 0) 'A new-tab external link is missing noopener/noreferrer.'
  Assert-State ($state.showreelSlides -ge 5 -and $state.showreelActive -eq 1) 'The homepage showreel frame structure is incomplete.'
  Assert-State ($state.sliderDataCount -ge 5) 'Visuals must contain at least five data entries.'
  Assert-State $state.loaderBinaryRemoved 'Loader binary elements were not removed after completion.'
  Assert-State ($state.restoredRecordCount -ge 10 -and $state.visibleRestoredRecords -eq $state.restoredRecordCount) 'Profile, CV, or Contact content is still visually clipped or hidden.'
  Assert-State ($state.profileMetaCount -eq 6 -and $state.cvGroupCount -ge 8 -and $state.contactLinkCount -eq 5) 'Profile, CV, or Contact content is incomplete.'
}

function Assert-ProjectImages {
  foreach ($slug in $expectedSlugs) {
    $selector = ".project-row[data-project-id='$slug']"
    Center-Element $selector
    if ($slug -eq 'project-01') { continue }
    $selectorLiteral = ConvertTo-Json -InputObject $selector -Compress
    $readyExpression = @"
(() => {
  const row = document.querySelector($selectorLiteral);
  const figure = row && row.querySelector(".project-row__media");
  const image = figure && figure.querySelector("img");
  if (!row || !figure || !image) return false;
  const bounds = image.getBoundingClientRect();
  const style = getComputedStyle(image);
  return image.complete && image.naturalWidth > 0 && image.naturalHeight > 0 &&
    bounds.width > 40 && bounds.height > 24 && style.display !== "none" &&
    style.visibility !== "hidden" && Number(style.opacity) > 0.5 &&
    figure.classList.contains("is-visible") &&
    !figure.classList.contains("is-media-missing");
})()
"@
    Wait-For $readyExpression ("Project cover did not become visibly available: {0}." -f $slug) 120
    $imageState = Evaluate-Json @"
JSON.stringify((() => {
  const row = document.querySelector($selectorLiteral);
  const figure = row.querySelector(".project-row__media");
  const image = figure.querySelector("img");
  return {
    local: !/^https?:/i.test(image.getAttribute("src") || ""),
    alt: image.getAttribute("alt") || "",
    revealed: figure.classList.contains("is-visible"),
    width: image.getBoundingClientRect().width,
    height: image.getBoundingClientRect().height
  };
})())
"@
    Assert-State $imageState.local ("Project cover uses a remote source: {0}." -f $slug)
    Assert-State (-not [string]::IsNullOrWhiteSpace([string]$imageState.alt)) ("Project cover lacks alt text: {0}." -f $slug)
    Assert-State ($imageState.revealed -and $imageState.width -gt 40 -and $imageState.height -gt 24) ("Project cover reveal did not complete: {0}." -f $slug)
  }
}

function Assert-ShowreelChanges {
  Center-Element '[data-broadcast-monitor]'
  Wait-For 'document.querySelector("[data-showreel-fallback]")?.dataset.showreelInitialized === "true"' 'The showreel did not initialize.' 60
  $initialFrame = [string](Evaluate 'document.querySelector("[data-showreel-fallback]").dataset.activeFrame || document.getElementById("showreel-frame").textContent.trim()')
  $initialFrameLiteral = ConvertTo-Json -InputObject $initialFrame -Compress
  $changeExpression = @"
(() => {
  const reel = document.querySelector("[data-showreel-fallback]");
  const frame = reel && (reel.dataset.activeFrame || document.getElementById("showreel-frame")?.textContent.trim());
  return reel && reel.dataset.playing === "true" && frame && frame !== $initialFrameLiteral;
})()
"@
  Wait-For $changeExpression 'The opening showreel remained on one frame.' 70
  $changedState = Evaluate-Json @'
JSON.stringify((() => {
  const reel = document.querySelector("[data-showreel-fallback]");
  const slides = Array.from(reel.querySelectorAll("[data-showreel-slide]"));
  const active = slides.filter(slide => slide.classList.contains("is-active"));
  return {
    frame: reel.dataset.activeFrame || "",
    playing: reel.dataset.playing || "",
    active: active.length,
    ariaVisible: slides.filter(slide => slide.getAttribute("aria-hidden") === "false").length,
    status: document.getElementById("showreel-status")?.textContent.trim() || "",
    togglePressed: document.getElementById("showreel-toggle")?.getAttribute("aria-pressed") || ""
  };
})())
'@
  Assert-State ($changedState.frame -ne $initialFrame -and $changedState.playing -eq 'true') 'The showreel frame/readout did not advance.'
  Assert-State ($changedState.active -eq 1 -and $changedState.ariaVisible -eq 1) 'The showreel does not expose exactly one active frame.'
  Assert-State ($changedState.status -match '^PLAYING' -and $changedState.togglePressed -eq 'false') 'Showreel playing controls are inconsistent.'

  $null = Evaluate 'document.getElementById("showreel-toggle").click(); true'
  Wait-For 'document.querySelector("[data-showreel-fallback]").dataset.playing === "false" && document.getElementById("showreel-toggle").getAttribute("aria-pressed") === "true"' 'The showreel pause control failed.' 30
  $null = Evaluate 'document.getElementById("showreel-toggle").click(); true'
  Wait-For 'document.querySelector("[data-showreel-fallback]").dataset.playing === "true" && document.getElementById("showreel-toggle").getAttribute("aria-pressed") === "false"' 'The showreel play control failed.' 30
}

function Assert-VisualSlider {
  Center-Element '[data-visual-slider]'
  Wait-For 'document.querySelector("[data-visual-slider]")?.dataset.visualInitialized === "true"' 'The Visuals slider did not initialize.' 60
  $state = Evaluate-Json @'
JSON.stringify((() => {
  const slider = document.querySelector("[data-visual-slider]");
  const slides = Array.from(slider.querySelectorAll(".visual-slide"));
  const previous = slider.querySelector("[data-visual-prev]");
  const next = slider.querySelector("[data-visual-next]");
  const size = button => {
    const bounds = button.getBoundingClientRect();
    return { width: bounds.width, height: bounds.height };
  };
  return {
    dataCount: window.siteContent.visuals.length,
    slideCount: slides.length,
    current: slider.querySelector("[data-visual-current]")?.textContent.trim() || "",
    total: slider.querySelector("[data-visual-total]")?.textContent.trim() || "",
    active: slides.filter(slide => slide.classList.contains("is-active")).length,
    ariaVisible: slides.filter(slide => slide.getAttribute("aria-hidden") === "false").length,
    localImages: slides.every(slide => !/^https?:/i.test(slide.querySelector("img")?.getAttribute("src") || "")),
    altImages: slides.every(slide => Boolean((slide.querySelector("img")?.getAttribute("alt") || "").trim())),
    openLinks: slides.map(slide => {
      const control = slide.querySelector(".visual-slide__open");
      return {
        semantic: control?.tagName === "A",
        href: control?.getAttribute("href") || "",
        text: control?.textContent.trim() || ""
      };
    }),
    previous: size(previous),
    next: size(next),
    tabindex: slider.getAttribute("tabindex") || ""
  };
})())
'@
  Assert-State ($state.dataCount -ge 5 -and $state.slideCount -eq $state.dataCount) 'Visuals slide count does not match its data array or is below five.'
  Assert-State ($state.current -eq '01' -and [int]$state.total -eq $state.dataCount) 'Visuals initial current/total values are incorrect.'
  Assert-State ($state.active -eq 1 -and $state.ariaVisible -eq 1) 'Visuals does not expose exactly one active slide.'
  Assert-State ($state.localImages -and $state.altImages) 'Visuals requires local images with alt text.'
  $expectedVisualHrefs = @($expectedVisualSlugs | ForEach-Object { "visual.html?visual=$_" })
  Assert-State (-not (@($state.openLinks.semantic) -contains $false) -and (@($state.openLinks.href) -join ',') -eq ($expectedVisualHrefs -join ',')) 'Open Visual controls are not semantic links to the shared visual routes.'
  Assert-State (-not (@($state.openLinks.text) | Where-Object { [string]::IsNullOrWhiteSpace([string]$_) })) 'An Open Visual link has no readable label.'
  Assert-State ($state.previous.width -ge 44 -and $state.previous.height -ge 44 -and $state.next.width -ge 44 -and $state.next.height -ge 44) 'Visuals controls are smaller than 44 by 44 pixels.'
  Assert-State ($state.tabindex -eq '0') 'Visuals is not keyboard focusable.'

  $null = Evaluate 'document.querySelector("[data-visual-next]").click(); true'
  Wait-For 'document.querySelector("[data-visual-current]").textContent.trim() === "02"' 'Visuals next control failed.' 30
  $null = Evaluate 'document.querySelector("[data-visual-prev]").click(); true'
  Wait-For 'document.querySelector("[data-visual-current]").textContent.trim() === "01"' 'Visuals previous control failed.' 30
  $lastValue = ([int]$state.dataCount).ToString('00')
  $lastValueLiteral = ConvertTo-Json -InputObject $lastValue -Compress
  $null = Evaluate 'document.querySelector("[data-visual-slider]").dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowLeft", bubbles: true, cancelable: true })); true'
  Wait-For "document.querySelector('[data-visual-current]').textContent.trim() === $lastValueLiteral" 'Visuals ArrowLeft wrapping failed.' 30
  $null = Evaluate 'document.querySelector("[data-visual-slider]").dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowRight", bubbles: true, cancelable: true })); true'
  Wait-For 'document.querySelector("[data-visual-current]").textContent.trim() === "01"' 'Visuals ArrowRight wrapping failed.' 30
}

function Assert-VisualRoute([string]$slug, [string]$previousSlug, [string]$nextSlug) {
  Wait-For "document.body.dataset.visualSlug === '$slug' && document.querySelectorAll('.visual-record').length === 1" ("Visual route did not render: {0}." -f $slug) 80
  Wait-For-AppReady ("visual route {0}" -f $slug)
  Wait-For 'document.querySelector(".visual-record__media img")?.complete && document.querySelector(".visual-record__media img").naturalWidth > 0' ("Visual image did not load: {0}." -f $slug) 100

  $state = Evaluate-Json @'
JSON.stringify((() => {
  const slug = document.body.dataset.visualSlug || "";
  const visual = window.siteContent.visuals.find(item => item.slug === slug);
  const record = document.querySelector(".visual-record");
  const metadata = record?.querySelector(".visual-record__meta");
  const title = record?.querySelector("h1");
  const figure = record?.querySelector(".visual-record__media");
  const frame = figure?.querySelector(".visual-record__image-frame");
  const image = figure?.querySelector("img");
  const caption = figure?.querySelector("figcaption");
  const description = record?.querySelector(".visual-record__description");
  const navigation = record?.querySelector(".visual-record__navigation");
  const previous = navigation?.querySelector('a[rel="prev"]');
  const next = navigation?.querySelector('a[rel="next"]');
  const loader = document.getElementById("loader");
  const orderedNodes = [metadata, title, image, caption, description, navigation];
  const values = color => (color.match(/[\d.]+/g) || []).map(Number);
  const luminance = color => {
    const rgb = values(color);
    const scale = /^color\(srgb/i.test(color) ? 255 : 1;
    return rgb.length >= 3 ? (rgb[0] * 0.2126 + rgb[1] * 0.7152 + rgb[2] * 0.0722) * scale : -1;
  };
  return {
    slug,
    dataSlug: visual?.slug || "",
    dataTitle: visual?.title || "",
    dataImage: visual?.src || "",
    dataCaption: visual?.caption || "",
    dataDescription: visual?.description || "",
    dataEmphasis: visual?.emphasis || "",
    dataOrientation: visual?.orientation || "",
    h1Count: document.querySelectorAll("main h1").length,
    title: title?.textContent.trim() || "",
    metadataRows: metadata?.querySelectorAll("div").length || 0,
    description: description?.textContent.trim() || "",
    strongText: description?.querySelector("strong")?.textContent.trim() || "",
    caption: caption?.textContent.trim() || "",
    captionAttached: caption?.parentElement === figure,
    source: image?.getAttribute("src") || "",
    local: image ? !/^https?:/i.test(image.getAttribute("src") || "") : false,
    alt: image?.getAttribute("alt") || "",
    loaded: Boolean(image?.complete && image.naturalWidth > 0 && image.naturalHeight > 0),
    visible: image ? image.getBoundingClientRect().width > 40 && image.getBoundingClientRect().height > 24 : false,
    objectFit: image ? getComputedStyle(image).objectFit : "",
    opacity: image ? Number.parseFloat(getComputedStyle(image).opacity) : 0,
    visibility: image ? getComputedStyle(image).visibility : "",
    display: image ? getComputedStyle(image).display : "",
    mediaMissing: Boolean(figure?.classList.contains("is-media-missing")),
    frameRatioError: frame && image?.naturalWidth && image?.naturalHeight
      ? Math.abs((frame.getBoundingClientRect().width / frame.getBoundingClientRect().height) - (image.naturalWidth / image.naturalHeight))
      : 1,
    orientation: figure?.dataset.orientation || "",
    semanticOrder: orderedNodes.every(Boolean) && orderedNodes.slice(1).every((node, index) =>
      Boolean(orderedNodes[index].compareDocumentPosition(node) & Node.DOCUMENT_POSITION_FOLLOWING)
    ),
    previousHref: previous?.getAttribute("href") || "",
    nextHref: next?.getAttribute("href") || "",
    previousText: previous?.textContent.trim() || "",
    nextText: next?.textContent.trim() || "",
    loaderProject: Boolean(loader?.classList.contains("loader--project")),
    loaderVisual: Boolean(loader?.classList.contains("loader--visual")),
    loaderDark: Boolean(loader?.classList.contains("loader--project-dark")),
    loaderLight: loader ? luminance(getComputedStyle(loader).backgroundColor) : -1,
    rootScrollWidth: document.documentElement.scrollWidth,
    clientWidth: document.documentElement.clientWidth
  };
})())
'@
  Assert-State ($state.slug -eq $slug -and $state.dataSlug -eq $slug -and $state.h1Count -eq 1 -and $state.title -eq $state.dataTitle) ("Visual route identity does not match central data: {0}." -f $slug)
  Assert-State ($state.metadataRows -ge 3 -and $state.semanticOrder -and -not [string]::IsNullOrWhiteSpace([string]$state.description) -and $state.description -eq $state.dataDescription -and $state.strongText -eq $state.dataEmphasis) ("Visual metadata, bold emphasis, description, or semantic reading order is incomplete: {0}." -f $slug)
  Assert-State ($state.loaded -and $state.visible -and $state.local -and -not [string]::IsNullOrWhiteSpace([string]$state.alt) -and $state.source -eq $state.dataImage) ("Visual image is remote, unloaded, invisible, or does not match central data: {0}." -f $slug)
  Assert-State (-not $state.mediaMissing -and $state.opacity -gt 0.98 -and $state.visibility -eq 'visible' -and $state.display -ne 'none') ("Visual image is not visibly painted: {0}." -f $slug)
  Assert-State ($state.objectFit -eq 'contain' -and $state.orientation -eq $state.dataOrientation -and $state.frameRatioError -lt 0.01) ("Visual image is cropped, stretched, ratio-clamped, or missing its orientation class: {0}." -f $slug)
  Assert-State ($state.captionAttached -and $state.caption -eq $state.dataCaption) ("Visual caption is detached or does not match central data: {0}." -f $slug)
  Assert-State ($state.previousHref -eq ("visual.html?visual={0}" -f $previousSlug) -and $state.nextHref -eq ("visual.html?visual={0}" -f $nextSlug) -and -not [string]::IsNullOrWhiteSpace([string]$state.previousText) -and -not [string]::IsNullOrWhiteSpace([string]$state.nextText)) ("Visual previous/next route links are invalid: {0}." -f $slug)
  Assert-State ($state.loaderProject -and $state.loaderVisual -and -not $state.loaderDark -and $state.loaderLight -gt 235) ("Visual route loader is not using the light opening system: {0}." -f $slug)
  Assert-State ($state.rootScrollWidth -le ($state.clientWidth + 1)) ("Visual route has horizontal overflow: {0}." -f $slug)

  Set-Viewport $phoneViewport
  Wait-For 'innerWidth === 390 && innerHeight === 844' ("Visual mobile viewport did not settle: {0}." -f $slug) 40
  $mobile = Evaluate-Json @'
JSON.stringify((() => {
  const record = document.querySelector(".visual-record");
  const nodes = [
    record?.querySelector(".visual-record__meta"),
    record?.querySelector("h1"),
    record?.querySelector(".visual-record__media img"),
    record?.querySelector(".visual-record__media figcaption"),
    record?.querySelector(".visual-record__description"),
    record?.querySelector(".visual-record__navigation")
  ];
  const rects = nodes.map(node => node?.getBoundingClientRect());
  const links = Array.from(record?.querySelectorAll(".visual-record__navigation a") || []);
  return {
    complete: nodes.every(Boolean),
    ordered: rects.slice(1).every((rect, index) => rect.top >= rects[index].bottom - 2),
    linksLarge: links.every(link => {
      const rect = link.getBoundingClientRect();
      return rect.width >= 44 && rect.height >= 44;
    }),
    scrollWidth: document.documentElement.scrollWidth,
    clientWidth: document.documentElement.clientWidth
  };
})())
'@
  Assert-State ($mobile.complete -and $mobile.ordered) ("Visual mobile reading order is not metadata, title, image, caption, description, navigation: {0}." -f $slug)
  Assert-State ($mobile.linksLarge -and $mobile.scrollWidth -le ($mobile.clientWidth + 1)) ("Visual mobile navigation targets are too small or the layout overflows: {0}." -f $slug)
  Set-Viewport $desktopViewport
}

function Assert-VisualRoutes {
  for ($index = 0; $index -lt $expectedVisualSlugs.Count; $index++) {
    Set-Viewport $desktopViewport
    $slug = $expectedVisualSlugs[$index]
    $previousSlug = $expectedVisualSlugs[($index - 1 + $expectedVisualSlugs.Count) % $expectedVisualSlugs.Count]
    $nextSlug = $expectedVisualSlugs[($index + 1) % $expectedVisualSlugs.Count]
    Clear-CdpEvents
    Navigate ($visualBaseUrl + "?visual=$slug")
    Assert-VisualRoute $slug $previousSlug $nextSlug
    Assert-No-PageErrors ("visual route {0}" -f $slug)
  }

  Clear-CdpEvents
  Navigate ($visualBaseUrl + '?visual=missing')
  Wait-For 'document.querySelectorAll(".visual-detail__error").length === 1' 'The invalid visual route did not render its error state.' 80
  Wait-For-AppReady 'invalid visual route'
  $invalid = Evaluate-Json 'JSON.stringify({ heading: document.querySelector(".visual-detail__error h1")?.textContent.trim() || "", returnHref: document.querySelector(".visual-detail__error a")?.getAttribute("href") || "", h1Count: document.querySelectorAll("main h1").length, darkLoader: document.getElementById("loader")?.classList.contains("loader--project-dark") })'
  Assert-State ($invalid.heading -eq 'VISUAL NOT FOUND' -and $invalid.returnHref -eq 'index.html#visual-studies' -and $invalid.h1Count -eq 1 -and -not $invalid.darkLoader) 'The invalid visual route is not a complete light accessible fallback.'
  Assert-No-PageErrors 'invalid visual route'
}

function Get-ReadingSnapshot([string]$selector = '[data-reading-text]') {
  $selectorLiteral = ConvertTo-Json -InputObject $selector -Compress
  $expression = @"
JSON.stringify((() => {
  const element = document.querySelector($selectorLiteral);
  const words = element ? Array.from(element.querySelectorAll(".reading-word")) : [];
  const values = words.map(word => {
    const inline = parseFloat(word.style.getPropertyValue("--reading-progress"));
    const computed = parseFloat(getComputedStyle(word).getPropertyValue("--reading-progress"));
    return Number.isFinite(inline) ? inline : Number.isFinite(computed) ? computed : 0;
  });
  const colors = words.map(word => getComputedStyle(word).color);
  const allVisible = words.every(word => {
    const bounds = word.getBoundingClientRect();
    const style = getComputedStyle(word);
    return bounds.width > 0 && bounds.height > 0 && style.display !== "none" &&
      style.visibility !== "hidden" && Number(style.opacity) > 0.9;
  });
  const average = values.length ? values.reduce((sum, value) => sum + value, 0) / values.length : 0;
  const quarter = Math.max(1, Math.floor(values.length / 4));
  const mean = list => list.length ? list.reduce((sum, value) => sum + value, 0) / list.length : 0;
  return {
    prepared: element?.dataset.readingPrepared || "",
    count: words.length,
    values,
    colors,
    average,
    minimum: values.length ? Math.min(...values) : 0,
    maximum: values.length ? Math.max(...values) : 0,
    upcoming: values.filter(value => value <= 0.2).length,
    current: values.filter(value => value > 0.2 && value < 0.82).length,
    completed: values.filter(value => value >= 0.82).length,
    firstQuarter: mean(values.slice(0, quarter)),
    lastQuarter: mean(values.slice(-quarter)),
    distinctColors: new Set(colors).size,
    allVisible
  };
})())
"@
  return Evaluate-Json $expression
}

function Set-ReadingProgress([double]$progress) {
  $progressLiteral = $progress.ToString([System.Globalization.CultureInfo]::InvariantCulture)
  $expression = @"
(() => {
  const stage = document.querySelector('[data-reading-stage]');
  if (!stage) return false;
  document.documentElement.style.scrollBehavior = 'auto';
  const viewportHeight = Math.max(innerHeight, 1);
  const bounds = stage.getBoundingClientRect();
  const documentTop = bounds.top + scrollY;
  const distance = Math.max(bounds.height - viewportHeight * 0.2, viewportHeight * 0.75);
  scrollTo({
    top: Math.max(0, documentTop - viewportHeight * 0.58 + distance * $progressLiteral),
    behavior: 'auto'
  });
  return true;
})()
"@
  Assert-State ([bool](Evaluate $expression)) 'The manifesto reading stage is missing.'
  $waitExpression = "Math.abs(parseFloat(document.querySelector('.manifesto__text').style.getPropertyValue('--reading-section-progress')) - $progressLiteral) < 0.04"
  Wait-For $waitExpression 'The manifesto reading progress did not settle at the requested position.' 50
  Start-Sleep -Milliseconds 80
}

function Assert-ReadingProgression {
  $selector = '.manifesto__text[data-reading-text]'
  Wait-For 'document.querySelectorAll(".manifesto__text .reading-word").length >= 20' 'The manifesto was not prepared into word-level reading spans.' 50
  $structure = Evaluate-Json @'
JSON.stringify((() => {
  const text = document.querySelector(".manifesto__text");
  const stage = document.querySelector("[data-reading-stage]");
  return {
    visualCopies: text?.querySelectorAll(".reading-visual").length || 0,
    hiddenCopies: text?.querySelectorAll(".visually-hidden").length || 0,
    accessibleLabel: text?.getAttribute("aria-label") || "",
    stageRatio: stage ? stage.getBoundingClientRect().height / innerHeight : 0,
    viewport: `${innerWidth}x${innerHeight}`,
    stageMinHeight: stage ? getComputedStyle(stage).minHeight : "",
    narrowMedia: matchMedia("(max-width: 700px)").matches
  };
})())
'@
  Assert-State ($structure.visualCopies -eq 1 -and $structure.hiddenCopies -eq 0 -and -not [string]::IsNullOrWhiteSpace([string]$structure.accessibleLabel)) 'The Architecture of Elsewhere statement is duplicated or lacks one accessible label.'
  $stageRatioValid = if ($structure.narrowMedia) {
    $structure.stageRatio -ge 0.45 -and $structure.stageRatio -le 1.2
  } else {
    $structure.stageRatio -ge 0.6 -and $structure.stageRatio -le 1.15
  }
  Assert-State $stageRatioValid ("The Architecture of Elsewhere reading stage is outside its controlled duration: ratio={0} viewport={1} min={2} narrow={3}." -f $structure.stageRatio, $structure.viewport, $structure.stageMinHeight, $structure.narrowMedia)

  Set-ReadingProgress 0.02
  $early = Get-ReadingSnapshot $selector
  Assert-State ($early.prepared -eq 'true' -and $early.count -ge 20) 'The manifesto word-level reading contract is incomplete.'
  Assert-State ($early.allVisible -and $early.average -lt 0.3) 'Upcoming manifesto words are not visibly pale before the reading line.'

  Set-ReadingProgress 0.50
  $middle = Get-ReadingSnapshot $selector
  Assert-State ($middle.upcoming -gt 0 -and $middle.current -gt 0 -and $middle.completed -gt 0) 'No scroll position exposed completed, active, and upcoming manifesto words together.'
  Assert-State ($middle.distinctColors -ge 3 -and $middle.firstQuarter -gt ($middle.lastQuarter + 0.08)) 'Manifesto progression is not moving through individual words in reading order.'
  Assert-State $middle.allVisible 'Manifesto words became hidden during reading progression.'

  Set-ReadingProgress 0.98
  $late = Get-ReadingSnapshot $selector
  Assert-State ($late.average -gt ($middle.average + 0.12) -and $late.average -gt 0.72) 'Scrolling forward did not darken the manifesto toward completion.'

  Set-ReadingProgress 0.50
  $reverseMiddle = Get-ReadingSnapshot $selector
  Assert-State ([Math]::Abs([double]$reverseMiddle.average - [double]$middle.average) -lt 0.12) 'Returning to the same reading position did not restore comparable word progress.'

  Set-ReadingProgress 0.02
  $reverseEarly = Get-ReadingSnapshot $selector
  Assert-State ($reverseEarly.average -lt ($reverseMiddle.average - 0.12)) 'Scrolling upward did not reverse manifesto word progression.'
  Assert-State ([Math]::Abs([double]$reverseEarly.average - [double]$early.average) -lt 0.12) 'Reversed manifesto progression did not return to its pale initial state.'
  Assert-State $reverseEarly.allVisible 'Manifesto words became invisible after reverse scrolling.'
}

function Assert-ManmaticThemeInversion {
  Center-Element '.project-row[data-manmatic-system]'
  Wait-For 'document.documentElement.dataset.siteTheme === "manmatic" && document.querySelector("meta[name=theme-color]").content.toLowerCase() === "#0a0a0a"' 'The global ManMaTIC state did not activate.' 50
  Start-Sleep -Milliseconds 1050
  $dark = Evaluate-Json @'
JSON.stringify((() => {
  const bodyStyle = getComputedStyle(document.body);
  const htmlStyle = getComputedStyle(document.documentElement);
  const headerStyle = getComputedStyle(document.querySelector(".site-header"));
  const headerBounds = document.querySelector(".site-header").getBoundingClientRect();
  const shellStyle = getComputedStyle(document.querySelector(".site-shell"));
  const row = document.querySelector(".project-row[data-manmatic-system]");
  const rowStyle = getComputedStyle(row);
  const readingWord = document.querySelector(".reading-word");
  const numbers = color => (color.match(/[\d.]+/g) || []).map(Number);
  const luminance = color => {
    const values = numbers(color);
    if (values.length < 3) return -1;
    const scale = /^color\(srgb/i.test(color) ? 255 : 1;
    return (values[0] * 0.2126 + values[1] * 0.7152 + values[2] * 0.0722) * scale;
  };
  return {
    active: document.documentElement.dataset.siteTheme === "manmatic",
    bodyBackground: bodyStyle.backgroundColor,
    bodyColor: bodyStyle.color,
    htmlBackground: htmlStyle.backgroundColor,
    headerBackground: headerStyle.backgroundColor,
    headerColor: headerStyle.color,
    shellBackground: shellStyle.backgroundColor,
    rowBackground: rowStyle.backgroundColor,
    backgroundToken: bodyStyle.getPropertyValue("--background").trim(),
    textToken: bodyStyle.getPropertyValue("--text-primary").trim(),
    bodyBackgroundLight: luminance(bodyStyle.backgroundColor),
    bodyTextLight: luminance(bodyStyle.color),
    htmlBackgroundLight: luminance(htmlStyle.backgroundColor),
    headerBackgroundLight: luminance(headerStyle.backgroundColor),
    headerTextLight: luminance(headerStyle.color),
    headerPosition: headerStyle.position,
    headerTop: headerBounds.top,
    rowBackgroundLight: luminance(rowStyle.backgroundColor),
    readingLight: readingWord ? luminance(getComputedStyle(readingWord).color) : -1,
    themeColor: document.querySelector('meta[name="theme-color"]')?.content || ""
  };
})())
'@
  Assert-State $dark.active 'The body does not expose a ManMaTIC global state.'
  Assert-State ($dark.bodyBackgroundLight -ge 0 -and $dark.bodyBackgroundLight -lt 30 -and $dark.bodyTextLight -gt 180) 'The page body did not invert to dark with light text.'
  Assert-State ($dark.htmlBackgroundLight -ge 0 -and $dark.htmlBackgroundLight -lt 30) 'The root canvas remained light during ManMaTIC inversion.'
  Assert-State ($dark.headerBackgroundLight -ge 0 -and $dark.headerBackgroundLight -lt 35 -and $dark.headerTextLight -gt 150) 'The header did not participate in the ManMaTIC inversion.'
  Assert-State ($dark.headerPosition -eq 'fixed' -and [Math]::Abs([double]$dark.headerTop) -le 1) 'The site header is not fixed at the top while scrolling.'
  Assert-State ($dark.rowBackgroundLight -ge 0 -and $dark.rowBackgroundLight -lt 30 -and $dark.themeColor.ToLower() -eq '#0a0a0a') 'The ManMaTIC field or browser theme color is not dark.'
  Assert-State ($dark.readingLight -gt 150) 'Completed reading text did not adapt to the globally inverted theme.'

  $null = Evaluate 'window.scrollBy(0, 24); true'
  Start-Sleep -Milliseconds 180
  Assert-State ([bool](Evaluate 'document.documentElement.dataset.siteTheme === "manmatic"')) 'The ManMaTIC state flickered inside its active range.'

  Center-Element '.project-row[data-project-index="03"]'
  Wait-For 'document.documentElement.dataset.siteTheme !== "manmatic" && document.querySelector("meta[name=theme-color]").content.toLowerCase() === "#ffffff"' 'The page did not leave the ManMaTIC state.' 50
  Start-Sleep -Milliseconds 1050
  $light = Evaluate-Json @'
JSON.stringify((() => {
  const bodyStyle = getComputedStyle(document.body);
  const htmlStyle = getComputedStyle(document.documentElement);
  const numbers = color => (color.match(/[\d.]+/g) || []).map(Number);
  const luminance = color => {
    const values = numbers(color);
    const scale = /^color\(srgb/i.test(color) ? 255 : 1;
    return values.length >= 3 ? (values[0] * 0.2126 + values[1] * 0.7152 + values[2] * 0.0722) * scale : -1;
  };
  return {
    bodyBackgroundLight: luminance(bodyStyle.backgroundColor),
    bodyTextLight: luminance(bodyStyle.color),
    htmlBackgroundLight: luminance(htmlStyle.backgroundColor)
  };
})())
'@
  Assert-State ($light.bodyBackgroundLight -gt 235 -and $light.bodyTextLight -lt 60 -and $light.htmlBackgroundLight -gt 235) 'The page did not return to its light theme after ManMaTIC.'
}

function Assert-HeadingComplete([string]$selector, [string]$label) {
  Center-Element $selector
  $selectorLiteral = ConvertTo-Json -InputObject $selector -Compress
  $completeExpression = @"
(() => {
  const container = document.querySelector($selectorLiteral);
  if (!container) return false;
  const texts = Array.from(container.querySelectorAll(".heading-motion__text"));
  return container.classList.contains("is-heading-visible") &&
    container.classList.contains("is-heading-settled") &&
    !container.classList.contains("is-heading-scanning") && texts.length > 0 &&
    texts.every(text => {
      const expected = text.dataset.pointerText || text.dataset.scrambleText || "";
      return expected && text.textContent.trim() === expected.trim();
    });
})()
"@
  Wait-For $completeExpression ("Heading did not settle: {0}." -f $label) 80
  $state = Evaluate-Json @"
JSON.stringify((() => {
  const container = document.querySelector($selectorLiteral);
  const texts = Array.from(container.querySelectorAll(".heading-motion__text"));
  const bounds = container.getBoundingClientRect();
  const code = container.querySelector(".section-heading__code, h2 > span:not(.pointer-scan)");
  const note = container.querySelector(".section-heading__note");
  const rule = container.querySelector(".contact__marker-rule");
  const pseudo = getComputedStyle(container, "::before");
  const visible = node => !node || (getComputedStyle(node).visibility !== "hidden" && Number(getComputedStyle(node).opacity) > 0.9);
  return {
    width: bounds.width,
    left: bounds.left,
    right: bounds.right,
    texts: texts.length,
    textSizes: texts.map(text => ({ value: text.textContent, client: text.clientWidth, scroll: text.scrollWidth, display: getComputedStyle(text).display })),
    textOverflow: texts.some(text => text.scrollWidth > text.clientWidth + 2 && text.clientWidth > 0),
    codeVisible: visible(code),
    noteVisible: visible(note),
    ruleWidth: rule ? rule.getBoundingClientRect().width : parseFloat(pseudo.width) || 0,
    ruleTransform: rule ? getComputedStyle(rule).transform : pseudo.transform,
    scanning: container.classList.contains("is-heading-scanning")
  };
})())
"@
  Assert-State ($state.texts -gt 0 -and -not $state.textOverflow -and -not $state.scanning) ("Heading is clipped, overflowing, or still scanning: {0}. texts={1} overflow={2} scanning={3} sizes={4}" -f $label, $state.texts, $state.textOverflow, $state.scanning, ($state.textSizes | ConvertTo-Json -Compress))
  Assert-State ($state.left -ge -1 -and $state.right -le (([int](Evaluate 'innerWidth')) + 1)) ("Heading leaves the viewport: {0}." -f $label)
  Assert-State ($state.codeVisible -and $state.noteVisible) ("Heading code or technical note is not visible: {0}." -f $label)
  if ($selector -match 'section-heading|contact__marker') {
    Assert-State ($state.ruleWidth -gt 12 -and $state.ruleTransform -notmatch 'matrix\(0') ("Heading rule did not finish expanding: {0}." -f $label)
  }
}

function Assert-AllHeadingCompletion {
  $headings = @(
    @{ Selector = '.opening__name'; Label = 'opening Ahmad Alhadidii' },
    @{ Selector = '.manifesto__title'; Label = 'Architecture of Elsewhere' },
    @{ Selector = '#profile .section-heading'; Label = 'Profile' },
    @{ Selector = '#cv .section-heading'; Label = 'Curriculum Vitae' },
    @{ Selector = '#work .section-heading'; Label = 'Selected Work' },
    @{ Selector = '#visual-studies .section-heading'; Label = 'Visuals' },
    @{ Selector = '#contact .contact__marker'; Label = 'Contact' },
    @{ Selector = '.closing-identity'; Label = 'closing Ahmad Alhadidii' }
  )
  foreach ($heading in $headings) {
    Assert-HeadingComplete $heading.Selector $heading.Label
  }
  foreach ($slug in $expectedSlugs) {
    Assert-HeadingComplete ".project-row[data-project-id='$slug']" ("project title {0}" -f $slug)
  }
}

function Assert-ResponsiveLayout($viewport, [string]$label) {
  Set-Viewport $viewport
  $width = [int]$viewport.Width
  $height = [int]$viewport.Height
  Start-Sleep -Milliseconds 180
  $null = Evaluate 'document.documentElement.style.scrollBehavior = "auto"; window.scrollTo(0, 0); true'
  $null = Evaluate "document.documentElement.dataset.auditWidth = '$width'; true"
  Start-Sleep -Milliseconds 180
  $state = Evaluate-Json @'
JSON.stringify((() => {
  const home = document.body.classList.contains("home-page");
  const width = innerWidth;
  const visible = element => {
    const style = getComputedStyle(element);
    return style.display !== "none" && style.visibility !== "hidden";
  };
  const selector = home
    ? ".site-header__inner, main > section, .broadcast-monitor, .project-row, .visual-slider, .contact__band, .closing-identity, .site-footer"
    : ".site-header__inner, .project-header, .project-hero, .project-copy-section, .project-navigation, .site-footer";
  const boundsViolations = Array.from(document.querySelectorAll(selector)).filter(visible).filter(element => {
    const bounds = element.getBoundingClientRect();
    return bounds.width > 0 && (bounds.left < -1.5 || bounds.right > width + 1.5);
  }).map(element => element.className || element.tagName);
  const headings = Array.from(document.querySelectorAll("h1, h2, h3")).filter(visible);
  const headingOverflow = headings.filter(heading => heading.clientWidth > 0 && heading.scrollWidth > heading.clientWidth + 2).map(heading => (heading.textContent || "").trim().slice(0, 80));
  const emails = Array.from(document.querySelectorAll('a[href^="mailto:"]')).filter(visible);
  const emailOverflow = emails.filter(email => {
    const bounds = email.getBoundingClientRect();
    return bounds.left < -1.5 || bounds.right > width + 1.5 || email.scrollWidth > email.clientWidth + 2;
  }).map(email => email.textContent.trim());
  const monitor = document.querySelector(".broadcast-monitor");
  const monitorBounds = monitor ? monitor.getBoundingClientRect() : null;
  const nav = document.getElementById("primary-navigation");
  const toggle = document.getElementById("nav-toggle");
  const toggleBounds = toggle ? toggle.getBoundingClientRect() : null;
  const sliderButtons = Array.from(document.querySelectorAll("[data-visual-prev], [data-visual-next]"));
  const sliderTargets = sliderButtons.map(button => {
    const bounds = button.getBoundingClientRect();
    return { width: bounds.width, height: bounds.height };
  });
  const projectImages = Array.from(document.querySelectorAll(".project-row:not([hidden]) .project-row__media img, .project-hero img"));
  const requestedWidth = Number(document.documentElement.dataset.auditWidth || innerWidth);
  const overflowElements = Array.from(document.body.querySelectorAll("*")).filter(visible).map(element => {
    const bounds = element.getBoundingClientRect();
    return { element, bounds };
  }).filter(item => item.bounds.width > 0 && (item.bounds.left < -1.5 || item.bounds.right > requestedWidth + 1.5)).sort((a, b) => Math.abs(a.bounds.right - requestedWidth) - Math.abs(b.bounds.right - requestedWidth)).slice(0, 12).map(item => ({
    tag: item.element.tagName,
    className: item.element.className || "",
    left: Math.round(item.bounds.left),
    right: Math.round(item.bounds.right),
    width: Math.round(item.bounds.width)
  }));
  return {
    width: innerWidth,
    height: innerHeight,
    rootScrollWidth: document.documentElement.scrollWidth,
    bodyScrollWidth: document.body.scrollWidth,
    bodyScrollHeight: document.body.scrollHeight,
    overflowElements,
    boundsViolations,
    headingOverflow,
    emailOverflow,
    monitorLeft: monitorBounds ? monitorBounds.left : 0,
    monitorRight: monitorBounds ? monitorBounds.right : 0,
    monitorWidth: monitorBounds ? monitorBounds.width : 0,
    navAriaHidden: nav?.getAttribute("aria-hidden") ?? "",
    navVisible: nav ? visible(nav) : false,
    toggleVisible: toggle ? visible(toggle) : false,
    toggleWidth: toggleBounds ? toggleBounds.width : 0,
    toggleHeight: toggleBounds ? toggleBounds.height : 0,
    menuOpen: document.body.classList.contains("menu-open"),
    sliderTargets,
    badProjectImages: projectImages.filter(image => {
      const bounds = image.getBoundingClientRect();
      return bounds.width <= 0 || bounds.height <= 0;
    }).map(image => ({ src: image.currentSrc || image.getAttribute("src"), className: image.className, width: image.getBoundingClientRect().width, height: image.getBoundingClientRect().height })),
    loaderHidden: Boolean(document.getElementById("loader")?.hidden)
  };
})())
'@
  Assert-State ($state.width -eq $width -and $state.height -eq $height) ("Browser viewport mismatch for {0} at {1}: requested {2}x{3}, actual {4}x{5}, root/body scroll widths {6}/{7}." -f $label, $viewport.Name, $width, $height, $state.width, $state.height, $state.rootScrollWidth, $state.bodyScrollWidth)
  Assert-State ($state.rootScrollWidth -le ($width + 1) -and $state.bodyScrollWidth -le ($width + 1)) ("Horizontal overflow for {0} at {1}: root {2}, body {3}, viewport {4}; elements {5}." -f $label, $viewport.Name, $state.rootScrollWidth, $state.bodyScrollWidth, $width, (($state.overflowElements | ConvertTo-Json -Compress) -join ''))
  Assert-State (@($state.boundsViolations).Count -eq 0) ("Key layout bounds leave the viewport for {0} at {1}: {2}." -f $label, $viewport.Name, (@($state.boundsViolations) -join ', '))
  Assert-State (@($state.headingOverflow).Count -eq 0) ("A heading clips or overflows for {0} at {1}: {2}." -f $label, $viewport.Name, (@($state.headingOverflow) -join ', '))
  Assert-State (@($state.emailOverflow).Count -eq 0) ("An email address overflows for {0} at {1}." -f $label, $viewport.Name)
  Assert-State ($state.bodyScrollHeight -gt $height -and $state.loaderHidden -and -not $state.menuOpen) ("The page is clipped, loading, or menu-locked for {0} at {1}." -f $label, $viewport.Name)
  Assert-State (@($state.badProjectImages).Count -eq 0) ("A project image has no layout box for {0} at {1}: {2}." -f $label, $viewport.Name, (($state.badProjectImages | ConvertTo-Json -Compress) -join ''))

  if ((Evaluate 'document.body.classList.contains("home-page")')) {
    Assert-State ($state.monitorWidth -gt 0 -and $state.monitorLeft -ge -1 -and $state.monitorRight -le ($width + 1)) ("Opening monitor overflows at {0}." -f $viewport.Name)
    foreach ($target in @($state.sliderTargets)) {
      Assert-State ($target.width -ge 44 -and $target.height -ge 44) ("Slider touch target is too small at {0}." -f $viewport.Name)
    }
  }

  if ($width -le 960) {
    Assert-State ($state.toggleVisible -and $state.toggleWidth -ge 44 -and $state.toggleHeight -ge 44 -and $state.navAriaHidden -eq 'true') ("Mobile navigation state is invalid at {0}." -f $viewport.Name)
  } else {
    Assert-State (-not $state.toggleVisible -and $state.navVisible -and [string]::IsNullOrEmpty([string]$state.navAriaHidden)) ("Desktop navigation state is invalid at {0}." -f $viewport.Name)
  }
}

function Assert-HomepageViewports {
  foreach ($viewport in $viewports) {
    Assert-ResponsiveLayout $viewport 'homepage'
  }
}

function Assert-MobileMenuAtViewport($viewport) {
  Set-Viewport $viewport
  $width = [int]$viewport.Width
  $height = [int]$viewport.Height
  Wait-For "innerWidth === $width && innerHeight === $height" ("Mobile menu viewport did not settle: {0}." -f $viewport.Name) 40
  $null = Evaluate 'window.scrollTo(0, Math.min(160, document.documentElement.scrollHeight - innerHeight)); true'
  Start-Sleep -Milliseconds 80
  $before = Evaluate-Json 'JSON.stringify({ rootOverflow: document.documentElement.style.overflow, rootOverscroll: document.documentElement.style.overscrollBehavior, bodyOverflow: document.body.style.overflow })'

  $null = Evaluate @'
(() => {
  const toggle = document.getElementById("nav-toggle");
  toggle.dispatchEvent(new PointerEvent("pointerup", {
    bubbles: true,
    cancelable: true,
    pointerId: 71,
    pointerType: "touch",
    isPrimary: true,
    button: 0
  }));
  return true;
})()
'@
  Wait-For 'document.getElementById("nav-toggle").getAttribute("aria-expanded") === "true" && document.body.classList.contains("menu-open") && document.getElementById("primary-navigation").getAttribute("aria-hidden") === "false"' ("The mobile menu did not open through touch input: {0}." -f $viewport.Name) 30
  Start-Sleep -Milliseconds 380
  $open = Evaluate-Json @'
JSON.stringify((() => {
  const nav = document.getElementById("primary-navigation");
  const toggle = document.getElementById("nav-toggle");
  const close = toggle.querySelector(".nav-toggle__close");
  const navStyle = getComputedStyle(nav);
  const navRect = nav.getBoundingClientRect();
  const toggleRect = toggle.getBoundingClientRect();
  const links = Array.from(nav.querySelectorAll("a"));
  const numbers = color => (color.match(/[\d.]+/g) || []).map(Number);
  const luminance = color => {
    const rgb = numbers(color);
    const scale = /^color\(srgb/i.test(color) ? 255 : 1;
    return rgb.length >= 3 ? (rgb[0] * 0.2126 + rgb[1] * 0.7152 + rgb[2] * 0.0722) * scale : -1;
  };
  const backgroundLight = luminance(navStyle.backgroundColor);
  return {
    navVisible: navStyle.display !== "none" && navStyle.visibility !== "hidden" && Number(navStyle.opacity) > 0.98 && navStyle.pointerEvents !== "none",
    navInViewport: navRect.width > 0 && navRect.height > 0 && navRect.left >= -1 && navRect.right <= innerWidth + 1 && navRect.top >= -1 && navRect.bottom <= innerHeight + 1,
    links: links.length,
    linksReadable: links.every(link => {
      const rect = link.getBoundingClientRect();
      const style = getComputedStyle(link);
      const foregroundLight = luminance(style.color);
      return Boolean((link.textContent || "").trim()) && rect.width >= 44 && rect.height >= 44 &&
        style.display !== "none" && style.visibility !== "hidden" && Number(style.opacity) > 0.98 &&
        foregroundLight >= 0 && backgroundLight >= 0 && Math.abs(foregroundLight - backgroundLight) >= 70;
    }),
    toggleLarge: toggleRect.width >= 44 && toggleRect.height >= 44,
    closeVisible: Boolean((close.textContent || "").trim()) && getComputedStyle(close).display !== "none" && getComputedStyle(close).visibility !== "hidden" && Number(getComputedStyle(close).opacity) > 0.98,
    closeLabel: toggle.getAttribute("aria-label") || "",
    rootLocked: document.documentElement.style.overflow === "hidden" && document.documentElement.style.overscrollBehavior === "none",
    bodyLocked: document.body.style.overflow === "hidden",
    scrollWidth: document.documentElement.scrollWidth,
    clientWidth: document.documentElement.clientWidth
  };
})())
'@
  Assert-State ($open.navVisible -and $open.navInViewport -and $open.links -ge 6 -and $open.linksReadable) ("The mobile menu is empty, clipped, transparent, or unreadable: {0}." -f $viewport.Name)
  Assert-State ($open.toggleLarge -and $open.closeVisible -and $open.closeLabel -match 'Close') ("The mobile close control is hidden, too small, or lacks an accessible label: {0}." -f $viewport.Name)
  Assert-State ($open.rootLocked -and $open.bodyLocked -and $open.scrollWidth -le ($open.clientWidth + 1)) ("The open mobile menu is not scroll-locked or introduces horizontal overflow: {0}." -f $viewport.Name)

  $null = Evaluate 'document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true })); true'
  Wait-For 'document.getElementById("nav-toggle").getAttribute("aria-expanded") === "false" && !document.body.classList.contains("menu-open") && document.getElementById("primary-navigation").getAttribute("aria-hidden") === "true"' ("The mobile menu did not close on Escape: {0}." -f $viewport.Name) 30
  $closed = Evaluate-Json 'JSON.stringify({ rootOverflow: document.documentElement.style.overflow, rootOverscroll: document.documentElement.style.overscrollBehavior, bodyOverflow: document.body.style.overflow, openLabel: document.getElementById("nav-toggle").getAttribute("aria-label") || "" })'
  Assert-State ($closed.rootOverflow -eq $before.rootOverflow -and $closed.rootOverscroll -eq $before.rootOverscroll -and $closed.bodyOverflow -eq $before.bodyOverflow -and $closed.openLabel -match 'Open') ("Escape left the document locked or the toggle mislabeled: {0}." -f $viewport.Name)

  $null = Evaluate @'
(() => {
  const toggle = document.getElementById("nav-toggle");
  const touch = () => toggle.dispatchEvent(new PointerEvent("pointerup", { bubbles: true, cancelable: true, pointerId: 72, pointerType: "touch", isPrimary: true, button: 0 }));
  touch();
  touch();
  return true;
})()
'@
  Wait-For 'document.getElementById("nav-toggle").getAttribute("aria-expanded") === "false" && !document.body.classList.contains("menu-open")' ("The mobile close control did not respond to touch: {0}." -f $viewport.Name) 30
  $touchClosed = Evaluate-Json 'JSON.stringify({ rootOverflow: document.documentElement.style.overflow, rootOverscroll: document.documentElement.style.overscrollBehavior, bodyOverflow: document.body.style.overflow })'
  Assert-State ($touchClosed.rootOverflow -eq $before.rootOverflow -and $touchClosed.rootOverscroll -eq $before.rootOverscroll -and $touchClosed.bodyOverflow -eq $before.bodyOverflow) ("Touch-close did not restore document scrolling: {0}." -f $viewport.Name)
}

function Assert-MobileInteractions {
  Set-Viewport $phoneViewport
  Wait-For 'innerWidth === 390 && innerHeight === 844' 'Mobile interaction viewport did not settle.' 40
  Assert-ReadingProgression
  $null = Evaluate 'document.documentElement.style.scrollBehavior = "auto"; window.scrollTo(0, 0); true'
  Start-Sleep -Milliseconds 100

  foreach ($name in @('320x568', '375x812', '390x844', '430x932', '768x1024')) {
    $viewport = $viewports | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    Assert-MobileMenuAtViewport $viewport
  }

  Set-Viewport $phoneViewport
  Wait-For 'innerWidth === 390 && innerHeight === 844' 'Mobile interaction viewport did not reset.' 40

  Center-Element '[data-visual-slider]'
  $null = Evaluate 'document.querySelector("[data-visual-slider]").dispatchEvent(new KeyboardEvent("keydown", { key: "Home", bubbles: true })); document.querySelector("[data-visual-prev]").click(); document.querySelector("[data-visual-next]").click(); true'
  $null = Evaluate @'
(() => {
  const slider = document.querySelector("[data-visual-slider]");
  const viewport = slider.querySelector("[data-visual-viewport]");
  const start = { bubbles: true, cancelable: true, pointerId: 41, pointerType: "touch", button: 0, clientX: 300, clientY: 200 };
  viewport.dispatchEvent(new PointerEvent("pointerdown", start));
  viewport.dispatchEvent(new PointerEvent("pointermove", { ...start, clientX: 185, clientY: 202 }));
  viewport.dispatchEvent(new PointerEvent("pointerup", { ...start, clientX: 185, clientY: 202 }));
  return true;
})()
'@
  Wait-For 'document.querySelector("[data-visual-current]").textContent.trim() === "02"' 'The Visuals touch swipe did not advance.' 30
  $null = Evaluate 'document.querySelector("[data-visual-prev]").click(); true'
  Wait-For 'document.querySelector("[data-visual-current]").textContent.trim() === "01"' 'The Visuals slider did not reset after touch testing.' 30
}

function Assert-ProjectRoute([string]$slug, [string]$number, [string]$previousSlug, [string]$nextSlug) {
  Wait-For "document.body.dataset.project === '$slug' && document.querySelectorAll('.project-header').length === 1" ("Project route did not render: {0}." -f $slug) 80
  Wait-For-AppReady ("project route {0}" -f $slug)
  Assert-HeadingComplete '.project-header' ("project page heading {0}" -f $slug)
  Wait-For 'document.querySelector(".project-hero img")?.complete && document.querySelector(".project-hero img").naturalWidth > 0' ("Project hero did not load: {0}." -f $slug) 100

  $state = Evaluate-Json @'
JSON.stringify((() => {
  const project = window.siteContent.projects.find(item => (item.slug || item.id) === document.body.dataset.project);
  const header = document.querySelector(".project-header");
  const image = document.querySelector(".project-hero img");
  const links = Array.from(document.querySelectorAll(".project-navigation__link"));
  const loader = document.getElementById("loader");
  const loaderImage = loader?.querySelector("[data-loader-preview]");
  const bodyStyle = getComputedStyle(document.body);
  const htmlStyle = getComputedStyle(document.documentElement);
  const values = color => (color.match(/[\d.]+/g) || []).map(Number);
  const luminance = color => {
    const rgb = values(color);
    const scale = /^color\(srgb/i.test(color) ? 255 : 1;
    return rgb.length >= 3 ? (rgb[0] * 0.2126 + rgb[1] * 0.7152 + rgb[2] * 0.0722) * scale : -1;
  };
  return {
    slug: document.body.dataset.project || "",
    theme: document.documentElement.dataset.siteTheme || "",
    headerTheme: header?.dataset.projectTheme || "",
    number: (header?.querySelector(".project-header__eyebrow")?.textContent.match(/\d{2}/) || [""])[0],
    title: header?.querySelector("h1")?.getAttribute("aria-label") || "",
    dataTitle: project?.navigationTitle || project?.title || "",
    dataLoaderTitle: project?.archiveTitle || project?.title || "",
    dataLoaderImage: project?.hero?.src || "",
    h1Count: document.querySelectorAll("main h1").length,
    headerCount: document.querySelectorAll(".project-header").length,
    heroCount: document.querySelectorAll(".project-hero").length,
    heroComplete: Boolean(image?.complete && image.naturalWidth > 0 && image.naturalHeight > 0),
    heroLocal: image ? !/^https?:/i.test(image.getAttribute("src") || "") : false,
    heroVisible: image ? image.getBoundingClientRect().width > 40 && image.getBoundingClientRect().height > 24 && getComputedStyle(image).visibility !== "hidden" : false,
    overview: document.querySelectorAll(".project-copy-section").length,
    frameworkPoints: document.querySelectorAll(".project-logic-list li").length,
    expandedSections: document.querySelectorAll(".project-expanded-section").length,
    navigation: links.length,
    navHrefs: links.map(link => link.getAttribute("href") || ""),
    bodyLight: luminance(bodyStyle.backgroundColor),
    textLight: luminance(bodyStyle.color),
    htmlLight: luminance(htmlStyle.backgroundColor),
    scrollWidth: document.documentElement.scrollWidth,
    clientWidth: document.documentElement.clientWidth,
    fieldLink: Boolean(document.querySelector(".project-header__field-link"))
    ,loaderProjectClass: Boolean(loader?.classList.contains("loader--project"))
    ,loaderDarkClass: Boolean(loader?.classList.contains("loader--project-dark"))
    ,loaderTitle: document.getElementById("loader-name")?.textContent.trim() || ""
    ,loaderKicker: loader?.querySelector("[data-project-loader-kicker]")?.textContent.trim() || ""
    ,loaderCaption: loader?.querySelector("[data-project-loader-caption]")?.textContent.trim() || ""
    ,loaderImage: loaderImage?.getAttribute("src") || ""
    ,loaderBackgroundLight: loader ? luminance(getComputedStyle(loader).backgroundColor) : -1
  };
})())
'@
  Assert-State ($state.slug -eq $slug -and $state.h1Count -eq 1 -and $state.headerCount -eq 1) ("Project identity structure is invalid: {0}." -f $slug)
  Assert-State ($state.number -eq $number.Substring(1, 2) -and -not [string]::IsNullOrWhiteSpace([string]$state.title) -and $state.title -eq $state.dataTitle) ("Project number or title does not match central data: {0}." -f $slug)
  Assert-State ($state.heroCount -eq 1 -and $state.heroComplete -and $state.heroLocal -and $state.heroVisible) ("Project hero is missing, remote, unloaded, or invisible: {0}." -f $slug)
  Assert-State ($state.overview -ge 2 -and ($state.frameworkPoints -ge 1 -or $state.expandedSections -ge 1)) ("Project overview/framework is incomplete: {0}." -f $slug)
  Assert-State ($state.navigation -eq 2) ("Project previous/next navigation is incomplete: {0}." -f $slug)
  Assert-State ((@($state.navHrefs) -join ',') -eq ("project.html?project={0},project.html?project={1}" -f $previousSlug, $nextSlug)) ("Project navigation order is invalid: {0}." -f $slug)
  Assert-State ($state.scrollWidth -le ($state.clientWidth + 1)) ("Project route has horizontal overflow: {0}." -f $slug)
  Assert-State ($state.loaderTitle -eq $state.dataLoaderTitle -and $state.loaderKicker -eq ("PROJECT FILE {0}" -f $number.Substring(1, 2))) ("Project loader title or number is not dynamic: {0}." -f $slug)
  Assert-State ($state.loaderCaption -match [regex]::Escape([string]$state.dataLoaderTitle) -and $state.loaderImage -eq $state.dataLoaderImage) ("Project loader image or caption does not match the selected project: {0}." -f $slug)

  if ($slug -eq 'project-01') {
    Assert-State ($state.loaderProjectClass -and $state.loaderDarkClass -and $state.loaderBackgroundLight -ge 0 -and $state.loaderBackgroundLight -lt 20) 'The ManMaTIC project loader is not using the dedicated black opening system.'
    Assert-State ($state.theme -eq 'manmatic' -and $state.headerTheme -eq 'manmatic' -and $state.bodyLight -lt 30 -and $state.htmlLight -lt 30 -and $state.textLight -gt 180 -and $state.fieldLink) 'The ManMaTIC project route is not fully inverted by default.'
  } else {
    Assert-State ($state.loaderProjectClass -and -not $state.loaderDarkClass -and $state.loaderBackgroundLight -gt 235) ("A non-ManMaTIC project loader is not light: {0}." -f $slug)
    Assert-State ($state.theme -eq 'light' -and $state.headerTheme -eq 'light' -and $state.bodyLight -gt 235 -and $state.htmlLight -gt 235 -and $state.textLight -lt 70 -and -not $state.fieldLink) ("A light project route has the wrong theme: {0}." -f $slug)
  }
}

function Assert-ProjectRoutes {
  for ($index = 0; $index -lt $expectedSlugs.Count; $index++) {
    Set-Viewport $desktopViewport
    $slug = $expectedSlugs[$index]
    $previousSlug = $expectedSlugs[($index - 1 + $expectedSlugs.Count) % $expectedSlugs.Count]
    $nextSlug = $expectedSlugs[($index + 1) % $expectedSlugs.Count]
    Clear-CdpEvents
    Navigate ($projectBaseUrl + "?project=$slug")
    Assert-ProjectRoute $slug $expectedNumbers[$index] $previousSlug $nextSlug
    Assert-No-PageErrors ("project route {0}" -f $slug)

    if ($slug -eq 'project-01') {
      $keyNames = @('320x568', '390x844', '844x390', '768x1024', '1024x768', '1440x900', '1920x1080')
      Clear-CdpEvents
      foreach ($name in $keyNames) {
        $viewport = $viewports | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        Assert-ResponsiveLayout $viewport 'ManMaTIC project'
      }
      Assert-No-PageErrors 'ManMaTIC project responsive checks'
      Set-Viewport $desktopViewport
    }
  }

  Clear-CdpEvents
  Navigate ($projectBaseUrl + '?project=missing')
  Wait-For 'document.querySelectorAll(".project-detail__error").length === 1' 'The invalid project route did not render its error state.' 80
  Wait-For-AppReady 'invalid project route'
  $invalid = Evaluate-Json @'
JSON.stringify({
  heading: document.querySelector(".project-detail__error h1")?.textContent.trim() || "",
  returnHref: document.querySelector(".project-detail__error a")?.getAttribute("href") || "",
  h1Count: document.querySelectorAll("main h1").length,
  scrollWidth: document.documentElement.scrollWidth,
  clientWidth: document.documentElement.clientWidth
})
'@
  Assert-State ($invalid.heading -eq 'PROJECT NOT FOUND' -and $invalid.returnHref -eq 'index.html#work' -and $invalid.h1Count -eq 1) 'The invalid project route is not a complete accessible fallback.'
  Assert-State ($invalid.scrollWidth -le ($invalid.clientWidth + 1)) 'The invalid project route has horizontal overflow.'
  Assert-No-PageErrors 'invalid project route'
}

function Assert-ReducedMotion {
  $null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{
    media = 'screen'
    features = @(@{ name = 'prefers-reduced-motion'; value = 'reduce' })
  }
  Set-Viewport $phoneViewport
  Clear-CdpEvents
  Navigate $homeUrl
  $null = Assert-LoaderCycle 'reduced-motion homepage loader' 3
  $reducedProbe = Evaluate-Json 'JSON.stringify(window.__portfolioContractProbe)'
  Assert-State ([int]$reducedProbe.blackFlashCount -eq 0) 'Reduced motion retained a black loader flash.'
  $state = Evaluate-Json @'
JSON.stringify((() => {
  const headings = Array.from(document.querySelectorAll(".heading-motion"));
  const scrambles = Array.from(document.querySelectorAll("[data-scramble]"));
  const readingWords = Array.from(document.querySelectorAll(".reading-word"));
  const reveals = Array.from(document.querySelectorAll("[data-image-reveal]"));
  const reel = document.querySelector("[data-showreel-fallback]");
  const toggle = document.querySelector("[data-showreel-toggle]");
  const duration = value => Math.max(...String(value).split(",").map(part => parseFloat(part) || 0));
  return {
    media: matchMedia("(prefers-reduced-motion: reduce)").matches,
    rootClass: document.documentElement.classList.contains("reduced-motion"),
    headings: headings.length,
    settledHeadings: headings.filter(heading => heading.classList.contains("is-heading-settled") && !heading.classList.contains("is-heading-scanning")).length,
    scrambleMismatches: scrambles.filter(text => {
      const expected = text.dataset.pointerText || text.dataset.scrambleText || text.textContent;
      return text.textContent.trim() !== String(expected).trim();
    }).length,
    readingWords: readingWords.length,
    incompleteWords: readingWords.filter(word => {
      const progress = parseFloat(word.style.getPropertyValue("--reading-progress"));
      return !Number.isFinite(progress) || progress < 0.999;
    }).length,
    hiddenWords: readingWords.filter(word => getComputedStyle(word).visibility === "hidden" || Number(getComputedStyle(word).opacity) < 0.9).length,
    reveals: reveals.length,
    visibleReveals: reveals.filter(reveal => reveal.classList.contains("is-visible")).length,
    reelFrame: reel?.dataset.activeFrame || "",
    reelPlaying: reel?.dataset.playing || "",
    reelStatus: document.getElementById("showreel-status")?.textContent.trim() || "",
    toggleDisabled: Boolean(toggle?.disabled),
    toggleText: toggle?.textContent.trim() || "",
    binaryRemoved: !document.querySelector(".loader__binary"),
    scanDisplay: getComputedStyle(document.querySelector(".pointer-scan"), "::after").display,
    maxTransition: duration(getComputedStyle(document.querySelector(".project-row")).transitionDuration),
    scrollWidth: document.documentElement.scrollWidth,
    clientWidth: document.documentElement.clientWidth
  };
})())
'@
  Assert-State ($state.media -and $state.rootClass) 'The browser and root do not expose reduced-motion mode.'
  Assert-State ($state.headings -gt 0 -and $state.settledHeadings -eq $state.headings -and $state.scrambleMismatches -eq 0) 'Reduced motion left a heading moving, clipped, or scrambled.'
  Assert-State ($state.readingWords -gt 0 -and $state.incompleteWords -eq 0 -and $state.hiddenWords -eq 0) 'Reduced motion left reading text pale, incomplete, or hidden.'
  Assert-State ($state.reveals -gt 0 -and $state.visibleReveals -eq $state.reveals) 'Reduced motion left an image reveal concealed.'
  Assert-State ($state.reelFrame -eq '01' -and $state.reelPlaying -eq 'false' -and $state.reelStatus -match '^STATIC' -and $state.toggleDisabled -and $state.toggleText -eq 'STATIC FRAME') 'Reduced motion did not freeze the showreel in its accessible static state.'
  Assert-State ($state.binaryRemoved -and $state.scanDisplay -eq 'none' -and $state.maxTransition -le 0.02) 'Reduced motion retained binary, scanning, or long transition effects.'
  Assert-State ($state.scrollWidth -le ($state.clientWidth + 1)) 'Reduced-motion homepage has horizontal overflow.'

  Assert-ResponsiveLayout $phoneViewport 'reduced-motion homepage'
  Assert-ResponsiveLayout $smallPhoneViewport 'reduced-motion homepage'
  Assert-No-PageErrors 'reduced-motion homepage'
}

function Send-CdpNoWait([string]$method) {
  if ($null -eq $ws -or $ws.State -ne [System.Net.WebSockets.WebSocketState]::Open) { return }
  $script:cdpId++
  $json = @{ id = $script:cdpId; method = $method } | ConvertTo-Json -Compress
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  $segment = [System.ArraySegment[byte]]::new($bytes)
  $null = $ws.SendAsync(
    $segment,
    [System.Net.WebSockets.WebSocketMessageType]::Text,
    $true,
    [System.Threading.CancellationToken]::None
  ).GetAwaiter().GetResult()
}

$runFailure = $null
$cleanupFailure = $null

try {
  Assert-SourceContract
  Assert-State (Test-Path -LiteralPath $chrome -PathType Leaf) 'Google Chrome was not found at the configured path.'

  New-Item -ItemType Directory -Force -Path $outDir | Out-Null
  New-Item -ItemType Directory -Force -Path $profile | Out-Null
  $profileCreated = $true

  $process = Start-Process -FilePath $chrome -ArgumentList @(
    '--headless=new',
    '--disable-gpu',
    '--disable-background-timer-throttling',
    '--disable-backgrounding-occluded-windows',
    '--disable-renderer-backgrounding',
    '--disable-default-apps',
    '--hide-scrollbars',
    '--no-first-run',
    '--no-default-browser-check',
    '--allow-file-access-from-files',
    '--remote-debugging-port=0',
    '--remote-allow-origins=*',
    "--user-data-dir=$profile",
    'about:blank'
  ) -PassThru -WindowStyle Hidden

  $portFile = Join-Path $profile 'DevToolsActivePort'
  $deadline = (Get-Date).AddSeconds(15)
  while (-not (Test-Path -LiteralPath $portFile) -and (Get-Date) -lt $deadline) {
    if ($process.HasExited) { throw 'Chrome exited before its DevTools endpoint started.' }
    Start-Sleep -Milliseconds 100
  }
  Assert-State (Test-Path -LiteralPath $portFile -PathType Leaf) 'Chrome DevTools endpoint did not start.'

  $port = [int](Get-Content -LiteralPath $portFile | Select-Object -First 1)
  $target = $null
  $targetDeadline = (Get-Date).AddSeconds(5)
  while ($null -eq $target -and (Get-Date) -lt $targetDeadline) {
    try {
      $targets = Invoke-RestMethod -Uri "http://127.0.0.1:$port/json/list"
      $target = $targets | Where-Object { $_.type -eq 'page' } | Select-Object -First 1
    } catch {}
    if ($null -eq $target) { Start-Sleep -Milliseconds 100 }
  }
  Assert-State ($null -ne $target) 'No Chrome page target was available.'

  $ws = [System.Net.WebSockets.ClientWebSocket]::new()
  $connectCancellation = [System.Threading.CancellationTokenSource]::new(15000)
  try {
    $null = $ws.ConnectAsync([System.Uri]$target.webSocketDebuggerUrl, $connectCancellation.Token).GetAwaiter().GetResult()
  } finally {
    $connectCancellation.Dispose()
  }

  $null = Invoke-Cdp 'Page.enable'
  $null = Invoke-Cdp 'Runtime.enable'
  $null = Invoke-Cdp 'Log.enable'
  $null = Invoke-Cdp 'Network.enable'
  $null = Invoke-Cdp 'Network.setCacheDisabled' @{ cacheDisabled = $true }
  $null = Invoke-Cdp 'Emulation.setFocusEmulationEnabled' @{ enabled = $true }
  Install-DocumentProbe
  $null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{
    media = 'screen'
    features = @(@{ name = 'prefers-reduced-motion'; value = 'no-preference' })
  }

  Set-Viewport $desktopViewport
  Clear-CdpEvents
  Navigate $homeUrl
  $firstProbe = Assert-LoaderCycle 'initial homepage loader'
  Assert-State ([int]$firstProbe.blackFlashCount -eq 2) 'The homepage loader did not restore both intentional black glitch flashes.'
  Assert-HomeStructure
  Assert-No-PageErrors 'initial homepage load'

  Clear-CdpEvents
  Reload-Page
  $refreshProbe = Assert-LoaderCycle 'refreshed homepage loader'
  Assert-State ([int]$refreshProbe.blackFlashCount -eq 2) 'The refreshed homepage loader did not replay both intentional black glitch flashes.'
  Assert-State ([double]$refreshProbe.timeOrigin -ne [double]$firstProbe.timeOrigin) 'The refresh did not create a new document loader cycle.'
  Assert-HomeStructure
  Assert-No-PageErrors 'refreshed homepage load'

  Clear-CdpEvents
  Assert-ShowreelChanges
  Assert-ReadingProgression
  Assert-ProjectImages
  Assert-VisualSlider
  Assert-ManmaticThemeInversion
  Assert-AllHeadingCompletion
  Assert-MobileInteractions
  Assert-HomepageViewports
  Assert-No-PageErrors 'homepage interactions and responsive checks'
  Capture-ManmaticEvidence

  Assert-ProjectRoutes
  Assert-VisualRoutes
  Assert-ReducedMotion

  Write-Output ("verification`tPASS`tassertions={0}`tviewports={1}`tprojects={2}`tvisuals={3}" -f $script:assertionCount, $viewports.Count, $expectedSlugs.Count, $expectedVisualSlugs.Count)
}
catch {
  $runFailure = $_
}
finally {
  try {
    if ($null -ne $ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
      try { Send-CdpNoWait 'Browser.close' } catch {}
      Start-Sleep -Milliseconds 250
    }
    if ($null -ne $ws) {
      try { $ws.Dispose() } catch {}
      $ws = $null
    }

    if ($null -ne $process) {
      try { $null = $process.WaitForExit(3000) } catch {}
      try {
        if (-not $process.HasExited) {
          Stop-Process -Id $process.Id -Force -ErrorAction Stop
          $null = $process.WaitForExit(3000)
        }
      } catch {
        if ($null -eq $cleanupFailure) { $cleanupFailure = $_ }
      }
    }

    if ($profileCreated) {
      try {
        $profileFull = [System.IO.Path]::GetFullPath($profile).TrimEnd('\')
        $outFull = [System.IO.Path]::GetFullPath($outDir).TrimEnd('\')
        $expectedPrefix = $outFull + [System.IO.Path]::DirectorySeparatorChar
        $safeProfile = $profileFull.StartsWith($expectedPrefix, [System.StringComparison]::OrdinalIgnoreCase) -and
          [System.IO.Path]::GetFileName($profileFull).StartsWith('profile-', [System.StringComparison]::OrdinalIgnoreCase)
        if (-not $safeProfile) { throw "Refusing to clean an unexpected profile path: $profileFull" }

        try {
          Get-CimInstance Win32_Process -Filter "Name = 'chrome.exe'" -ErrorAction Stop |
            Where-Object {
              $commandLine = [string]$_.CommandLine
              $commandLine.IndexOf($profileFull, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
            } |
            ForEach-Object {
              Stop-Process -Id ([int]$_.ProcessId) -Force -ErrorAction SilentlyContinue
            }
        } catch {}

        for ($attempt = 0; $attempt -lt 50 -and (Test-Path -LiteralPath $profileFull); $attempt++) {
          try {
            Remove-Item -LiteralPath $profileFull -Recurse -Force -ErrorAction Stop
          } catch {
            Start-Sleep -Milliseconds 100
          }
        }
        if (Test-Path -LiteralPath $profileFull) {
          throw "Chrome profile cleanup failed: $profileFull"
        }
      } catch {
        if ($null -eq $cleanupFailure) { $cleanupFailure = $_ }
      }
    }
  }
  catch {
    if ($null -eq $cleanupFailure) { $cleanupFailure = $_ }
  }
}

if ($null -ne $runFailure) { throw $runFailure }
if ($null -ne $cleanupFailure) { throw $cleanupFailure }
