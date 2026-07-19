$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$CanonicalBase = 'https://www.ahmadalhadidii.manmatic.institute'
$Build = '20260718-responsive-media-protection-06'

function ConvertTo-HtmlEscaped([object]$Value) {
  if ($null -eq $Value) { return '' }
  return [System.Security.SecurityElement]::Escape([string]$Value)
}

$Projects = @(
  @{
    Slug='shila'; Route='projects/shila/'; Number='001'; Theme='light';
    Title='SHILA (STONE) MUSEUM'; Subtitle='THE QUARRY THAT FOLDS INWARD';
    SeoTitle='Shila Museum | Ahmad Alhadidii';
    Description='Shila Museum transforms Sadahalli Quarry into an inward-folding architectural journey through stone, water, shadow, geology, and spatial memory.';
    Definition='A museum concept where the quarry folds inward, turning stone, water, shadow, and void into spatial memory.';
    Overview='Shila (Stone) Museum explores stone as both material and meaning through an architectural journey carved into a quarry. The project transforms the quarry itself into the exhibition, guiding visitors through descending and ascending paths that reveal the relationship between earth, time, and memory.';
    Year='2025'; Location='Sadahalli Quarry / Bengaluru, India'; Type='Museum of Geology / Quarry Intervention'; Context='The Drawing Board 2025 / Echoes in Stone'; Role='Concept, site response, spatial narrative, design development, drawing, visual communication';
    Image='/assets/images/shilla.webp'; ImageWidth='2400'; ImageHeight='1293'; ImageAlt='Pale architectural drawing of Shila Museum around a reflective quarry pool, with layered stone volumes and a stair rising overhead.'; Caption='SHILA (STONE) MUSEUM / THE QUARRY THAT FOLDS INWARD / 2025';
    Keywords='Museum, stone, quarry intervention, architecture, spatial narrative';
  },
  @{
    Slug='manmatic'; Route='projects/manmatic/'; Number='002'; Theme='manmatic';
    Title='MANMATIC'; Subtitle='AN ARCHITECTURAL METHODOLOGY FOR HUMAN–MACHINE COLLABORATION';
    SeoTitle='ManMaTIC | Ahmad Alhadidii';
    Description='ManMaTIC is Ahmad Alhadidii''s human–machine collaboration research and design methodology, connecting an active knowledge field to Protocol Port as its architectural application.';
    Definition='An architectural methodology for translating changing human–machine collaboration into institutional and spatial systems.';
    Overview='ManMaTIC is an architectural research methodology developed to translate changing human–machine collaboration into institutional and spatial systems. It connects research, evaluation criteria, design dialogue, technological systems, and architectural application within one evolving framework.';
    Year='2026'; Location=''; Type='Architectural Research Methodology'; Context='Human–Machine Collaboration'; Role='Architecture, research, systems thinking, visual communication';
    Image='/assets/images/manmatic-field-interface-live.png'; ImageWidth='1600'; ImageHeight='1000'; ImageAlt='ManMaTIC knowledge field connecting research, criteria, design dialogue, and architectural application.'; Caption='MANMATIC / THE FIELD + PROTOCOL PORT / ACTIVE DEVELOPMENT';
    Keywords='ManMaTIC, human–machine collaboration, architectural research, design methodology';
    Extra=@'
<section class="project-copy-section project-expanded-section page-width" id="the-manmatic-field"><p class="project-copy-section__label">01 / RECORD</p><div class="project-copy-section__body"><h2>THE MANMATIC FIELD</h2><p>A project-specific knowledge environment that organises research, thesis logic, criteria, case studies, design dialogue, and outputs into a readable operating field.</p><dl class="project-facts"><div><dt>TYPE</dt><dd>Knowledge and Design Operating Environment</dd></div><div><dt>RELATION</dt><dd>Operational Field within ManMaTIC</dd></div></dl><div class="project-record-links"><a href="https://www.manmatic.institute/" target="_blank" rel="noopener noreferrer">ENTER LIVE MANMATIC FIELD ↗</a></div></div></section>
<section class="project-copy-section project-expanded-section page-width" id="protocol-port"><p class="project-copy-section__label">02 / RECORD</p><div class="project-copy-section__body"><h2>PROTOCOL PORT</h2><p>The first site-specific architectural application of the ManMaTIC methodology, translating its research, criteria, and design dialogue into a Human–Machine Collaboration Institute for Aqaba.</p><figure class="project-record-media"><img src="/assets/images/manmatic/protocol-port-001-1200.jpg" width="1200" height="743" alt="Protocol Port axonometric drawing across Aqaba's logistics landscape." loading="lazy" decoding="async"><figcaption>PROTOCOL PORT / APPLICATION 01 / MAIN AXONOMETRIC</figcaption></figure><dl class="project-facts"><div><dt>RELATION</dt><dd>First Architectural Application of ManMaTIC</dd></div><div><dt>FUNCTION</dt><dd>Human–Machine Collaboration Institute</dd></div><div><dt>LOCATION</dt><dd>Aqaba, Jordan</dd></div></dl><div class="project-record-links"><a href="/projects/protocol-port/">ENTER PROTOCOL PORT →</a></div></div></section>
'@
  },
  @{
    Slug='protocol-port'; Route='projects/protocol-port/'; Number='002.B'; Theme='manmatic';
    Title='PROTOCOL PORT'; Subtitle='FIRST ARCHITECTURAL APPLICATION OF THE MANMATIC FIELD';
    SeoTitle='Protocol Port | Ahmad Alhadidii';
    Description='Protocol Port is the site-specific Human–Machine Collaboration Institute developed in Aqaba as the first architectural application of the ManMaTIC methodology.';
    Definition='The first architectural application through which ManMaTIC criteria, decision protocols, and human–machine collaboration are tested spatially.';
    Overview='Protocol Port is the first site-specific architectural application of ManMaTIC. It translates the methodology''s research, evaluation criteria, and author-led design dialogue into a Human–Machine Collaboration Institute for Aqaba.';
    Year='2026'; Location='Aqaba Digital City / Middle Logistics Area / Aqaba, Jordan'; Type='Human–Machine Collaboration Institute'; Context='ManMaTIC / Architectural Application 01'; Role='Architecture, research, systems thinking, visual communication'; Relation='First Architectural Application of ManMaTIC';
    Image='/assets/images/manmatic/protocol-port-001-1200.jpg'; ImageWidth='1200'; ImageHeight='743'; ImageAlt='Protocol Port axonometric drawing across Aqaba''s logistics landscape.'; Caption='MANMATIC SYSTEM / PROTOCOL PORT / AQABA, JORDAN';
    Keywords='Protocol Port, ManMaTIC, human–machine collaboration, institute, Aqaba';
    Extra='<section class="project-copy-section page-width"><p class="project-copy-section__label">02 / SYSTEM LINK</p><div class="project-copy-section__body"><h2>Developed through ManMaTIC</h2><p>Protocol Port remains the architectural application of the ManMaTIC research and design methodology.</p><div class="project-record-links"><a href="/projects/manmatic/">BACK TO MANMATIC METHODOLOGY ←</a></div></div></section>'
  },
  @{
    Slug='dabouq'; Route='projects/dabouq/'; Number='003'; Theme='light';
    Title='DABOUQ RESIDENTIAL BUILDING'; Subtitle='PROFESSIONAL TRAINING PROJECT';
    SeoTitle='Dabouq Residential Building | Ahmad Alhadidii';
    Description='Dabouq Residential Building is a 2025 professional training project at BIM Lab involving architectural drawings, elevations, minor design modifications, and visual development under supervision.';
    Definition='A residential project developed during professional training at BIM Lab, contributing to architectural drawings, elevation development, minor design modifications, and visual development under supervision.';
    Overview='A residential project developed during professional training at BIM Lab, contributing to architectural drawings, elevation development, minor design modifications, and visual development under supervision.';
    Year='2025'; Location='Dabouq, Amman, Jordan'; Type='Residential Architecture'; Context='Professional Training'; Office='BIM Lab'; Role='Architectural drawings, elevation development, minor design modifications, and visual development under supervision.';
    Image='/assets/images/dabouq/dabouq-residential-preview.jpg'; ImageWidth='1600'; ImageHeight='1600'; ImageAlt='Architectural presentation drawing of a residential building developed during professional training at BIM Lab in Dabouq, Amman.'; Caption='RESIDENTIAL PROJECT / PROFESSIONAL TRAINING AT BIM LAB';
    Keywords='Dabouq residential building, BIM Lab, professional training, residential architecture';
  },
  @{
    Slug='concrete-fatigue'; Route='projects/concrete-fatigue/'; Number='004'; Theme='light';
    Title='FROM CONCRETE FATIGUE TO GREEN ASSET'; Subtitle='1ST PLACE — ENVIRONMENTAL LEGACY MAKERS AWARD';
    SeoTitle='From Concrete Fatigue to Green Asset | Ahmad Alhadidii';
    Description='First-place Environmental Legacy Makers Award team project transforming Jabal Al-Zuhour''s concrete stairs into green civic infrastructure.';
    Definition='A staircase transformation proposal turning daily urban infrastructure into environmental and social value.';
    Overview='The project rethinks Jabal Al-Zuhour staircase as more than circulation. Through shade, planting, water management, and social pauses, it turns a repeated daily climb into a green civic asset.';
    Year='2026'; Location='Amman, Jordan'; Type='Urban and Environmental Intervention'; Context='Award-Winning Team Project'; Award='1st Place — Environmental Legacy Makers Award'; Role='Concept Development, Environmental Strategy, and Visual Communication'; Organisations='Greater Amman Municipality, UN-Habitat Jordan, and the Royal Society for the Conservation of Nature, with support from the Government of the Netherlands.';
    Image='/assets/images/green-asset-1920.jpg'; ImageWidth='1920'; ImageHeight='1080'; ImageAlt='Environmental design board mapping the transformation of a concrete stair into green civic infrastructure.'; Caption='FROM CONCRETE FATIGUE TO GREEN ASSET / TREE UNIT IDENTITY STUDY / 2026';
    Keywords='Environmental Legacy Makers Award, team project, urban intervention, green infrastructure';
  }
)

