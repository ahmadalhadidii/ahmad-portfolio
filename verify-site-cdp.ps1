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
  $null = Evaluate ("(function(){var element=document.querySelector(\"{0}\");if(!element)return false;var rect=element.getBoundingClientRect();window.scrollTo(0,window.scrollY+rect.top-(window.innerHeight-rect.height)/2);return true;})()" -f $escaped)
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
  $null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{
    features = @(@{ name = 'prefers-reduced-motion'; value = 'no-preference' })
  }

  Set-Viewport $viewports[1]
  Navigate $homeUrl
  Wait-For 'document.querySelectorAll(".project-row").length === 5' 'Homepage content did not become ready.'
  $null = Evaluate 'sessionStorage.removeItem("portfolio:intro:editorial-v1"); true'
  Navigate $homeUrl
  Wait-For 'document.querySelectorAll(".project-row").length === 5' 'First-session homepage did not become ready.'
  $firstLoaderBlocking = [bool](Evaluate 'document.documentElement.classList.contains("loader-pending")')
  $loaderShot = Save-ViewportScreenshot 'loader-1440x900'
  Start-Sleep -Milliseconds 2180
  $firstLoaderReleased = -not [bool](Evaluate 'document.documentElement.classList.contains("loader-pending")')
  Navigate $homeUrl
  Start-Sleep -Milliseconds 120
  $repeatLoaderSkipped = -not [bool](Evaluate 'document.documentElement.classList.contains("loader-pending")')

  Assert-State $firstLoaderBlocking 'The first-session loader did not start.'
  Assert-State $firstLoaderReleased 'The loader remained blocking beyond its hard release.'
  Assert-State $repeatLoaderSkipped 'The loader replayed in the same browser session.'

  $null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{
    features = @(@{ name = 'prefers-reduced-motion'; value = 'reduce' })
  }
  $null = Evaluate 'sessionStorage.removeItem("portfolio:intro:editorial-v1"); true'
  Navigate $homeUrl
  Start-Sleep -Milliseconds 120
  $reducedLoaderSkipped = -not [bool](Evaluate 'document.documentElement.classList.contains("loader-pending")')
  Assert-State $reducedLoaderSkipped 'Reduced-motion mode did not skip the loader.'

  $null = Invoke-Cdp 'Emulation.setScriptExecutionDisabled' @{ value = $true }
  Navigate $homeUrl
  $noScriptState = (Evaluate @'
JSON.stringify({
  h1: document.querySelectorAll("main h1").length,
  rows: document.querySelectorAll(".project-row").length,
  cv: document.body.innerText.includes("Architectural Intern") && document.body.innerText.includes("Training Guide for Dialogue & Volunteer Clubs"),
  contact: !!document.querySelector('a[href="tel:+962790652697"]'),
  loaderHidden: getComputedStyle(document.getElementById("loader")).display === "none"
})
'@) | ConvertFrom-Json
  Assert-State ($noScriptState.h1 -eq 1 -and $noScriptState.rows -eq 5 -and $noScriptState.cv -and $noScriptState.contact -and $noScriptState.loaderHidden) 'The no-script homepage is incomplete.'
  $null = Invoke-Cdp 'Emulation.setScriptExecutionDisabled' @{ value = $false }

  $null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{
    features = @(@{ name = 'prefers-reduced-motion'; value = 'no-preference' })
  }
  $null = Evaluate 'sessionStorage.setItem("portfolio:intro:editorial-v1", "1"); true'

  $viewportResults = @()
  foreach ($viewport in $viewports) {
    Set-Viewport $viewport
    Navigate $homeUrl
    Wait-For 'document.querySelectorAll(".project-row").length === 5' ("Homepage did not render at {0}." -f $viewport.Name)
    Start-Sleep -Milliseconds 950
    $state = Home-State

    Assert-State ($state.scrollWidth -le $state.clientWidth) ("Horizontal overflow at {0}." -f $viewport.Name)
    Assert-State ($state.bodyBackground -eq 'rgb(255, 255, 255)') ("Body background is not white at {0}." -f $viewport.Name)
    Assert-State ($state.mainBackground -eq 'rgb(255, 255, 255)') ("Main background is not white at {0}." -f $viewport.Name)
    Assert-State (-not ($state.sectionBackgrounds | Where-Object { $_ -ne 'rgb(255, 255, 255)' })) ("A section background is not white at {0}." -f $viewport.Name)
    Assert-State ($state.h1Count -eq 1) ("Homepage heading count is invalid at {0}." -f $viewport.Name)
    Assert-State ($state.rows -eq 5 -and $state.validRows -eq 5) ("Project index is invalid at {0}." -f $viewport.Name)
    Assert-State ($state.badLinks -eq 0) ("An empty fragment link exists at {0}." -f $viewport.Name)
    Assert-State ($state.brokenInternalLinks -eq 0) ("An internal section link is broken at {0}." -f $viewport.Name)
    Assert-State ($state.duplicateIds -eq 0 -and $state.emptyLinks -eq 0) ("Duplicate IDs or empty links exist at {0}." -f $viewport.Name)
    Assert-State ($state.ratings -eq 11) ("Accessible proficiency labels are incomplete at {0}." -f $viewport.Name)
    Assert-State ($state.firstEmail -and $state.secondEmail -and $state.phone -and $state.linkedIn -and $state.instagram) ("Contact links are incomplete at {0}." -f $viewport.Name)
    Assert-State ($state.manifestoBelowImage) ("The manifesto is not directly below the opening image at {0}." -f $viewport.Name)
    Assert-State ($state.themeColor -eq '#ffffff') ("The browser theme color is not white at {0}." -f $viewport.Name)
    Assert-State (($state.navLabels -join ',') -eq 'INDEX,PROFILE,CV,WORK,CONTACT') ("Navigation order is invalid at {0}." -f $viewport.Name)

    $null = Evaluate 'document.querySelectorAll("[data-image-reveal]").forEach(function (item) { item.classList.add("is-visible"); }); true'
    Start-Sleep -Milliseconds 1050
    $null = Evaluate 'window.scrollTo(0, 0); true'
    Start-Sleep -Milliseconds 80
    $shot = Save-FullScreenshot ("home-{0}" -f $viewport.Name)
    $viewportResults += [PSCustomObject]@{ Viewport = $viewport.Name; State = $state; Screenshot = $shot }

    if ($viewport.Name -eq '1440x900' -or $viewport.Name -eq '390x844') {
      $topShot = Save-ViewportScreenshot ("review-{0}-top" -f $viewport.Name)
      foreach ($sectionId in @('profile', 'cv', 'work', 'contact')) {
        $null = Evaluate ("document.documentElement.style.scrollBehavior='auto'; document.getElementById('{0}').scrollIntoView({{block:'start'}}); true" -f $sectionId)
        Start-Sleep -Milliseconds 760
        $sectionShot = Save-ViewportScreenshot ("review-{0}-{1}" -f $viewport.Name, $sectionId)
        Write-Output ("review`t{0}`t{1}`t{2}" -f $viewport.Name, $sectionId, $sectionShot)
      }
      Write-Output ("review`t{0}`ttop`t{1}" -f $viewport.Name, $topShot)
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
  for ($index = 1; $index -le 5; $index++) {
    $key = "project-{0:d2}" -f $index
    Navigate ($projectBaseUrl + "?project=$key")
    Wait-For 'document.querySelectorAll(".project-header").length === 1' ("Project did not render: {0}." -f $key)
    Start-Sleep -Milliseconds 1000
    $state = Project-State
    Assert-State ($state.key -eq $key) ("Wrong project resolved for {0}." -f $key)
    Assert-State ($state.h1Count -eq 1 -and $state.header -eq 1 -and $state.hero -eq 1) ("Project structure is incomplete for {0}." -f $key)
    Assert-State ($state.navigation -eq 2 -and $state.badLinks -eq 0) ("Project navigation is invalid for {0}." -f $key)
    Assert-State ($state.background -eq 'rgb(255, 255, 255)') ("Project background is not white for {0}." -f $key)
    Assert-State ($state.scrollWidth -le $state.clientWidth) ("Project has horizontal overflow: {0}." -f $key)
    $projectResults += [PSCustomObject]@{ Project = $key; State = $state }
  }

  Navigate ($projectBaseUrl + '?project=missing')
  Wait-For 'document.querySelectorAll(".project-detail__error").length === 1' 'Invalid-project state did not render.'
  $invalidHeading = Evaluate 'document.querySelector(".project-detail__error h1").textContent'
  Assert-State ($invalidHeading -eq 'PROJECT NOT FOUND') 'Invalid-project heading is incorrect.'

  Navigate ($projectBaseUrl + '?project=project-01')
  Wait-For 'document.querySelectorAll(".project-header").length === 1' 'Project screenshot target did not render.'
  Start-Sleep -Milliseconds 1100
  $projectShot = Save-FullScreenshot 'project-01-1440x900'

  Set-Viewport $viewports[6]
  Navigate ($projectBaseUrl + '?project=project-01')
  Wait-For 'document.querySelectorAll(".project-header").length === 1' 'Mobile project did not render.'
  Start-Sleep -Milliseconds 1000
  $mobileProjectState = Project-State
  Assert-State ($mobileProjectState.scrollWidth -le $mobileProjectState.clientWidth) 'The mobile project has horizontal overflow.'
  $mobileProjectShot = Save-FullScreenshot 'project-01-390x844'

  Write-Output ("loader`t{0}" -f (@{
    firstBlocking = $firstLoaderBlocking
    firstReleased = $firstLoaderReleased
    repeatSkipped = $repeatLoaderSkipped
    reducedSkipped = $reducedLoaderSkipped
  } | ConvertTo-Json -Compress))
  Write-Output ("loader-screenshot`t{0}" -f $loaderShot)
  Write-Output ("no-script`t{0}" -f ($noScriptState | ConvertTo-Json -Compress))
  Write-Output ("print`t{0}" -f (@{ cvOnly = $printState } | ConvertTo-Json -Compress))

  foreach ($result in $viewportResults) {
    Write-Output ("viewport`t{0}`t{1}`t{2}" -f $result.Viewport, ($result.State | ConvertTo-Json -Compress), $result.Screenshot)
  }

  foreach ($result in $projectResults) {
    Write-Output ("project`t{0}`t{1}" -f $result.Project, ($result.State | ConvertTo-Json -Compress))
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
