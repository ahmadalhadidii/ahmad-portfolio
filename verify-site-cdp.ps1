$ErrorActionPreference = 'Stop'

$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$repoRoot = (Resolve-Path '.').Path
$outDir = Join-Path $env:TEMP 'ahmad-portfolio-contract-check'
$runId = Get-Date -Format 'yyyyMMdd-HHmmssfff'
$profile = Join-Path $outDir ("profile-$runId")
$homeUrl = ([System.Uri]::new((Resolve-Path '.\index.html').Path)).AbsoluteUri
$projectBaseUrl = ([System.Uri]::new((Resolve-Path '.\project.html').Path)).AbsoluteUri
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
    '.\content.js',
    '.\assets\css\style.css',
    '.\assets\js\main.js',
    '.\assets\js\project.js'
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

  foreach ($htmlPath in @('.\index.html', '.\project.html')) {
    $html = Get-Content -Raw -LiteralPath $htmlPath
    Assert-State ($html -match 'IBM\+Plex\+Sans' -and $html -match 'IBM\+Plex\+Mono') ("The two-font import is incomplete in {0}." -f $htmlPath)
    Assert-State ($html -match 'id="loader-progress"[^>]*>000<' -and $html -match 'id="loader-progress-secondary"[^>]*>000<') ("The loader does not begin at 000 in {0}." -f $htmlPath)
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
  $projectRows = [regex]::Matches($index, 'data-project-id="(project-\d{2})"')
  $rowIds = @($projectRows | ForEach-Object { $_.Groups[1].Value })
  Assert-State (($rowIds -join ',') -eq 'project-05,project-01,project-02,project-03,project-04') 'The homepage project archive order changed unexpectedly.'
  Assert-State ([regex]::Matches($index, 'data-manmatic-field').Count -eq 1) 'The homepage must contain one ManMaTIC activation field.'
  Assert-State ($index -match 'data-visual-slider' -and $index -match 'data-visual-prev' -and $index -match 'data-visual-next') 'The Visual Studies slider controls are missing from the source.'

  $mainScript = Get-Content -Raw -LiteralPath '.\assets\js\main.js'
  Assert-State ($mainScript -match 'prefers-reduced-motion' -and $mainScript -match 'data-reading-text' -and $mainScript -match 'reading-word') 'Reduced-motion or word-level reading logic is missing.'
  Assert-State ($mainScript -match 'data-showreel-slide' -and $mainScript -match 'data-visual-slider') 'Showreel or Visual Studies behavior is missing.'
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
$expectedSlugs = @('project-05', 'project-01', 'project-02', 'project-03', 'project-04')
$expectedNumbers = @('001', '002', '003', '004', '005')

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
  const sampleLoader = () => {
    const loader = document.getElementById("loader");
    const progress = document.getElementById("loader-progress");
    if (!loader || !progress) return;
    const value = String(progress.textContent || "").trim();
    if (!/^\d{3}$/.test(value)) return;
    const bar = document.getElementById("loader-progress-bar");
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
  const rows = Array.from(document.querySelectorAll(".project-row[data-project-id]"));
  const projects = window.siteContent && Array.isArray(window.siteContent.projects)
    ? window.siteContent.projects
    : [];
  const studies = window.siteContent && Array.isArray(window.siteContent.visualStudies)
    ? window.siteContent.visualStudies
    : [];
  const ids = Array.from(document.querySelectorAll("[id]"), node => node.id);
  const internalLinks = Array.from(document.querySelectorAll('a[href^="#"]'));
  const externalLinks = Array.from(document.querySelectorAll('a[target="_blank"]'));
  return {
    home: document.body.classList.contains("home-page"),
    h1Count: document.querySelectorAll("main h1").length,
    rowIds: rows.map(row => row.dataset.projectId || ""),
    rowNumbers: rows.map(row => (row.querySelector(".project-row__number")?.textContent || "").trim()),
    rowHrefs: rows.map(row => row.querySelector(".project-row__link")?.getAttribute("href") || ""),
    rowImages: rows.map(row => Boolean(row.querySelector(".project-row__media img"))),
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
    loaderBinaryRemoved: !document.querySelector(".loader__binary")
  };
})())
'@
  $state = Evaluate-Json $expression
  Assert-State $state.home 'The homepage body contract is missing.'
  Assert-State ($state.h1Count -eq 1) 'The homepage must have one main h1.'
  Assert-State ((@($state.rowIds) -join ',') -eq ($expectedSlugs -join ',')) 'Homepage project IDs are out of archive order.'
  Assert-State ((@($state.rowNumbers) -join ',') -eq ($expectedNumbers -join ',')) 'Homepage project numbers are out of archive order.'
  $expectedHrefs = @($expectedSlugs | ForEach-Object { "project.html?project=$_" })
  Assert-State ((@($state.rowHrefs) -join ',') -eq ($expectedHrefs -join ',')) 'Homepage project routes do not match the archive.'
  Assert-State ((@($state.dataIds) -join ',') -eq ($expectedSlugs -join ',') -and (@($state.dataNumbers) -join ',') -eq ($expectedNumbers -join ',')) 'Central project data does not match homepage order and numbering.'
  Assert-State (-not (@($state.rowImages) -contains $false)) 'At least one homepage project entry has no cover image.'
  Assert-State (@($state.duplicateIds).Count -eq 0 -and $state.emptyLinks -eq 0 -and @($state.brokenInternalLinks).Count -eq 0) 'The homepage contains duplicate IDs, empty links, or broken internal fragments.'
  Assert-State ($state.unsafeExternalLinks -eq 0) 'A new-tab external link is missing noopener/noreferrer.'
  Assert-State ($state.showreelSlides -ge 5 -and $state.showreelActive -eq 1) 'The homepage showreel frame structure is incomplete.'
  Assert-State ($state.sliderDataCount -ge 5) 'Visual Studies must contain at least five data entries.'
  Assert-State $state.loaderBinaryRemoved 'Loader binary elements were not removed after completion.'
}

