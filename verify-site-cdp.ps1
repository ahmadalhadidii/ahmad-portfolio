$ErrorActionPreference = 'Stop'

$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$outDir = Join-Path $env:TEMP 'ahmad-portfolio-editorial-check'
$runId = Get-Date -Format 'yyyyMMdd-HHmmssfff'
$profile = Join-Path $outDir ("profile-$runId")
$homeUrl = ([System.Uri]::new((Resolve-Path '.\index.html').Path)).AbsoluteUri
$projectBaseUrl = ([System.Uri]::new((Resolve-Path '.\project.html').Path)).AbsoluteUri
$viewports = @(
  @{ Name = '1920x1080'; Width = 1920; Height = 1080; Mobile = $false },
  @{ Name = '1440x900'; Width = 1440; Height = 900; Mobile = $false },
  @{ Name = '1366x768'; Width = 1366; Height = 768; Mobile = $false },
  @{ Name = '1024x768'; Width = 1024; Height = 768; Mobile = $false },
  @{ Name = '768x1024'; Width = 768; Height = 1024; Mobile = $true },
  @{ Name = '430x932'; Width = 430; Height = 932; Mobile = $true },
  @{ Name = '390x844'; Width = 390; Height = 844; Mobile = $true },
  @{ Name = '360x800'; Width = 360; Height = 800; Mobile = $true }
)

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

function Set-Viewport($viewport) {
  $null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{
    width = [int]$viewport.Width
    height = [int]$viewport.Height
    deviceScaleFactor = 1
    mobile = [bool]$viewport.Mobile
    screenWidth = [int]$viewport.Width
    screenHeight = [int]$viewport.Height
  }
}

function Save-FullScreenshot([string]$name) {
  $layout = Invoke-Cdp 'Page.getLayoutMetrics'
  $content = $layout.cssContentSize
  $height = [Math]::Min([double]$content.height, 30000)
  $path = Join-Path $outDir ("$runId-$name.png")
  $result = Invoke-Cdp 'Page.captureScreenshot' @{
    format = 'png'
    fromSurface = $true
    captureBeyondViewport = $true
    clip = @{
      x = 0
      y = 0
      width = [double]$content.width
      height = $height
      scale = 1
    }
  }
  [System.IO.File]::WriteAllBytes($path, [System.Convert]::FromBase64String($result.data))
  return $path
}

function Save-ViewportScreenshot([string]$name) {
  $path = Join-Path $outDir ("$runId-$name.png")
  $result = Invoke-Cdp 'Page.captureScreenshot' @{
    format = 'png'
    fromSurface = $true
    captureBeyondViewport = $false
  }
  [System.IO.File]::WriteAllBytes($path, [System.Convert]::FromBase64String($result.data))
  return $path
}

function Assert-State([bool]$condition, [string]$message) {
  if (-not $condition) { throw $message }
}