$Primary = @('shila','manmatic','dabouq','concrete-fatigue')

foreach ($Project in $Projects) {
  $Canonical = "$CanonicalBase/$($Project.Route)"
  $ImageAbsolute = "$CanonicalBase$($Project.Image)"
  $ThemeColor = if ($Project.Theme -eq 'manmatic') { '#0a0a0a' } else { '#ffffff' }
  $InitialTheme = if ($Project.Theme -eq 'manmatic') { 'manmatic' } else { 'light' }

  $MetaRows = @(
    @('YEAR',$Project.Year), @('LOCATION',$Project.Location), @('TYPE',$Project.Type),
    @('CONTEXT',$Project.Context), @('OFFICE',$Project.Office), @('RELATION',$Project.Relation),
    @('AWARD',$Project.Award), @('ROLE',$Project.Role)
  ) | Where-Object { $_[1] }
  $MetaHtml = ($MetaRows | ForEach-Object { '<div><dt>{0}</dt><dd>{1}</dd></div>' -f (ConvertTo-HtmlEscaped $_[0]),(ConvertTo-HtmlEscaped $_[1]) }) -join ''

  $CreditRows = @(
    @('ROLE',$Project.Role), @('CATEGORY',$Project.Context), @('ORGANISATIONS',$Project.Organisations), @('OFFICE',$Project.Office)
  ) | Where-Object { $_[1] }
  $CreditHtml = ($CreditRows | ForEach-Object { '<div><dt>{0}</dt><dd>{1}</dd></div>' -f (ConvertTo-HtmlEscaped $_[0]),(ConvertTo-HtmlEscaped $_[1]) }) -join ''

  $Creator = @{ '@type'='Person'; '@id'="$CanonicalBase/#person"; name='Ahmad Alhadidii'; url="$CanonicalBase/" }
  $Schema = [ordered]@{
    '@context'='https://schema.org'; '@type'='CreativeWork'; '@id'="$Canonical#project";
    name=$Project.Title; headline=$Project.SeoTitle; description=$Project.Description; url=$Canonical;
    image=$ImageAbsolute; dateCreated=$Project.Year;
    creator=if ($Project.Context -eq 'Award-Winning Team Project') { $null } else { $Creator };
    author=if ($Project.Context -eq 'Award-Winning Team Project') { $null } else { $Creator };
    contributor=if ($Project.Context -eq 'Award-Winning Team Project') { $Creator } else { $null };
    locationCreated=if ($Project.Location) { @{ '@type'='Place'; name=$Project.Location } } else { $null };
    keywords=$Project.Keywords; award=$Project.Award;
    creditText=if ($Project.Context -eq 'Award-Winning Team Project') { "Award-winning team project. Ahmad Alhadidii's role: $($Project.Role)" } else { $null };
    isPartOf=if ($Project.Slug -eq 'protocol-port') { @{ '@type'='CreativeWork'; '@id'="$CanonicalBase/projects/manmatic/#project"; name='ManMaTIC' } } else { @{ '@type'='WebSite'; '@id'="$CanonicalBase/#website"; name='Ahmad Alhadidii Portfolio' } }
  }
  $SchemaJson = $Schema | ConvertTo-Json -Depth 8

  $Index = [Array]::IndexOf($Primary, $Project.Slug)
  if ($Index -ge 0) {
    $PreviousSlug = $Primary[($Index - 1 + $Primary.Count) % $Primary.Count]
    $NextSlug = $Primary[($Index + 1) % $Primary.Count]
    $Previous = $Projects | Where-Object Slug -eq $PreviousSlug
    $Next = $Projects | Where-Object Slug -eq $NextSlug
    $ProjectNav = '<div class="project-navigation__grid"><a class="project-navigation__link" href="/{0}" rel="prev"><p class="project-navigation__direction">PREVIOUS / {1}</p><p class="project-navigation__title">{2}</p></a><a class="project-navigation__link" href="/{3}" rel="next"><p class="project-navigation__direction">NEXT / {4}</p><p class="project-navigation__title">{5}</p></a></div>' -f (ConvertTo-HtmlEscaped $Previous.Route),(ConvertTo-HtmlEscaped $Previous.Number),(ConvertTo-HtmlEscaped $Previous.Title),(ConvertTo-HtmlEscaped $Next.Route),(ConvertTo-HtmlEscaped $Next.Number),(ConvertTo-HtmlEscaped $Next.Title)
  } else {
    $ProjectNav = '<a class="project-navigation__link" href="/projects/manmatic/">BACK TO MANMATIC METHODOLOGY ←</a>'
  }

  $Html = @"
<!doctype html>
<html lang="en" class="no-js" data-page="project" data-project-key="$(ConvertTo-HtmlEscaped $Project.Slug)" data-initial-theme="$InitialTheme" data-site-theme="$InitialTheme" data-build="$Build">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="description" content="$(ConvertTo-HtmlEscaped $Project.Description)">
  <meta name="author" content="Ahmad Alhadidii">
  <meta name="creator" content="Ahmad Alhadidii">
  <meta name="copyright" content="Ahmad Alhadidii">
  <meta name="robots" content="index, follow, max-image-preview:large">
  <meta name="theme-color" content="$ThemeColor">
  <meta property="og:type" content="article"><meta property="og:site_name" content="Ahmad Alhadidii Portfolio">
  <meta property="og:title" content="$(ConvertTo-HtmlEscaped $Project.SeoTitle)"><meta property="og:description" content="$(ConvertTo-HtmlEscaped $Project.Description)">
  <meta property="og:url" content="$Canonical"><meta property="og:image" content="$ImageAbsolute"><meta property="og:image:alt" content="$(ConvertTo-HtmlEscaped $Project.ImageAlt)"><meta property="og:image:width" content="$($Project.ImageWidth)"><meta property="og:image:height" content="$($Project.ImageHeight)">
  <meta name="twitter:card" content="summary_large_image"><meta name="twitter:title" content="$(ConvertTo-HtmlEscaped $Project.SeoTitle)"><meta name="twitter:description" content="$(ConvertTo-HtmlEscaped $Project.Description)"><meta name="twitter:image" content="$ImageAbsolute"><meta name="twitter:image:alt" content="$(ConvertTo-HtmlEscaped $Project.ImageAlt)">
  <title>$(ConvertTo-HtmlEscaped $Project.SeoTitle)</title><link rel="canonical" href="$Canonical">
  <link rel="icon" type="image/png" sizes="16x16" href="/assets/icons/ad-mark-v1-16.png"><link rel="icon" type="image/png" sizes="32x32" href="/assets/icons/ad-mark-v1-32.png"><link rel="apple-touch-icon" sizes="180x180" href="/assets/icons/ad-mark-v1-180.png"><link rel="manifest" href="/site.webmanifest">
  <script type="application/ld+json">$SchemaJson</script>
  <script src="/content.js?v=$Build"></script><script src="/assets/js/project-bootstrap.js?v=$Build"></script>
  <style>html,body,main{background:#fff;color:#111}.no-js .loader{display:none}html[data-initial-theme="manmatic"],html[data-initial-theme="manmatic"] body,html[data-initial-theme="manmatic"] main{background:#0a0a0a;color:#f2f2f2}</style>
  <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="preload" href="$($Project.Image)" as="image"><link rel="stylesheet" href="/assets/css/style.css?v=$Build"><script src="/assets/js/main.js?v=$Build" defer></script><script src="/assets/js/project.js?v=$Build" defer></script>
</head>
<body class="project-page" data-project="$(ConvertTo-HtmlEscaped $Project.Slug)">
  <div class="loader loader--project" id="loader" role="status" aria-label="Opening $(ConvertTo-HtmlEscaped $Project.Title)"><p class="visually-hidden" id="loader-announcement" aria-live="polite">$(ConvertTo-HtmlEscaped $Project.Title) project file is opening.</p><div class="project-loader" aria-hidden="true"><header class="project-loader__identity"><p class="project-loader__file" data-project-loader-kicker>PROJECT FILE</p><p class="project-loader__title" id="loader-name">$(ConvertTo-HtmlEscaped $Project.Title)</p><p class="project-loader__subtitle" data-project-loader-subtitle>$(ConvertTo-HtmlEscaped $Project.Subtitle)</p><dl><div><dt>LOCATION / YEAR</dt><dd data-project-loader-year>$(ConvertTo-HtmlEscaped (($Project.Location,$Project.Year | Where-Object { $_ }) -join ' / '))</dd></div><div><dt>TYPE</dt><dd data-project-loader-type>$(ConvertTo-HtmlEscaped $Project.Type)</dd></div><div><dt>STATE</dt><dd id="loader-state">FILE INDEXING</dd></div></dl></header><figure class="project-loader__visual"><div class="project-loader__image loader__preview-image"><img data-loader-preview width="$($Project.ImageWidth)" height="$($Project.ImageHeight)" alt=""><span class="project-loader__scan"></span><span class="project-loader__slice project-loader__slice--one"></span><span class="project-loader__slice project-loader__slice--two"></span><p class="project-loader__fallback" data-project-loader-fallback>PROJECT IMAGE UNAVAILABLE</p></div><figcaption><span data-project-loader-caption>PROJECT IMAGE</span><span>FRAME <b id="loader-frame">01 / 06</b> · SIGNAL <b id="loader-signal">000.000</b></span></figcaption></figure><footer class="project-loader__footer"><div class="project-loader__opening"><span>OPENING FILE</span><div class="project-loader__count"><strong id="loader-progress">000</strong><small>/ 100</small></div></div><div class="loader__progress-track"><span id="loader-progress-bar"></span></div><div class="project-loader__status"><p data-project-loader-status-type>PROJECT FILE</p><p id="loader-phase">FILE ACCESS</p><p><span id="loader-progress-secondary">000</span> / 100</p></div></footer></div></div>
  <noscript><style>.loader,.nav-toggle{display:none!important}</style></noscript><a class="skip-link" href="#main-content">Skip to project content</a><div class="ambient-signal" aria-hidden="true"></div><div class="material-texture" aria-hidden="true"></div>
  <div class="site-shell"><header class="site-header" id="site-header"><div class="site-header__inner page-width"><a class="site-header__name" href="/" aria-label="Ahmad Alhadidii, return to portfolio index">AHMAD ALHADIDII</a><p class="running-header" aria-hidden="true"><span id="running-header-text">$(if($Project.Theme -eq 'manmatic'){'MANMATIC / HUMAN–MACHINE COLLABORATION / ACTIVE FIELD'}else{"PROJECT FILE $($Project.Number) / $($Project.Title) / $($Project.Year)"})</span></p><button class="nav-toggle" id="nav-toggle" type="button" aria-expanded="false" aria-controls="primary-navigation" aria-label="Open navigation"><span class="nav-toggle__open">MENU</span><span class="nav-toggle__close">CLOSE</span></button><button class="nav-backdrop" type="button" data-nav-dismiss tabindex="-1" aria-label="Close navigation"></button><nav class="site-nav" id="primary-navigation" aria-label="Primary navigation"><a href="/"><span>INDEX</span></a><a href="/#profile"><span>PROFILE</span></a><a href="/#cv"><span>CV</span></a><a class="is-active" href="/#work" aria-current="location"><span>WORK</span></a><a href="/#computation"><span>COMPUTATION</span></a><a href="/#visual-studies"><span>VISUALS</span></a><a href="/#contact"><span>CONTACT</span></a><a class="site-nav__external" href="https://www.manmatic.institute/" target="_blank" rel="noopener noreferrer">MANMATIC FIELD <span aria-hidden="true">↗</span></a></nav></div></header>
    <main id="main-content" tabindex="-1"><article class="project-detail" id="project-detail"><div class="project-intro page-width"><header class="project-header" data-project-theme="$InitialTheme">$(if($Project.Slug -eq 'protocol-port'){'<div class="project-header__system-nav"><p>MANMATIC SYSTEM / PROTOCOL PORT</p><a href="/projects/manmatic/">BACK TO MANMATIC SYSTEM ←</a></div>'})<p class="project-header__eyebrow">PROJECT FILE $(ConvertTo-HtmlEscaped $Project.Number) / $(ConvertTo-HtmlEscaped $Project.Context)</p><h1 aria-label="$(ConvertTo-HtmlEscaped $Project.Title)"><span class="project-header__archive-title pointer-scan">$(ConvertTo-HtmlEscaped $Project.Title)</span><span class="project-header__archive-subtitle">$(ConvertTo-HtmlEscaped $Project.Subtitle)</span></h1><p class="project-header__definition">$(ConvertTo-HtmlEscaped $Project.Definition)</p><dl class="project-meta">$MetaHtml</dl></header><section class="project-hero" aria-label="Project visual"><figure class="project-hero__media image-frame image-reveal media--contain" style="--media-ratio:$($Project.ImageWidth) / $($Project.ImageHeight)"><div class="image-frame__crop"><img src="$($Project.Image)" width="$($Project.ImageWidth)" height="$($Project.ImageHeight)" alt="$(ConvertTo-HtmlEscaped $Project.ImageAlt)" fetchpriority="high" decoding="async"></div><figcaption>$(ConvertTo-HtmlEscaped $Project.Caption)</figcaption></figure></section></div>
      <section class="project-copy-section page-width"><p class="project-copy-section__label">01 / OVERVIEW</p><div class="project-copy-section__body"><h2>Project overview</h2><p>$(ConvertTo-HtmlEscaped $Project.Overview)</p></div></section>$($Project.Extra)<section class="project-copy-section page-width"><p class="project-copy-section__label">03 / CREDITS</p><div class="project-copy-section__body"><h2>Project contribution</h2><dl class="project-credit-list">$CreditHtml</dl></div></section><nav class="project-navigation page-width" aria-label="Project navigation"><div class="project-navigation__top"><a href="/#work">BACK TO WORK ←</a><a href="/">PORTFOLIO INDEX ↑</a></div>$ProjectNav</nav></article></main>
    <footer class="site-footer page-width"><p>© 2026 AHMAD ALHADIDII</p><p>AS-SALT, JORDAN</p><a href="/">PORTFOLIO INDEX <span aria-hidden="true">↗</span></a></footer></div>
</body>
</html>
"@

  $Output = Join-Path $Root ($Project.Route + 'index.html')
  New-Item -ItemType Directory -Path (Split-Path -Parent $Output) -Force | Out-Null
  [System.IO.File]::WriteAllText($Output, $Html, [System.Text.UTF8Encoding]::new($false))
  Write-Output "Generated $($Project.Route)index.html"
}