function Assert-ProjectImages {
  foreach ($slug in $expectedSlugs) {
    $selector = ".project-row[data-project-id='$slug']"
    Center-Element $selector
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
  Wait-For 'document.querySelector("[data-visual-slider]")?.dataset.visualInitialized === "true"' 'The Visual Studies slider did not initialize.' 60
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
    dataCount: window.siteContent.visualStudies.length,
    slideCount: slides.length,
    current: slider.querySelector("[data-visual-current]")?.textContent.trim() || "",
    total: slider.querySelector("[data-visual-total]")?.textContent.trim() || "",
    active: slides.filter(slide => slide.classList.contains("is-active")).length,
    ariaVisible: slides.filter(slide => slide.getAttribute("aria-hidden") === "false").length,
    localImages: slides.every(slide => !/^https?:/i.test(slide.querySelector("img")?.getAttribute("src") || "")),
    altImages: slides.every(slide => Boolean((slide.querySelector("img")?.getAttribute("alt") || "").trim())),
    previous: size(previous),
    next: size(next),
    tabindex: slider.getAttribute("tabindex") || ""
  };
})())
'@
  Assert-State ($state.dataCount -ge 5 -and $state.slideCount -eq $state.dataCount) 'Visual Studies slide count does not match its data array or is below five.'
  Assert-State ($state.current -eq '01' -and [int]$state.total -eq $state.dataCount) 'Visual Studies initial current/total values are incorrect.'
  Assert-State ($state.active -eq 1 -and $state.ariaVisible -eq 1) 'Visual Studies does not expose exactly one active slide.'
  Assert-State ($state.localImages -and $state.altImages) 'Visual Studies requires local images with alt text.'
  Assert-State ($state.previous.width -ge 44 -and $state.previous.height -ge 44 -and $state.next.width -ge 44 -and $state.next.height -ge 44) 'Visual Studies controls are smaller than 44 by 44 pixels.'
  Assert-State ($state.tabindex -eq '0') 'Visual Studies is not keyboard focusable.'

  $null = Evaluate 'document.querySelector("[data-visual-next]").click(); true'
  Wait-For 'document.querySelector("[data-visual-current]").textContent.trim() === "02"' 'Visual Studies next control failed.' 30
  $null = Evaluate 'document.querySelector("[data-visual-prev]").click(); true'
  Wait-For 'document.querySelector("[data-visual-current]").textContent.trim() === "01"' 'Visual Studies previous control failed.' 30
  $lastValue = ([int]$state.dataCount).ToString('00')
  $lastValueLiteral = ConvertTo-Json -InputObject $lastValue -Compress
  $null = Evaluate 'document.querySelector("[data-visual-slider]").dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowLeft", bubbles: true, cancelable: true })); true'
  Wait-For "document.querySelector('[data-visual-current]').textContent.trim() === $lastValueLiteral" 'Visual Studies ArrowLeft wrapping failed.' 30
  $null = Evaluate 'document.querySelector("[data-visual-slider]").dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowRight", bubbles: true, cancelable: true })); true'
  Wait-For 'document.querySelector("[data-visual-current]").textContent.trim() === "01"' 'Visual Studies ArrowRight wrapping failed.' 30
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