function Home-State {
  $expression = @'
(function () {
  function query(selector) { return document.querySelector(selector); }
  function rect(element) {
    if (!element) return null;
    var value = element.getBoundingClientRect();
    return { left: value.left, top: value.top, right: value.right, bottom: value.bottom, width: value.width, height: value.height };
  }
  function style(element) { return element ? getComputedStyle(element) : null; }
  function pixels(value) { var parsed = parseFloat(value); return Number.isFinite(parsed) ? parsed : 0; }
  function lineCount(element) {
    if (!element) return 0;
    var range = document.createRange();
    range.selectNodeContents(element);
    var tops = [];
    Array.from(range.getClientRects()).filter(function (item) {
      return item.width > 1 && item.height > 1;
    }).forEach(function (item) {
      if (!tops.some(function (top) { return Math.abs(top - item.top) < 2; })) tops.push(item.top);
    });
    return tops.length;
  }
  function normalizedText(element) {
    return element ? (element.innerText || element.textContent || "").replace(/\s+/g, " ").trim() : "";
  }
  function precedes(first, second) {
    return !!(first && second && (first.compareDocumentPosition(second) & Node.DOCUMENT_POSITION_FOLLOWING));
  }
  function transformScale(element) {
    if (!element) return 0;
    var transform = style(element).transform;
    if (!transform || transform === "none") return 1;
    try {
      var matrix = new DOMMatrixReadOnly(transform);
      return Math.max(Math.hypot(matrix.a, matrix.b), Math.hypot(matrix.c, matrix.d));
    } catch (error) {
      return 99;
    }
  }

  var opening = query(".opening");
  var identity = query(".opening__identity");
  var monitor = query("[data-broadcast-monitor]");
  var screen = query("[data-monitor-screen]");
  var concept = query(".opening__concept");
  var firstBoard = query("[data-opening-board]");
  var title = query(".manifesto__title");
  var manifesto = query(".manifesto__text");
  var profile = query(".profile__statement");
  var marker = query("[data-section-marker]");
  var markerHeading = marker ? marker.querySelector("h2") : null;
  var contactName = query(".contact__name");
  var contactStatement = query(".contact__statement");
  var contactBand = query(".contact__band");
  var titleStyle = style(title);
  var manifestoStyle = style(manifesto);
  var profileStyle = style(profile);
  var markerStyle = style(markerHeading);
  var nameStyle = style(contactName);
  var statementStyle = style(contactStatement);
  var openingRect = rect(opening);
  var monitorRect = rect(monitor);
  var screenRect = rect(screen);
  var boardStyle = style(firstBoard);
  var researchWord = Array.from(document.querySelectorAll(".profile__statement .reading-word")).find(function (word) {
    return (word.textContent || "").toLowerCase() === "research-based";
  });
  var rowElements = Array.from(document.querySelectorAll(".project-row"));
  var projects = window.siteContent && Array.isArray(window.siteContent.projects) ? window.siteContent.projects : [];
  var sectionDimensions = ["profile", "cv", "work", "contact"].map(function (id) {
    var element = document.getElementById(id);
    var computed = style(element);
    return { id: id, minHeight: pixels(computed && computed.minHeight), height: computed ? computed.height : "" };
  });
  var markerRect = rect(markerHeading);
  var nameRect = rect(contactName);
  var statementRect = rect(contactStatement);
  var bandRect = rect(contactBand);
  var headerRect = rect(query(".site-header"));
  var boardRect = rect(firstBoard);

  return JSON.stringify({
    width: innerWidth,
    height: innerHeight,
    scrollWidth: document.documentElement.scrollWidth,
    clientWidth: document.documentElement.clientWidth,
    bodyBackground: style(document.body).backgroundColor,
    bodyColor: style(document.body).color,
    siteTheme: document.body.dataset.siteTheme || "",
    h1Count: document.querySelectorAll("main h1").length,
    rows: rowElements.length,
    validRows: document.querySelectorAll('.project-row__link[href^="project.html?project=project-"]').length,
    navLabels: Array.from(document.querySelectorAll(".site-nav a")).map(function (link) { return (link.dataset.sectionLink || "").toUpperCase(); }),
    badLinks: document.querySelectorAll('a[href="#"]').length,
    brokenInternalLinks: Array.from(document.querySelectorAll('a[href^="#"]')).filter(function (link) { return !document.querySelector(link.getAttribute("href")); }).length,
    duplicateIds: Array.from(document.querySelectorAll("[id]")).map(function (item) { return item.id; }).filter(function (id, index, ids) { return ids.indexOf(id) !== index; }).length,
    emptyLinks: Array.from(document.querySelectorAll("a")).filter(function (link) { return !(link.textContent || "").trim() && !link.getAttribute("aria-label"); }).length,
    ratings: document.querySelectorAll('.rating[aria-label*="out of 5"]').length,
    firstEmail: !!query('a[href="mailto:ahmadalhadidii@manmatic.institute"]'),
    secondEmail: !!query('a[href="mailto:alhadidiahamd@gmail.com"]'),
    phone: !!query('a[href="tel:+962790652697"]'),
    linkedIn: !!query('a[href="https://www.linkedin.com/in/ahmad-alhadidii-97b796290/"]'),
    instagram: !!query('a[href="https://www.instagram.com/ahmad.alhadidii/"]'),
    themeColor: query('meta[name="theme-color"]') ? query('meta[name="theme-color"]').getAttribute("content") : "",
    menuExpanded: query("#nav-toggle") ? query("#nav-toggle").getAttribute("aria-expanded") : "",
    sectionDimensions: sectionDimensions,
    monitor: {
      count: document.querySelectorAll("[data-broadcast-monitor]").length,
      screenCount: document.querySelectorAll("[data-monitor-screen]").length,
      width: monitorRect ? monitorRect.width : 0,
      widthRatio: monitorRect && openingRect ? monitorRect.width / openingRect.width : 0,
      screenRatio: screenRect && screenRect.height ? screenRect.width / screenRect.height : 0,
      slideCount: document.querySelectorAll("[data-showreel-slide]").length,
      activeSlides: document.querySelectorAll("[data-showreel-slide].is-active").length,
      localImages: Array.from(document.querySelectorAll("[data-showreel-slide] img")).every(function (image) {
        return !/^https?:/i.test(image.getAttribute("src") || "");
      }),
      toggle: !!query("[data-showreel-toggle]"),
      toggleIsButton: !!query("button[data-showreel-toggle]"),
      described: !!(monitor && monitor.getAttribute("aria-describedby") && document.getElementById(monitor.getAttribute("aria-describedby"))),
      order: precedes(identity, monitor) && precedes(monitor, concept)
    },
    openingImage: {
      complete: !!(firstBoard && firstBoard.complete && firstBoard.naturalWidth > 0 && firstBoard.naturalHeight > 0),
      naturalRatio: firstBoard && firstBoard.naturalHeight ? firstBoard.naturalWidth / firstBoard.naturalHeight : 0,
      objectFit: boardStyle ? boardStyle.objectFit : "",
      objectPosition: boardStyle ? boardStyle.objectPosition : "",
      transformScale: transformScale(firstBoard),
      belowHeader: !!(boardRect && headerRect && boardRect.top >= headerRect.bottom - 1)
    },
    typography: {
      titleSize: pixels(titleStyle && titleStyle.fontSize),
      titleLines: lineCount(title),
      titleWidthRatio: rect(title) && openingRect ? rect(title).width / openingRect.width : 0,
      titleHasBreak: !!(title && title.querySelector("br")),
      manifestoSize: pixels(manifestoStyle && manifestoStyle.fontSize),
      manifestoLines: lineCount(manifesto),
      manifestoWidthRatio: rect(manifesto) && openingRect ? rect(manifesto).width / openingRect.width : 0,
      manifestoLineHeight: manifestoStyle ? pixels(manifestoStyle.lineHeight) / Math.max(1, pixels(manifestoStyle.fontSize)) : 0,
      profileSize: pixels(profileStyle && profileStyle.fontSize),
      profileWidthRatio: rect(profile) && rect(document.getElementById("profile")) ? rect(profile).width / rect(document.getElementById("profile")).width : 0,
      profileHyphens: profileStyle ? profileStyle.hyphens : "",
      profileOverflowWrap: profileStyle ? profileStyle.overflowWrap : "",
      profileWordBreak: profileStyle ? profileStyle.wordBreak : "",
      researchWordLines: researchWord ? lineCount(researchWord) : 1,
      projectTitleMax: Math.max.apply(null, [0].concat(Array.from(document.querySelectorAll(".project-row__copy h3")).map(function (heading) { return pixels(style(heading).fontSize); })))
    },
    projectOrder: {
      dataSlugs: projects.map(function (project) { return project.slug; }),
      dataNumbers: projects.map(function (project) { return project.number; }),
      rowIds: rowElements.map(function (row) { return row.dataset.projectId || ""; }),
      rowNumbers: rowElements.map(function (row) { return normalizedText(row.querySelector(".project-row__number")); }),
      rowHrefs: rowElements.map(function (row) { var link = row.querySelector(".project-row__link"); return link ? link.getAttribute("href") : ""; }),
      firstText: normalizedText(rowElements[0]),
      secondText: normalizedText(rowElements[1])
    },
    contact: {
      markerCount: document.querySelectorAll("[data-section-marker]").length,
      markerText: normalizedText(markerHeading).replace(/\s*\/\s*/, " / "),
      markerSize: pixels(markerStyle && markerStyle.fontSize),
      markerFont: markerStyle ? markerStyle.fontFamily : "",
      markerDisplay: markerStyle ? markerStyle.display : "",
      markerAlign: markerStyle ? markerStyle.alignItems : "",
      hasDisconnectedHeading: !!query("#contact .section-heading"),
      leftMarkerName: markerRect && nameRect ? Math.abs(markerRect.left - nameRect.left) : 999,
      leftNameStatement: nameRect && statementRect ? Math.abs(nameRect.left - statementRect.left) : 999,
      leftStatementBand: statementRect && bandRect ? Math.abs(statementRect.left - bandRect.left) : 999,
      markerNameGap: markerRect && nameRect ? nameRect.top - markerRect.bottom : 999,
      nameStatementGap: nameRect && statementRect ? statementRect.top - nameRect.bottom : 999,
      statementBandGap: statementRect && bandRect ? bandRect.top - statementRect.bottom : 999,
      nameSize: pixels(nameStyle && nameStyle.fontSize),
      nameLines: lineCount(contactName),
      nameLineHeight: nameStyle ? pixels(nameStyle.lineHeight) / Math.max(1, pixels(nameStyle.fontSize)) : 0,
      statementSize: pixels(statementStyle && statementStyle.fontSize),
      statementLineHeight: statementStyle ? pixels(statementStyle.lineHeight) / Math.max(1, pixels(statementStyle.fontSize)) : 0,
      statementWidth: statementRect ? statementRect.width : 0,
      bandColumns: contactBand ? style(contactBand).gridTemplateColumns : ""
    }
  });
})()
'@
  return (Evaluate $expression) | ConvertFrom-Json
}

