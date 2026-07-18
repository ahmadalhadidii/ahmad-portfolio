param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$Root = [System.IO.Path]::GetFullPath($Root)
$CanonicalBase = 'https://www.ahmadalhadidii.manmatic.institute'
$Build = '20260718-responsive-media-protection-06'

function ConvertTo-HtmlEncoded([object]$Value) {
  return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Get-RootPath([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
  if ($Path -match '^(?:https?:)?//|^/') { return $Path }
  return '/' + $Path.TrimStart('.', '/')
}

function Get-RootSrcset([string]$Srcset) {
  if ([string]::IsNullOrWhiteSpace($Srcset)) { return '' }
  return (($Srcset -split ',') | ForEach-Object {
    $candidate = $_.Trim()
    if ($candidate -match '^(\S+)(.*)$') {
      (Get-RootPath $Matches[1]) + $Matches[2]
    }
  }) -join ', '
}

function Get-MetaDescription([string]$Description) {
  if ($Description.Length -le 158) { return $Description }
  $candidate = $Description.Substring(0, 155).TrimEnd()
  $lastSpace = $candidate.LastIndexOf(' ')
  if ($lastSpace -gt 115) { $candidate = $candidate.Substring(0, $lastSpace) }
  return $candidate.TrimEnd(' ', ',', ';', ':', '-') + '…'
}

function Get-EmphasizedHtml([string]$Text, [string]$Emphasis) {
  if ([string]::IsNullOrWhiteSpace($Emphasis)) { return ConvertTo-HtmlEncoded $Text }
  $index = $Text.IndexOf($Emphasis, [System.StringComparison]::Ordinal)
  if ($index -lt 0) { return ConvertTo-HtmlEncoded $Text }
  $before = ConvertTo-HtmlEncoded $Text.Substring(0, $index)
  $strong = ConvertTo-HtmlEncoded $Emphasis
  $after = ConvertTo-HtmlEncoded $Text.Substring($index + $Emphasis.Length)
  return "$before<strong>$strong</strong>$after"
}

$contentPath = Join-Path $Root 'content.js'
$source = Get-Content -Raw -Encoding utf8 -LiteralPath $contentPath
$visualMatch = [regex]::Match($source, '(?s)visuals:\s*(\[\s*\{.*?\}\s*\])\s*,\s*computations:')
if (-not $visualMatch.Success) { throw 'Unable to locate the Visual records in content.js.' }

$visualJson = [regex]::Replace(
  $visualMatch.Groups[1].Value,
  '(?m)^(\s*)([A-Za-z][A-Za-z0-9]*):',
  '$1"$2":'
)
$visuals = $visualJson | ConvertFrom-Json
if ($visuals.Count -eq 0) { throw 'No Visual records were found in content.js.' }

for ($index = 0; $index -lt $visuals.Count; $index++) {
  $visual = $visuals[$index]
  $previous = $visuals[($index - 1 + $visuals.Count) % $visuals.Count]
  $next = $visuals[($index + 1) % $visuals.Count]
  $route = "/visuals/$($visual.slug)/"
  $canonical = "$CanonicalBase$route"
  $title = "$($visual.title) | Ahmad Alhadidii"
  $metaDescription = Get-MetaDescription $visual.description
  $imagePath = Get-RootPath $visual.src
  $imageUrl = "$CanonicalBase$imagePath"
  $srcset = Get-RootSrcset $visual.srcset
  $orientation = if ($visual.orientation -match '^[a-z0-9_-]+$') { $visual.orientation } else { 'landscape' }
  $fit = if ($visual.fit -in @('contain', 'cover')) { $visual.fit } else { 'contain' }
  $recordCount = $visuals.Count.ToString('00')
  $descriptionHtml = Get-EmphasizedHtml $visual.description $visual.emphasis
  $contextHtml = if ([string]::IsNullOrWhiteSpace($visual.context)) { '' } else {
    "`n            <p class=`"visual-record__context`">$(ConvertTo-HtmlEncoded $visual.context)</p>"
  }
  $finalProcessHtml = if ([string]::IsNullOrWhiteSpace($visual.finalProcess)) { '' } else {
    "`n                <div><dt>FINAL PROCESS</dt><dd>$(ConvertTo-HtmlEncoded $visual.finalProcess)</dd></div>"
  }
  $style = if ([string]::IsNullOrWhiteSpace($visual.accent)) { '' } else {
    " style=`"--visual-accent: $(ConvertTo-HtmlEncoded $visual.accent)`""
  }
  $srcsetAttribute = if ([string]::IsNullOrWhiteSpace($srcset)) { '' } else {
    " srcset=`"$(ConvertTo-HtmlEncoded $srcset)`""
  }

  $structuredData = [ordered]@{
    '@context' = 'https://schema.org'
    '@type' = 'VisualArtwork'
    name = $visual.title
    headline = $visual.title
    description = $visual.description
    url = $canonical
    dateCreated = $visual.year
    creator = [ordered]@{
      '@type' = 'Person'
      name = 'Ahmad Alhadidii'
      url = "$CanonicalBase/"
    }
    image = [ordered]@{
      '@type' = 'ImageObject'
      url = $imageUrl
      width = [int]$visual.width
      height = [int]$visual.height
      caption = $visual.caption
      description = $visual.alt
    }
  }
  $jsonLd = ($structuredData | ConvertTo-Json -Depth 6 -Compress).Replace('</', '<\/')

  $loaderData = [ordered]@{
    number = $visual.index
    kicker = "VISUAL $($visual.index) / $recordCount"
    title = $visual.title
    subtitle = $visual.category
    type = 'VISUAL NARRATIVE'
    year = $visual.year
    location = ''
    theme = 'light'
    image = $imagePath
    srcset = $srcset
    objectPosition = if ($visual.objectPosition) { $visual.objectPosition } else { '50% 50%' }
  }
  $loaderJson = ($loaderData | ConvertTo-Json -Depth 4 -Compress).Replace('</', '<\/')

  $html = @"
<!doctype html>
<html lang="en" class="no-js" data-page="visual" data-site-theme="light" data-initial-theme="light" data-build="$Build">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="portfolio-build" content="$Build">
  <meta name="description" content="$(ConvertTo-HtmlEncoded $metaDescription)">
  <meta name="robots" content="index, follow, max-image-preview:large">
  <meta name="theme-color" content="#ffffff">

  <meta property="og:type" content="article">
  <meta property="og:title" content="$(ConvertTo-HtmlEncoded $title)">
  <meta property="og:description" content="$(ConvertTo-HtmlEncoded $metaDescription)">
  <meta property="og:url" content="$(ConvertTo-HtmlEncoded $canonical)">
  <meta property="og:image" content="$(ConvertTo-HtmlEncoded $imageUrl)">
  <meta property="og:image:alt" content="$(ConvertTo-HtmlEncoded $visual.alt)">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="$(ConvertTo-HtmlEncoded $title)">
  <meta name="twitter:description" content="$(ConvertTo-HtmlEncoded $metaDescription)">
  <meta name="twitter:image" content="$(ConvertTo-HtmlEncoded $imageUrl)">
  <meta name="twitter:image:alt" content="$(ConvertTo-HtmlEncoded $visual.alt)">

  <title>$(ConvertTo-HtmlEncoded $title)</title>
  <link rel="canonical" href="$(ConvertTo-HtmlEncoded $canonical)">
  <link rel="icon" type="image/png" sizes="16x16" href="/assets/icons/ad-mark-v1-16.png">
  <link rel="icon" type="image/png" sizes="32x32" href="/assets/icons/ad-mark-v1-32.png">
  <link rel="apple-touch-icon" sizes="180x180" href="/assets/icons/ad-mark-v1-180.png">
  <link rel="manifest" href="/site.webmanifest">
  <script type="application/ld+json">$jsonLd</script>

  <script src="/content.js?v=$Build"></script>
  <script>
    (function () {
      var root = document.documentElement;
      window.__portfolioDetailLoaderData = $loaderJson;
      root.classList.remove("no-js");
      root.classList.add("js", "loader-pending");
      window.__portfolioLoaderFallback = window.setTimeout(function () {
        if (!root.classList.contains("loader-pending")) return;
        var loader = document.getElementById("loader");
        root.classList.remove("loader-pending");
        root.classList.add("loader-complete", "motion-ready");
        if (loader) {
          loader.hidden = true;
          loader.setAttribute("aria-hidden", "true");
        }
      }, 3200);
    })();
  </script>

  <style>
    html, body, main { background: #ffffff; color: #111111; }
    .no-js .loader { display: none; }
  </style>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/assets/css/style.css?v=$Build">
  <script src="/assets/js/main.js?v=$Build" defer></script>
  <script src="/assets/js/visual.js?v=$Build" defer></script>
</head>
<body class="visual-page" data-visual-slug="$(ConvertTo-HtmlEncoded $visual.slug)">
  <div class="loader loader--project loader--visual" id="loader" role="status" aria-label="Opening $(ConvertTo-HtmlEncoded $visual.title)">
    <p class="visually-hidden" id="loader-announcement" aria-live="polite">$(ConvertTo-HtmlEncoded $visual.title) is opening.</p>
    <div class="project-loader" aria-hidden="true">
      <header class="project-loader__identity">
        <p class="project-loader__file" data-project-loader-kicker>VISUAL $($visual.index) / $recordCount</p>
        <h1 class="project-loader__title" id="loader-name">$(ConvertTo-HtmlEncoded $visual.title.ToUpperInvariant())</h1>
        <p class="project-loader__subtitle" data-project-loader-subtitle>$(ConvertTo-HtmlEncoded $visual.category.ToUpperInvariant())</p>
        <dl>
          <div><dt>YEAR</dt><dd data-project-loader-year>$(ConvertTo-HtmlEncoded $visual.year)</dd></div>
          <div><dt>TYPE</dt><dd data-project-loader-type>VISUAL NARRATIVE</dd></div>
          <div><dt>STATE</dt><dd id="loader-state">FILE INDEXING</dd></div>
        </dl>
      </header>
      <figure class="project-loader__visual">
        <div class="project-loader__image loader__preview-image">
          <img data-loader-preview src="$(ConvertTo-HtmlEncoded $imagePath)"$srcsetAttribute width="$($visual.width)" height="$($visual.height)" alt="">
          <span class="project-loader__scan"></span>
          <span class="project-loader__slice project-loader__slice--one"></span>
          <span class="project-loader__slice project-loader__slice--two"></span>
          <p class="project-loader__fallback" data-project-loader-fallback>VISUAL IMAGE UNAVAILABLE</p>
        </div>
        <figcaption><span data-project-loader-caption>VISUAL IMAGE</span><span>FRAME <b id="loader-frame">01 / 06</b> · SIGNAL <b id="loader-signal">000.000</b></span></figcaption>
      </figure>
      <footer class="project-loader__footer">
        <div class="project-loader__opening"><span>OPENING VISUAL</span><div class="project-loader__count"><strong id="loader-progress">000</strong><small>/ 100</small></div></div>
        <div class="loader__progress-track"><span id="loader-progress-bar"></span></div>
        <div class="project-loader__status"><p data-project-loader-status-type>VISUAL NARRATIVE</p><p id="loader-phase">FILE ACCESS</p><p><span id="loader-progress-secondary">000</span> / 100</p></div>
      </footer>
    </div>
  </div>

  <noscript><style>.loader, .nav-toggle { display: none !important; }</style></noscript>
  <a class="skip-link" href="#main-content">Skip to visual content</a>
  <div class="ambient-signal" aria-hidden="true"></div>
  <div class="material-texture" aria-hidden="true"></div>

  <div class="site-shell" id="site-shell">
    <header class="site-header" id="site-header">
      <div class="site-header__inner page-width">
        <a class="site-header__name" href="/" aria-label="Ahmad Alhadidii, return to portfolio index">AHMAD ALHADIDII</a>
        <p class="running-header" aria-hidden="true"><span id="running-header-text">VISUAL $($visual.index) / $(ConvertTo-HtmlEncoded $visual.title.ToUpperInvariant()) / $(ConvertTo-HtmlEncoded $visual.year)</span></p>
        <button class="nav-toggle" id="nav-toggle" type="button" aria-expanded="false" aria-controls="primary-navigation" aria-label="Open navigation"><span class="nav-toggle__open">MENU</span><span class="nav-toggle__close">CLOSE</span></button>
        <button class="nav-backdrop" type="button" data-nav-dismiss tabindex="-1" aria-label="Close navigation"></button>
        <nav class="site-nav" id="primary-navigation" aria-label="Primary navigation">
          <a href="/"><span data-scramble>INDEX</span></a>
          <a href="/#profile"><span data-scramble>PROFILE</span></a>
          <a href="/#cv"><span data-scramble>CV</span></a>
          <a href="/#work"><span data-scramble>WORK</span></a>
          <a href="/#computation"><span data-scramble>COMPUTATION</span></a>
          <a class="is-active" href="/#visual-studies" aria-current="location"><span data-scramble>VISUALS</span></a>
          <a href="/#contact"><span data-scramble>CONTACT</span></a>
          <a class="site-nav__external" href="https://www.manmatic.institute/" target="_blank" rel="noopener noreferrer" aria-label="Open the ManMaTIC Institute field website in a new tab">MANMATIC FIELD <span aria-hidden="true">↗</span></a>
        </nav>
      </div>
    </header>

    <main id="main-content" tabindex="-1">
      <article class="visual-detail" id="visual-detail">
        <section class="visual-record page-width orientation--$orientation" data-visual-id="$(ConvertTo-HtmlEncoded $visual.id)"$style>
          <header class="visual-record__header">
            <dl class="visual-record__meta">
              <div><dt>RECORD</dt><dd>VISUAL $($visual.index) / $recordCount</dd></div>
              <div><dt>CATEGORY</dt><dd>$(ConvertTo-HtmlEncoded $visual.category)</dd></div>
              <div><dt>YEAR</dt><dd>$(ConvertTo-HtmlEncoded $visual.year)</dd></div>
            </dl>
            <h1>$(ConvertTo-HtmlEncoded $visual.title)</h1>
          </header>
          <figure class="visual-record__media orientation--$orientation media--$fit" data-orientation="$orientation" data-media-fit="$fit" style="--media-ratio: $($visual.width) / $($visual.height)">
            <div class="visual-record__image-frame"><img src="$(ConvertTo-HtmlEncoded $imagePath)"$srcsetAttribute sizes="(max-width: 700px) calc(100vw - 36px), (max-width: 1100px) 58vw, min(980px, 62vw)" width="$($visual.width)" height="$($visual.height)" alt="$(ConvertTo-HtmlEncoded $visual.alt)" loading="eager" decoding="async" fetchpriority="high" draggable="false"></div>
            <figcaption>$(ConvertTo-HtmlEncoded $visual.caption)</figcaption>
          </figure>
          <div class="visual-record__narrative">
            <p class="visual-record__description">$descriptionHtml</p>$contextHtml
            <section class="visual-record__process">
              <h2>PROCESS RECORD</h2>
              <dl class="visual-record__process-meta">
                <div><dt>AUTHORSHIP</dt><dd>$(ConvertTo-HtmlEncoded $visual.authorship)</dd></div>
                <div><dt>PROCESS</dt><dd>$(ConvertTo-HtmlEncoded $visual.process)</dd></div>
                <div><dt>TOOLS</dt><dd>$(ConvertTo-HtmlEncoded $visual.tools)</dd></div>
                <div><dt>AI ROLE</dt><dd>$(ConvertTo-HtmlEncoded $visual.aiRole)</dd></div>$finalProcessHtml
              </dl>
            </section>
          </div>
          <nav class="visual-record__navigation" aria-label="Visual narrative navigation">
            <a class="visual-record__previous" href="/visuals/$(ConvertTo-HtmlEncoded $previous.slug)/" rel="prev" aria-label="Previous visual: $(ConvertTo-HtmlEncoded $previous.title)"><span>PREVIOUS VISUAL</span><strong>$(ConvertTo-HtmlEncoded $previous.title)</strong></a>
            <a class="visual-record__next" href="/visuals/$(ConvertTo-HtmlEncoded $next.slug)/" rel="next" aria-label="Next visual: $(ConvertTo-HtmlEncoded $next.title)"><span>NEXT VISUAL</span><strong>$(ConvertTo-HtmlEncoded $next.title)</strong></a>
            <a class="visual-record__all" href="/#visual-studies">ALL VISUALS ↗</a>
          </nav>
        </section>
      </article>
    </main>

    <footer class="site-footer page-width">
      <p>© 2026 AHMAD ALHADIDII</p>
      <p>AS-SALT, JORDAN</p>
      <a href="/#visual-studies">VISUAL INDEX <span aria-hidden="true">↗</span></a>
    </footer>
  </div>
</body>
</html>
"@

  $directory = Join-Path $Root ("visuals\" + $visual.slug)
  [System.IO.Directory]::CreateDirectory($directory) | Out-Null
  [System.IO.File]::WriteAllText(
    (Join-Path $directory 'index.html'),
    $html.TrimStart() + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false)
  )
}

Write-Output ("Generated {0} Visual pages." -f $visuals.Count)