function Assert-ReadingProgression {
  $selector = '.manifesto__text[data-reading-text]'
  Wait-For 'document.querySelectorAll(".manifesto__text .reading-word").length >= 20' 'The manifesto was not prepared into word-level reading spans.' 50

  Place-Element $selector 0.92
  $early = Get-ReadingSnapshot $selector
  Assert-State ($early.prepared -eq 'true' -and $early.count -ge 20) 'The manifesto word-level reading contract is incomplete.'
  Assert-State ($early.allVisible -and $early.average -lt 0.3) 'Upcoming manifesto words are not visibly pale before the reading line.'

  $middle = $null
  $middleFraction = 0.0
  foreach ($fraction in @(0.70, 0.64, 0.58, 0.52, 0.46, 0.40, 0.34, 0.28)) {
    Place-Element $selector $fraction
    $candidate = Get-ReadingSnapshot $selector
    if ($candidate.upcoming -gt 0 -and $candidate.current -gt 0 -and $candidate.completed -gt 0) {
      $middle = $candidate
      $middleFraction = $fraction
      break
    }
  }
  Assert-State ($null -ne $middle) 'No scroll position exposed completed, active, and upcoming manifesto words together.'
  Assert-State ($middle.distinctColors -ge 3 -and $middle.firstQuarter -gt ($middle.lastQuarter + 0.08)) 'Manifesto progression is not moving through individual words in reading order.'
  Assert-State $middle.allVisible 'Manifesto words became hidden during reading progression.'

  Place-Element $selector 0.18
  $late = Get-ReadingSnapshot $selector
  Assert-State ($late.average -gt ($middle.average + 0.12) -and $late.average -gt 0.72) 'Scrolling forward did not darken the manifesto toward completion.'

  Place-Element $selector $middleFraction
  $reverseMiddle = Get-ReadingSnapshot $selector
  Assert-State ([Math]::Abs([double]$reverseMiddle.average - [double]$middle.average) -lt 0.12) 'Returning to the same reading position did not restore comparable word progress.'

  Place-Element $selector 0.92
  $reverseEarly = Get-ReadingSnapshot $selector
  Assert-State ($reverseEarly.average -lt ($reverseMiddle.average - 0.12)) 'Scrolling upward did not reverse manifesto word progression.'
  Assert-State ([Math]::Abs([double]$reverseEarly.average - [double]$early.average) -lt 0.12) 'Reversed manifesto progression did not return to its pale initial state.'
  Assert-State $reverseEarly.allVisible 'Manifesto words became invisible after reverse scrolling.'
}