function Theme-State {
  $expression = @'
JSON.stringify({
  theme: document.body.dataset.siteTheme || "",
  background: getComputedStyle(document.body).backgroundColor,
  color: getComputedStyle(document.body).color,
  themeLine: getComputedStyle(document.body).getPropertyValue("--theme-line").trim().toLowerCase(),
  headerColor: getComputedStyle(document.querySelector(".site-header__name")).color,
  headerBorder: getComputedStyle(document.querySelector(".site-header")).borderBottomColor,
  runningHeader: (document.getElementById("running-header-text") || {}).textContent || "",
  themeColor: document.querySelector('meta[name="theme-color"]') ? document.querySelector('meta[name="theme-color"]').getAttribute("content") : ""
})
'@
  return (Evaluate $expression) | ConvertFrom-Json
}

function Center-Element([string]$selector) {
  $escaped = $selector.Replace('\', '\\').Replace('"', '\"')
  $null = Evaluate ('(function(){var element=document.querySelector("' + $escaped + '");if(!element)return false;document.documentElement.style.scrollBehavior="auto";var rect=element.getBoundingClientRect();window.scrollTo(0,window.scrollY+rect.top-(window.innerHeight-rect.height)/2);return true;})()')
}

function Reduced-Motion-State {
  $expression = @'
(function () {
  function visibleReveal(item) {
    var crop = item.querySelector(".image-frame__crop") || item;
    var computed = getComputedStyle(crop);
    return parseFloat(computed.opacity || "1") >= 0.99 &&
      (computed.clipPath === "none" || /inset\((0(px)?\s*){4}\)/.test(computed.clipPath)) &&
      (computed.transform === "none" || computed.transform === "matrix(1, 0, 0, 1, 0, 0)");
  }
  var active = document.querySelector("[data-showreel-slide].is-active");
  var loader = document.getElementById("loader");
  return JSON.stringify({
    loaderSkipped: !document.documentElement.classList.contains("loader-pending") && (!loader || loader.hidden || getComputedStyle(loader).display === "none" || getComputedStyle(loader).visibility === "hidden"),
    activeFrame: active ? active.getAttribute("data-frame") : "",
    activeSlides: document.querySelectorAll("[data-showreel-slide].is-active").length,
    videosPaused: Array.from(document.querySelectorAll("video")).every(function (video) { return video.paused; }),
    revealsVisible: Array.from(document.querySelectorAll("[data-image-reveal]")).every(visibleReveal),
    revealStates: Array.from(document.querySelectorAll("[data-image-reveal]")).map(function (item) {
      var crop = item.querySelector(".image-frame__crop") || item;
      var computed = getComputedStyle(crop);
      return { opacity: computed.opacity, clip: computed.clipPath, transform: computed.transform, visible: visibleReveal(item) };
    }),
    runningAnimations: document.getAnimations().filter(function (animation) { return animation.playState === "running"; }).length,
    readingFullyDark: Array.from(document.querySelectorAll(".reading-word")).every(function (word) {
      return getComputedStyle(word).color === getComputedStyle(document.body).color;
    }),
    smoothScrollDisabled: getComputedStyle(document.documentElement).scrollBehavior === "auto"
  });
})()
'@
  return (Evaluate $expression) | ConvertFrom-Json
}

function Project-State {
  $expression = @'
(function () {
  var hero = document.querySelector(".project-hero__media img");
  var links = Array.from(document.querySelectorAll(".project-navigation__link"));
  return JSON.stringify({
    title: document.title,
    key: document.body.dataset.project || null,
    siteTheme: document.body.dataset.siteTheme || "",
    h1Count: document.querySelectorAll("main h1").length,
    header: document.querySelectorAll(".project-header").length,
    hero: document.querySelectorAll(".project-hero__media img").length,
    heroComplete: !!(hero && hero.complete && hero.naturalWidth > 0),
    heroFit: hero ? getComputedStyle(hero).objectFit : "",
    overview: document.querySelectorAll(".project-copy-section").length,
    navigation: links.length,
    navHrefs: links.map(function (link) { return link.getAttribute("href") || ""; }),
    navTitles: links.map(function (link) { return (link.textContent || "").replace(/\s+/g, " ").trim(); }),
    badLinks: document.querySelectorAll('a[href="#"]').length,
    background: getComputedStyle(document.body).backgroundColor,
    color: getComputedStyle(document.body).color,
    themeLine: getComputedStyle(document.body).getPropertyValue("--theme-line").trim().toLowerCase(),
    scrollWidth: document.documentElement.scrollWidth,
    clientWidth: document.documentElement.clientWidth
  });
})()
'@
  return (Evaluate $expression) | ConvertFrom-Json
}

try {
  $null = Invoke-Cdp 'Page.enable'
  $null = Invoke-Cdp 'Runtime.enable'
  $null = Invoke-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{
    source = @'
(function () {
  var audit = window.__portfolioLoaderAudit = { pendingAt: null, releasedAt: null };
  var timer = 0;
  function visuallyReleased(loader) {
    if (!loader || loader.hidden) return true;
    var computed = getComputedStyle(loader);
    return computed.display === "none" || computed.visibility === "hidden" || parseFloat(computed.opacity || "1") < 0.02;
  }
  function check() {
    var root = document.documentElement;
    if (!root) return;
    var pending = root.classList.contains("loader-pending");
    if (pending && audit.pendingAt === null) audit.pendingAt = performance.now();
    if (audit.pendingAt !== null && !pending && visuallyReleased(document.getElementById("loader"))) {
      audit.releasedAt = performance.now();
      if (timer) window.clearInterval(timer);
    }
  }
  timer = window.setInterval(check, 8);
  window.setTimeout(function () {
    if (timer) window.clearInterval(timer);
  }, 2500);
  document.addEventListener("DOMContentLoaded", check, { once: true });
  check();
})()
'@
  }
  $null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{
    features = @(@{ name = 'prefers-reduced-motion'; value = 'no-preference' })
  }

  Set-Viewport $viewports[1]
  Navigate $homeUrl
  Wait-For 'document.querySelectorAll(".project-row").length === 5' 'Homepage content did not become ready.'
  $null = Evaluate 'sessionStorage.clear(); true'
  Navigate $homeUrl
  Wait-For 'document.querySelectorAll(".project-row").length === 5' 'First-session homepage did not become ready.'
  $loaderStarted = [bool](Evaluate 'document.documentElement.classList.contains("loader-pending")')
  $loaderShot = Save-ViewportScreenshot 'loader-1440x900'
  $loaderReleaseAt = 9999.0
  for ($loaderPoll = 0; $loaderPoll -lt 90; $loaderPoll++) {
    $loaderSample = (Evaluate @'
JSON.stringify({
  now: performance.now(),
  pending: document.documentElement.classList.contains("loader-pending"),
  pendingAt: window.__portfolioLoaderAudit ? window.__portfolioLoaderAudit.pendingAt : null,
  releasedAt: window.__portfolioLoaderAudit ? window.__portfolioLoaderAudit.releasedAt : null,
  visuallyReleased: (function () {
    var loader = document.getElementById("loader");
    if (!loader || loader.hidden) return true;
    var computed = getComputedStyle(loader);
    return computed.display === "none" || computed.visibility === "hidden" || parseFloat(computed.opacity || "1") < 0.02;
  })()
})
'@) | ConvertFrom-Json
    if (-not $loaderSample.pending -and $loaderSample.visuallyReleased -and $null -ne $loaderSample.pendingAt -and $null -ne $loaderSample.releasedAt) {
      $loaderReleaseAt = [double]$loaderSample.releasedAt - [double]$loaderSample.pendingAt
      break
    }
    Start-Sleep -Milliseconds 20
  }
  $firstLoaderReleased = $loaderReleaseAt -le 1425
  Navigate $homeUrl
  Start-Sleep -Milliseconds 120
  $repeatLoaderSkipped = [bool](Evaluate @'
(function () {
  var loader = document.getElementById("loader");
  return !document.documentElement.classList.contains("loader-pending") &&
    (!loader || loader.hidden || getComputedStyle(loader).display === "none" || getComputedStyle(loader).visibility === "hidden");
})()
'@)

  Assert-State $loaderStarted 'The first-session monitor activation did not start.'
  Assert-State $firstLoaderReleased ("The monitor activation remained visible beyond 1.4 seconds ({0:N0}ms)." -f $loaderReleaseAt)
  Assert-State $repeatLoaderSkipped 'The loader replayed in the same browser session.'

  Wait-For 'document.querySelectorAll("[data-showreel-slide]").length >= 5' 'The fallback showreel was not available.'
  $showreelInitialFrame = [string](Evaluate '(document.querySelector("[data-showreel-slide].is-active") || {}).dataset.frame || ""')
  $showreelAdvanced = $false
  for ($framePoll = 0; $framePoll -lt 10; $framePoll++) {
    Start-Sleep -Milliseconds 450
    $currentFrame = [string](Evaluate '(document.querySelector("[data-showreel-slide].is-active") || {}).dataset.frame || ""')
    if ($currentFrame -and $currentFrame -ne $showreelInitialFrame) {
      $showreelAdvanced = $true
      break
    }
  }
  Assert-State $showreelAdvanced 'The fallback showreel did not advance within 4.5 seconds.'
  $null = Evaluate 'document.querySelector("[data-showreel-toggle]").click(); true'
  Start-Sleep -Milliseconds 100
  $pausedFrame = [string](Evaluate '(document.querySelector("[data-showreel-slide].is-active") || {}).dataset.frame || ""')
  $pauseState = [bool](Evaluate 'document.querySelector("[data-showreel-toggle]").getAttribute("aria-pressed") === "true"')
  Start-Sleep -Milliseconds 4200
  $pausedFrameAfterWait = [string](Evaluate '(document.querySelector("[data-showreel-slide].is-active") || {}).dataset.frame || ""')
  Assert-State ($pauseState -and $pausedFrame -eq $pausedFrameAfterWait) 'The showreel pause control did not stop the continuing motion.'
  $null = Evaluate 'document.querySelector("[data-showreel-toggle]").click(); true'

  $null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{
    features = @(@{ name = 'prefers-reduced-motion'; value = 'reduce' })
  }
  $null = Evaluate 'sessionStorage.clear(); true'
  Navigate $homeUrl
  Wait-For 'document.querySelectorAll(".project-row").length === 5' 'Reduced-motion homepage did not render.'
  Start-Sleep -Milliseconds 180
  $reducedStateBefore = Reduced-Motion-State
  $reducedShot = Save-ViewportScreenshot 'reduced-motion-1440x900'
  Start-Sleep -Milliseconds 3300
  $reducedStateAfter = Reduced-Motion-State
  Write-Output ("REDUCED_STATE " + ($reducedStateBefore | ConvertTo-Json -Compress))
  $reducedLoaderSkipped = [bool]$reducedStateBefore.loaderSkipped
  Assert-State $reducedLoaderSkipped 'Reduced-motion mode did not skip the loader.'
  Assert-State ($reducedStateBefore.activeSlides -eq 1 -and $reducedStateBefore.activeFrame -eq $reducedStateAfter.activeFrame) 'Reduced-motion mode did not keep a static showreel frame.'
  Assert-State ($reducedStateBefore.videosPaused -and $reducedStateBefore.revealsVisible) 'Reduced-motion media or image reveals are still moving or hidden.'
  Assert-State ($reducedStateBefore.runningAnimations -eq 0 -and $reducedStateBefore.smoothScrollDisabled) 'Reduced-motion CSS still exposes ongoing animation or smooth scrolling.'

  $null = Invoke-Cdp 'Emulation.setScriptExecutionDisabled' @{ value = $true }
  Navigate $homeUrl
  $noScriptState = (Evaluate @'
JSON.stringify({
  h1: document.querySelectorAll("main h1").length,
  rows: document.querySelectorAll(".project-row").length,
  monitor: document.querySelectorAll("[data-broadcast-monitor]").length,
  slides: document.querySelectorAll("[data-showreel-slide]").length,
  cv: document.body.innerText.includes("Architectural Intern") && document.body.innerText.includes("Training Guide for Dialogue & Volunteer Clubs"),
  contact: !!document.querySelector('a[href="tel:+962790652697"]'),
  loaderHidden: getComputedStyle(document.getElementById("loader")).display === "none"
})
'@) | ConvertFrom-Json
  Assert-State ($noScriptState.h1 -eq 1 -and $noScriptState.rows -eq 5 -and $noScriptState.monitor -eq 1 -and $noScriptState.slides -ge 5 -and $noScriptState.cv -and $noScriptState.contact -and $noScriptState.loaderHidden) 'The no-script homepage is incomplete.'
  $null = Invoke-Cdp 'Emulation.setScriptExecutionDisabled' @{ value = $false }

  $null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{
    features = @(@{ name = 'prefers-reduced-motion'; value = 'no-preference' })
  }
  $null = Evaluate 'sessionStorage.setItem("portfolio:monitor-boot:v1", "1"); true'

  $expectedSlugs = @('project-05', 'project-01', 'project-02', 'project-03', 'project-04')
  $expectedNumbers = @('001', '002', '003', '004', '005')
  $expectedHrefs = $expectedSlugs | ForEach-Object { "project.html?project=$_" }
  $typeBounds = @{
    '1920x1080' = @{ TitleMin = 58; TitleMax = 77; TitleLines = 1; ManifestoMin = 24; ManifestoMax = 32.5; ManifestoLinesMin = 2; ManifestoLinesMax = 4; ProfileMin = 32; ProfileMax = 48.5 }
    '1440x900'  = @{ TitleMin = 48; TitleMax = 63; TitleLines = 1; ManifestoMin = 21; ManifestoMax = 28; ManifestoLinesMin = 2; ManifestoLinesMax = 5; ProfileMin = 30; ProfileMax = 43 }
    '1366x768'  = @{ TitleMin = 47; TitleMax = 63; TitleLines = 1; ManifestoMin = 20.5; ManifestoMax = 28; ManifestoLinesMin = 2; ManifestoLinesMax = 5; ProfileMin = 30; ProfileMax = 43 }
    '1024x768'  = @{ TitleMin = 42; TitleMax = 54; TitleLines = 2; ManifestoMin = 18; ManifestoMax = 25; ManifestoLinesMin = 3; ManifestoLinesMax = 6; ProfileMin = 25; ProfileMax = 38 }
    '768x1024'  = @{ TitleMin = 38; TitleMax = 50; TitleLines = 2; ManifestoMin = 17.5; ManifestoMax = 23; ManifestoLinesMin = 3; ManifestoLinesMax = 7; ProfileMin = 24; ProfileMax = 34 }
    '430x932'   = @{ TitleMin = 37.5; TitleMax = 47; TitleLines = 2; ManifestoMin = 17.5; ManifestoMax = 22; ManifestoLinesMin = 5; ManifestoLinesMax = 11; ProfileMin = 24; ProfileMax = 33 }
    '390x844'   = @{ TitleMin = 37.5; TitleMax = 47; TitleLines = 2; ManifestoMin = 17.5; ManifestoMax = 22; ManifestoLinesMin = 5; ManifestoLinesMax = 12; ProfileMin = 24; ProfileMax = 33 }
    '360x800'   = @{ TitleMin = 37.5; TitleMax = 47; TitleLines = 2; ManifestoMin = 17.5; ManifestoMax = 22; ManifestoLinesMin = 5; ManifestoLinesMax = 13; ProfileMin = 24; ProfileMax = 33 }
  }

  $viewportResults = @()
  foreach ($viewport in $viewports) {
    Set-Viewport $viewport
    Navigate $homeUrl
    Wait-For 'document.querySelectorAll(".project-row").length === 5' ("Homepage did not render at {0}." -f $viewport.Name)
    Start-Sleep -Milliseconds 1100
    $state = Home-State
    $bounds = $typeBounds[$viewport.Name]
    Write-Output ("TYPE_STATE " + $viewport.Name + " " + ($state.typography | ConvertTo-Json -Compress))

    Assert-State ($state.scrollWidth -le ($state.clientWidth + 1)) ("Horizontal overflow at {0}." -f $viewport.Name)
    Assert-State ($state.bodyBackground -eq 'rgb(255, 255, 255)') ("Body background is not white at {0}." -f $viewport.Name)
    Assert-State ($state.siteTheme -eq 'light') ("Homepage did not start in the light theme at {0}." -f $viewport.Name)
    Assert-State ($state.h1Count -eq 1) ("Homepage heading count is invalid at {0}." -f $viewport.Name)
    Assert-State ($state.rows -eq 5 -and $state.validRows -eq 5) ("Project index is invalid at {0}." -f $viewport.Name)
    Assert-State ($state.badLinks -eq 0) ("An empty fragment link exists at {0}." -f $viewport.Name)
    Assert-State ($state.brokenInternalLinks -eq 0) ("An internal section link is broken at {0}." -f $viewport.Name)
    Assert-State ($state.duplicateIds -eq 0 -and $state.emptyLinks -eq 0) ("Duplicate IDs or empty links exist at {0}." -f $viewport.Name)
    Assert-State ($state.ratings -eq 11) ("Accessible proficiency labels are incomplete at {0}." -f $viewport.Name)
    Assert-State ($state.firstEmail -and $state.secondEmail -and $state.phone -and $state.linkedIn -and $state.instagram) ("Contact links are incomplete at {0}." -f $viewport.Name)
    Assert-State ($state.themeColor -eq '#ffffff') ("The browser theme color is not white at {0}." -f $viewport.Name)
    Assert-State (($state.navLabels -join ',') -eq 'INDEX,PROFILE,CV,WORK,CONTACT') ("Navigation order is invalid at {0}." -f $viewport.Name)

    Assert-State ($state.monitor.count -eq 1 -and $state.monitor.screenCount -eq 1 -and $state.monitor.order) ("Monitor composition or document order is invalid at {0}." -f $viewport.Name)
    Assert-State ($state.monitor.slideCount -ge 5 -and $state.monitor.slideCount -le 8 -and $state.monitor.activeSlides -eq 1 -and $state.monitor.localImages) ("Fallback showreel frames are invalid at {0}." -f $viewport.Name)
    Assert-State ($state.monitor.toggle -and $state.monitor.toggleIsButton -and $state.monitor.described) ("Monitor controls or accessible description are incomplete at {0}." -f $viewport.Name)
    Assert-State ($state.monitor.screenRatio -ge 1.5 -and $state.monitor.screenRatio -le 1.85) ("Monitor screen ratio is outside the architectural broadcast range at {0}." -f $viewport.Name)
    if ($viewport.Width -ge 1024) {
      Assert-State ($state.monitor.widthRatio -ge 0.75 -and $state.monitor.widthRatio -le 0.94 -and $state.monitor.width -le 1642) ("Desktop monitor scale is outside the requested range at {0}." -f $viewport.Name)
    } else {
      Assert-State ($state.monitor.widthRatio -ge 0.88 -and $state.monitor.widthRatio -le 1.01) ("Mobile monitor does not use the available page width at {0}." -f $viewport.Name)
    }

    Assert-State ($state.openingImage.complete -and $state.openingImage.objectFit -eq 'contain') ("The opening board is missing or cropped at {0}." -f $viewport.Name)
    Assert-State ($state.openingImage.transformScale -le 1.002 -and $state.openingImage.belowHeader) ("The opening board is scaled or hidden beneath the header at {0}." -f $viewport.Name)

    Assert-State ($state.typography.titleSize -ge $bounds.TitleMin -and $state.typography.titleSize -le $bounds.TitleMax -and $state.typography.titleLines -le $bounds.TitleLines -and -not $state.typography.titleHasBreak) ("Architecture of Elsewhere typography is out of bounds at {0}." -f $viewport.Name)
    Assert-State ($state.typography.manifestoSize -ge $bounds.ManifestoMin -and $state.typography.manifestoSize -le $bounds.ManifestoMax -and $state.typography.manifestoLines -ge $bounds.ManifestoLinesMin -and $state.typography.manifestoLines -le $bounds.ManifestoLinesMax) ("Manifesto typography or line count is out of bounds at {0}." -f $viewport.Name)
    Assert-State ($state.typography.manifestoLineHeight -ge 1.2 -and $state.typography.manifestoLineHeight -le 1.42) ("Manifesto line height is invalid at {0}." -f $viewport.Name)
    Assert-State ($state.typography.profileSize -ge $bounds.ProfileMin -and $state.typography.profileSize -le $bounds.ProfileMax) ("Profile statement scale is invalid at {0}." -f $viewport.Name)
    Assert-State ($state.typography.profileHyphens -eq 'none' -and $state.typography.profileOverflowWrap -eq 'normal' -and $state.typography.profileWordBreak -eq 'normal' -and $state.typography.researchWordLines -eq 1) ("Profile words can split or hyphenate incorrectly at {0}." -f $viewport.Name)
    Assert-State ($state.typography.projectTitleMax -le 52.5) ("A project title exceeds the requested scale at {0}." -f $viewport.Name)
    if ($viewport.Width -ge 1024) {
      Assert-State ($state.typography.titleWidthRatio -ge 0.75 -and $state.typography.manifestoWidthRatio -ge 0.64 -and $state.typography.profileWidthRatio -ge 0.58) ("Editorial text columns are too narrow at {0}." -f $viewport.Name)
    }

    Assert-State (($state.projectOrder.dataSlugs -join ',') -eq ($expectedSlugs -join ',')) ("Central project data order is invalid at {0}." -f $viewport.Name)
    Assert-State (($state.projectOrder.dataNumbers -join ',') -eq ($expectedNumbers -join ',')) ("Central project numbering is invalid at {0}." -f $viewport.Name)
    Assert-State (($state.projectOrder.rowIds -join ',') -eq ($expectedSlugs -join ',') -and ($state.projectOrder.rowNumbers -join ',') -eq ($expectedNumbers -join ',') -and ($state.projectOrder.rowHrefs -join ',') -eq ($expectedHrefs -join ',')) ("Homepage project rows do not match central data at {0}." -f $viewport.Name)
    Assert-State ($state.projectOrder.firstText.ToUpper().Contains('SHILA MUSEUM') -and $state.projectOrder.firstText.ToUpper().Contains('THE QUARRY THAT FOLDS INWARD')) ("Shila is not project file 01 at {0}." -f $viewport.Name)
    Assert-State ($state.projectOrder.secondText.ToUpper().Contains('MANMATIC') -and $state.projectOrder.secondText.ToUpper().Contains('INTEGRATION INSTITUTE')) ("ManMaTIC is not project file 02 at {0}." -f $viewport.Name)

    Assert-State (-not ($state.sectionDimensions | Where-Object { $_.minHeight -ge ($viewport.Height * 0.9) })) ("A content section still behaves like a viewport-height slide at {0}." -f $viewport.Name)
    Assert-State ($state.contact.markerCount -eq 1 -and $state.contact.markerText -eq '04 / CONTACT' -and -not $state.contact.hasDisconnectedHeading) ("Contact marker is not the unified 04 / CONTACT heading at {0}." -f $viewport.Name)
    Assert-State ($state.contact.markerSize -ge 12 -and $state.contact.markerSize -le 14.5 -and $state.contact.markerFont.ToLower().Contains('plex mono') -and $state.contact.markerAlign -eq 'baseline') ("Contact marker typography or baseline is invalid at {0}." -f $viewport.Name)
    Assert-State ($state.contact.leftMarkerName -le 2.5 -and $state.contact.leftNameStatement -le 2.5 -and $state.contact.leftStatementBand -le 2.5) ("Contact elements do not share one primary edge at {0}." -f $viewport.Name)
    Assert-State ($state.contact.nameSize -ge ($(if ($viewport.Width -ge 1024) { 44 } else { 28 })) -and $state.contact.nameSize -le 105 -and $state.contact.nameLineHeight -ge 0.88 -and $state.contact.nameLineHeight -le 1.05) ("Contact name typography is invalid at {0}." -f $viewport.Name)
    Assert-State ($state.contact.statementSize -ge 20 -and $state.contact.statementSize -le 41 -and $state.contact.statementLineHeight -ge 1.2 -and $state.contact.statementLineHeight -le 1.42 -and $state.contact.statementWidth -le 1205) ("Contact statement typography is invalid at {0}." -f $viewport.Name)
    if ($viewport.Width -ge 1024) {
      Assert-State ($state.contact.nameLines -eq 1) ("Contact name should remain on one desktop line at {0}." -f $viewport.Name)
      Assert-State ($state.contact.markerNameGap -ge 32 -and $state.contact.markerNameGap -le 90 -and $state.contact.nameStatementGap -ge 16 -and $state.contact.nameStatementGap -le 48 -and $state.contact.statementBandGap -ge 30 -and $state.contact.statementBandGap -le 84) ("Contact vertical rhythm is invalid at {0}." -f $viewport.Name)
      Assert-State ($state.contact.bandColumns -ne 'none' -and $state.contact.bandColumns.Contains(' ')) ("Contact information band is not two-column at {0}." -f $viewport.Name)
    }

    $topShot = Save-ViewportScreenshot ("opening-{0}" -f $viewport.Name)

    Center-Element '[data-project-theme="manmatic"]'
    Wait-For 'document.body.dataset.siteTheme === "manmatic"' ("ManMaTIC theme did not activate at {0}." -f $viewport.Name)
    Start-Sleep -Milliseconds 1050
    $manmaticTheme = Theme-State
    Write-Output ("THEME_STATE " + $viewport.Name + " " + ($manmaticTheme | ConvertTo-Json -Compress))
    Assert-State ($manmaticTheme.background -eq 'rgb(10, 10, 10)' -and $manmaticTheme.color -eq 'rgb(242, 242, 242)' -and $manmaticTheme.themeLine -eq '#2a2a2a') ("ManMaTIC colors did not settle correctly at {0}." -f $viewport.Name)
    Assert-State ($manmaticTheme.headerColor -eq 'rgb(242, 242, 242)') ("Header colors did not adapt to ManMaTIC at {0}." -f $viewport.Name)
    $manmaticShot = Save-ViewportScreenshot ("manmatic-{0}" -f $viewport.Name)
    $null = Evaluate 'window.scrollBy(0, 24); true'
    Start-Sleep -Milliseconds 240
    Assert-State ([bool](Evaluate 'document.body.dataset.siteTheme === "manmatic"')) ("ManMaTIC theme flickered near its active range at {0}." -f $viewport.Name)

    Center-Element '.project-row[data-project-index="03"]'
    Wait-For 'document.body.dataset.siteTheme === "light"' ("Theme did not leave ManMaTIC at {0}." -f $viewport.Name)
    Start-Sleep -Milliseconds 1050
    $afterTheme = Theme-State
    Assert-State ($afterTheme.background -eq 'rgb(255, 255, 255)' -and $afterTheme.color -eq 'rgb(17, 17, 17)') ("Theme did not return to white after ManMaTIC at {0}." -f $viewport.Name)
    $afterThemeShot = Save-ViewportScreenshot ("after-manmatic-{0}" -f $viewport.Name)

    Center-Element '#contact'
    Start-Sleep -Milliseconds 180
    $contactShot = Save-ViewportScreenshot ("contact-{0}" -f $viewport.Name)

    $null = Evaluate 'document.querySelectorAll("[data-image-reveal]").forEach(function (item) { item.classList.add("is-visible"); }); true'
    Start-Sleep -Milliseconds 80
    $null = Evaluate 'window.scrollTo(0, 0); true'
    Start-Sleep -Milliseconds 80
    $shot = Save-FullScreenshot ("home-{0}" -f $viewport.Name)
    $viewportResults += [PSCustomObject]@{
      Viewport = $viewport.Name
      State = $state
      Theme = $manmaticTheme
      AfterTheme = $afterTheme
      Screenshot = $shot
      OpeningScreenshot = $topShot
      ManmaticScreenshot = $manmaticShot
      AfterManmaticScreenshot = $afterThemeShot
      ContactScreenshot = $contactShot
    }
  }

  Set-Viewport $viewports[6]
  Navigate $homeUrl
  Wait-For 'document.querySelectorAll(".project-row").length === 5' 'Mobile homepage did not render.'
  $null = Evaluate 'document.getElementById("nav-toggle").click(); true'
  Start-Sleep -Milliseconds 100
  $menuOpen = [bool](Evaluate 'document.getElementById("nav-toggle").getAttribute("aria-expanded") === "true" && document.body.classList.contains("menu-open")')
  Start-Sleep -Milliseconds 650
  $menuShot = Save-ViewportScreenshot 'mobile-menu-390x844'
  $null = Evaluate 'document.dispatchEvent(new KeyboardEvent("keydown", {key:"Escape", bubbles:true})); true'
  Start-Sleep -Milliseconds 80
  $menuClosed = [bool](Evaluate 'document.getElementById("nav-toggle").getAttribute("aria-expanded") === "false" && !document.body.classList.contains("menu-open")')
  Assert-State $menuOpen 'The mobile menu did not open accessibly.'
  Assert-State $menuClosed 'The mobile menu did not close on Escape.'

  Set-Viewport $viewports[1]
  Navigate $homeUrl
  Wait-For 'document.querySelectorAll(".project-row").length === 5' 'Print target did not render.'
  $null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{ media = 'print' }
  $printState = [bool](Evaluate 'getComputedStyle(document.getElementById("cv")).display !== "none" && getComputedStyle(document.getElementById("work")).display === "none" && getComputedStyle(document.querySelector(".site-header")).display === "none"')
  Assert-State $printState 'The CV print view does not isolate the CV.'
  $null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{
    media = 'screen'
    features = @(@{ name = 'prefers-reduced-motion'; value = 'no-preference' })
  }

  Set-Viewport $viewports[1]
  $projectResults = @()
  for ($index = 0; $index -lt $expectedSlugs.Count; $index++) {
    $key = $expectedSlugs[$index]
    $previousKey = $expectedSlugs[($index - 1 + $expectedSlugs.Count) % $expectedSlugs.Count]
    $nextKey = $expectedSlugs[($index + 1) % $expectedSlugs.Count]
    Navigate ($projectBaseUrl + "?project=$key")
    Wait-For 'document.querySelectorAll(".project-header").length === 1' ("Project did not render: {0}." -f $key)
    Start-Sleep -Milliseconds 1050
    $state = Project-State
    Assert-State ($state.key -eq $key) ("Wrong project resolved for {0}." -f $key)
    Assert-State ($state.h1Count -eq 1 -and $state.header -eq 1 -and $state.hero -eq 1 -and $state.heroComplete -and $state.heroFit -eq 'contain') ("Project structure or uncropped hero is incomplete for {0}." -f $key)
    Assert-State ($state.navigation -eq 2 -and $state.badLinks -eq 0) ("Project navigation is invalid for {0}." -f $key)
    Assert-State ($state.navHrefs[0] -eq "project.html?project=$previousKey" -and $state.navHrefs[1] -eq "project.html?project=$nextKey") ("Previous/next order is invalid for {0}." -f $key)
    if ($key -eq 'project-01') {
      Assert-State ($state.siteTheme -eq 'manmatic' -and $state.background -eq 'rgb(10, 10, 10)' -and $state.color -eq 'rgb(242, 242, 242)' -and $state.themeLine -eq '#2a2a2a') 'The ManMaTIC detail page is not dark by default.'
    } else {
      Assert-State ($state.siteTheme -eq 'light' -and $state.background -eq 'rgb(255, 255, 255)') ("A non-ManMaTIC project is not light: {0}." -f $key)
    }
    Assert-State ($state.scrollWidth -le ($state.clientWidth + 1)) ("Project has horizontal overflow: {0}." -f $key)
    $projectResults += [PSCustomObject]@{ Project = $key; State = $state }
  }

  Navigate ($projectBaseUrl + '?project=missing')
  Wait-For 'document.querySelectorAll(".project-detail__error").length === 1' 'Invalid-project state did not render.'
  $invalidHeading = Evaluate 'document.querySelector(".project-detail__error h1").textContent'
  Assert-State ($invalidHeading -eq 'PROJECT NOT FOUND') 'Invalid-project heading is incorrect.'

  Navigate ($projectBaseUrl + '?project=project-01')
  Wait-For 'document.querySelectorAll(".project-header").length === 1' 'Project screenshot target did not render.'
  Start-Sleep -Milliseconds 1100
  $projectShot = Save-FullScreenshot 'manmatic-project-1440x900'

  Set-Viewport $viewports[6]
  Navigate ($projectBaseUrl + '?project=project-01')
  Wait-For 'document.querySelectorAll(".project-header").length === 1' 'Mobile ManMaTIC project did not render.'
  Start-Sleep -Milliseconds 1050
  $mobileProjectState = Project-State
  Assert-State ($mobileProjectState.scrollWidth -le ($mobileProjectState.clientWidth + 1) -and $mobileProjectState.siteTheme -eq 'manmatic' -and $mobileProjectState.background -eq 'rgb(10, 10, 10)') 'The mobile ManMaTIC detail state is invalid.'
  $mobileProjectShot = Save-FullScreenshot 'manmatic-project-390x844'

  Write-Output ("loader`t{0}" -f (@{
    started = $loaderStarted
    firstReleased = $firstLoaderReleased
    releaseAtMs = $loaderReleaseAt
    repeatSkipped = $repeatLoaderSkipped
    reducedSkipped = $reducedLoaderSkipped
  } | ConvertTo-Json -Compress))
  Write-Output ("loader-screenshot`t{0}" -f $loaderShot)
  Write-Output ("reduced-motion-screenshot`t{0}" -f $reducedShot)
  Write-Output ("no-script`t{0}" -f ($noScriptState | ConvertTo-Json -Compress))
  Write-Output ("print`t{0}" -f (@{ cvOnly = $printState } | ConvertTo-Json -Compress))

  foreach ($result in $viewportResults) {
    Write-Output ("viewport`t{0}`t{1}`t{2}" -f $result.Viewport, ($result.State | ConvertTo-Json -Depth 12 -Compress), $result.Screenshot)
    Write-Output ("captures`t{0}`t{1}`t{2}`t{3}`t{4}" -f $result.Viewport, $result.OpeningScreenshot, $result.ManmaticScreenshot, $result.AfterManmaticScreenshot, $result.ContactScreenshot)
  }

  foreach ($result in $projectResults) {
    Write-Output ("project`t{0}`t{1}" -f $result.Project, ($result.State | ConvertTo-Json -Depth 8 -Compress))
  }

  Write-Output ("mobile-menu`t{0}" -f (@{ opened = $menuOpen; closed = $menuClosed } | ConvertTo-Json -Compress))
  Write-Output ("mobile-menu-screenshot`t{0}" -f $menuShot)
  Write-Output ("project-screenshot`t{0}" -f $projectShot)
  Write-Output ("mobile-project-screenshot`t{0}" -f $mobileProjectShot)
  Write-Output 'verification`tPASS'
}
finally {
  try { $null = Invoke-Cdp 'Browser.close' } catch {}
  try { $ws.Dispose() } catch {}
  if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
}