function Assert-ManmaticThemeInversion {
  Center-Element '.project-row[data-manmatic-field]'
  Wait-For '(document.body.classList.contains("is-manmatic-active") || document.body.dataset.siteTheme === "manmatic") && document.querySelector("meta[name=theme-color]").content.toLowerCase() === "#0a0a0a"' 'The global ManMaTIC state did not activate.' 50
  Start-Sleep -Milliseconds 1050
  $dark = Evaluate-Json @'
JSON.stringify((() => {
  const bodyStyle = getComputedStyle(document.body);
  const htmlStyle = getComputedStyle(document.documentElement);
  const headerStyle = getComputedStyle(document.querySelector(".site-header"));
  const shellStyle = getComputedStyle(document.querySelector(".site-shell"));
  const row = document.querySelector(".project-row[data-manmatic-field]");
  const rowStyle = getComputedStyle(row);
  const readingWord = document.querySelector(".reading-word");
  const numbers = color => (color.match(/[\d.]+/g) || []).map(Number);
  const luminance = color => {
    const values = numbers(color);
    if (values.length < 3) return -1;
    return values[0] * 0.2126 + values[1] * 0.7152 + values[2] * 0.0722;
  };
  return {
    active: document.body.classList.contains("is-manmatic-active") || document.body.dataset.siteTheme === "manmatic",
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
  Assert-State ($dark.rowBackgroundLight -ge 0 -and $dark.rowBackgroundLight -lt 30 -and $dark.themeColor.ToLower() -eq '#0a0a0a') 'The ManMaTIC field or browser theme color is not dark.'
  Assert-State ($dark.readingLight -gt 150) 'Completed reading text did not adapt to the globally inverted theme.'

  $null = Evaluate 'window.scrollBy(0, 24); true'
  Start-Sleep -Milliseconds 180
  Assert-State ([bool](Evaluate 'document.body.classList.contains("is-manmatic-active") || document.body.dataset.siteTheme === "manmatic"')) 'The ManMaTIC state flickered inside its active range.'

  Center-Element '.project-row[data-project-index="03"]'
  Wait-For '!document.body.classList.contains("is-manmatic-active") && document.body.dataset.siteTheme !== "manmatic" && document.querySelector("meta[name=theme-color]").content.toLowerCase() === "#ffffff"' 'The page did not leave the ManMaTIC state.' 50
  Start-Sleep -Milliseconds 1050
  $light = Evaluate-Json @'
JSON.stringify((() => {
  const bodyStyle = getComputedStyle(document.body);
  const htmlStyle = getComputedStyle(document.documentElement);
  const numbers = color => (color.match(/[\d.]+/g) || []).map(Number);
  const luminance = color => {
    const values = numbers(color);
    return values.length >= 3 ? values[0] * 0.2126 + values[1] * 0.7152 + values[2] * 0.0722 : -1;
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
    textOverflow: texts.some(text => text.scrollWidth > text.clientWidth + 2 && text.clientWidth > 0),
    codeVisible: visible(code),
    noteVisible: visible(note),
    ruleWidth: rule ? rule.getBoundingClientRect().width : parseFloat(pseudo.width) || 0,
    ruleTransform: rule ? getComputedStyle(rule).transform : pseudo.transform,
    scanning: container.classList.contains("is-heading-scanning")
  };
})())
"@
  Assert-State ($state.texts -gt 0 -and -not $state.textOverflow -and -not $state.scanning) ("Heading is clipped, overflowing, or still scanning: {0}." -f $label)
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
    @{ Selector = '#visual-studies .section-heading'; Label = 'Visual Studies' },
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
  Wait-For "innerWidth === $width && innerHeight === $height" ("Viewport metrics did not settle for {0} at {1}." -f $label, $viewport.Name) 40
  $null = Evaluate 'document.documentElement.style.scrollBehavior = "auto"; window.scrollTo(0, 0); true'
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
  const projectImages = Array.from(document.querySelectorAll(".project-row__media img, .project-hero img"));
  return {
    width: innerWidth,
    height: innerHeight,
    rootScrollWidth: document.documentElement.scrollWidth,
    bodyScrollWidth: document.body.scrollWidth,
    bodyScrollHeight: document.body.scrollHeight,
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
    }).length,
    loaderHidden: Boolean(document.getElementById("loader")?.hidden)
  };
})())
'@
  Assert-State ($state.width -eq $width -and $state.height -eq $height) ("Browser viewport mismatch for {0} at {1}." -f $label, $viewport.Name)
  Assert-State ($state.rootScrollWidth -le ($width + 1) -and $state.bodyScrollWidth -le ($width + 1)) ("Horizontal overflow for {0} at {1}: root {2}, body {3}, viewport {4}." -f $label, $viewport.Name, $state.rootScrollWidth, $state.bodyScrollWidth, $width)
  Assert-State (@($state.boundsViolations).Count -eq 0) ("Key layout bounds leave the viewport for {0} at {1}: {2}." -f $label, $viewport.Name, (@($state.boundsViolations) -join ', '))
  Assert-State (@($state.headingOverflow).Count -eq 0) ("A heading clips or overflows for {0} at {1}: {2}." -f $label, $viewport.Name, (@($state.headingOverflow) -join ', '))
  Assert-State (@($state.emailOverflow).Count -eq 0) ("An email address overflows for {0} at {1}." -f $label, $viewport.Name)
  Assert-State ($state.bodyScrollHeight -gt $height -and $state.loaderHidden -and -not $state.menuOpen) ("The page is clipped, loading, or menu-locked for {0} at {1}." -f $label, $viewport.Name)
  Assert-State ($state.badProjectImages -eq 0) ("A project image has no layout box for {0} at {1}." -f $label, $viewport.Name)

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

function Assert-MobileInteractions {
  Set-Viewport $phoneViewport
  Wait-For 'innerWidth === 390 && innerHeight === 844' 'Mobile interaction viewport did not settle.' 40
  Assert-ReadingProgression
  $null = Evaluate 'document.documentElement.style.scrollBehavior = "auto"; window.scrollTo(0, 0); true'
  Start-Sleep -Milliseconds 100
  $null = Evaluate 'document.getElementById("nav-toggle").click(); true'
  Wait-For 'document.getElementById("nav-toggle").getAttribute("aria-expanded") === "true" && document.body.classList.contains("menu-open") && document.getElementById("primary-navigation").getAttribute("aria-hidden") === "false"' 'The mobile menu did not open accessibly.' 30
  $null = Evaluate 'document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true })); true'
  Wait-For 'document.getElementById("nav-toggle").getAttribute("aria-expanded") === "false" && !document.body.classList.contains("menu-open") && document.getElementById("primary-navigation").getAttribute("aria-hidden") === "true"' 'The mobile menu did not close on Escape.' 30

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
  Wait-For 'document.querySelector("[data-visual-current]").textContent.trim() === "02"' 'The Visual Studies touch swipe did not advance.' 30
  $null = Evaluate 'document.querySelector("[data-visual-prev]").click(); true'
  Wait-For 'document.querySelector("[data-visual-current]").textContent.trim() === "01"' 'The Visual Studies slider did not reset after touch testing.' 30
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
  const bodyStyle = getComputedStyle(document.body);
  const htmlStyle = getComputedStyle(document.documentElement);
  const values = color => (color.match(/[\d.]+/g) || []).map(Number);
  const luminance = color => {
    const rgb = values(color);
    return rgb.length >= 3 ? rgb[0] * 0.2126 + rgb[1] * 0.7152 + rgb[2] * 0.0722 : -1;
  };
  return {
    slug: document.body.dataset.project || "",
    theme: document.body.dataset.siteTheme || "",
    headerTheme: header?.dataset.projectTheme || "",
    number: (header?.querySelector(".project-header__eyebrow")?.textContent.match(/\d{2}/) || [""])[0],
    title: header?.querySelector("h1")?.getAttribute("aria-label") || "",
    dataTitle: project?.navigationTitle || project?.title || "",
    h1Count: document.querySelectorAll("main h1").length,
    headerCount: document.querySelectorAll(".project-header").length,
    heroCount: document.querySelectorAll(".project-hero").length,
    heroComplete: Boolean(image?.complete && image.naturalWidth > 0 && image.naturalHeight > 0),
    heroLocal: image ? !/^https?:/i.test(image.getAttribute("src") || "") : false,
    heroVisible: image ? image.getBoundingClientRect().width > 40 && image.getBoundingClientRect().height > 24 && getComputedStyle(image).visibility !== "hidden" : false,
    overview: document.querySelectorAll(".project-copy-section").length,
    frameworkPoints: document.querySelectorAll(".project-logic-list li").length,
    navigation: links.length,
    navHrefs: links.map(link => link.getAttribute("href") || ""),
    bodyLight: luminance(bodyStyle.backgroundColor),
    textLight: luminance(bodyStyle.color),
    htmlLight: luminance(htmlStyle.backgroundColor),
    scrollWidth: document.documentElement.scrollWidth,
    clientWidth: document.documentElement.clientWidth,
    fieldLink: Boolean(document.querySelector(".project-header__field-link"))
  };
})())
'@
  Assert-State ($state.slug -eq $slug -and $state.h1Count -eq 1 -and $state.headerCount -eq 1) ("Project identity structure is invalid: {0}." -f $slug)
  Assert-State ($state.number -eq $number.Substring(1, 2) -and -not [string]::IsNullOrWhiteSpace([string]$state.title) -and $state.title -eq $state.dataTitle) ("Project number or title does not match central data: {0}." -f $slug)
  Assert-State ($state.heroCount -eq 1 -and $state.heroComplete -and $state.heroLocal -and $state.heroVisible) ("Project hero is missing, remote, unloaded, or invisible: {0}." -f $slug)
  Assert-State ($state.overview -ge 2 -and $state.frameworkPoints -ge 1) ("Project overview/framework is incomplete: {0}." -f $slug)
  Assert-State ($state.navigation -eq 2) ("Project previous/next navigation is incomplete: {0}." -f $slug)
  Assert-State ((@($state.navHrefs) -join ',') -eq ("project.html?project={0},project.html?project={1}" -f $previousSlug, $nextSlug)) ("Project navigation order is invalid: {0}." -f $slug)
  Assert-State ($state.scrollWidth -le ($state.clientWidth + 1)) ("Project route has horizontal overflow: {0}." -f $slug)

  if ($slug -eq 'project-01') {
    Assert-State ($state.theme -eq 'manmatic' -and $state.headerTheme -eq 'manmatic' -and $state.bodyLight -lt 30 -and $state.htmlLight -lt 30 -and $state.textLight -gt 180 -and $state.fieldLink) 'The ManMaTIC project route is not fully inverted by default.'
  } else {
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
  Assert-HomeStructure
  Assert-No-PageErrors 'initial homepage load'

  Clear-CdpEvents
  Reload-Page
  $refreshProbe = Assert-LoaderCycle 'refreshed homepage loader'
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

  Assert-ProjectRoutes
  Assert-ReducedMotion

  Write-Output ("verification`tPASS`tassertions={0}`tviewports={1}`tprojects={2}" -f $script:assertionCount, $viewports.Count, $expectedSlugs.Count)
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
