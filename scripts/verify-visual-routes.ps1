param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$Root = [System.IO.Path]::GetFullPath($Root)
$CanonicalBase = 'https://www.ahmadalhadidii.manmatic.institute'
$Assertions = 0

function Assert-State([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw $Message }
  $script:Assertions++
}

function Encode-Html([object]$Value) {
  return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

$source = Get-Content -Raw -Encoding utf8 -LiteralPath (Join-Path $Root 'content.js')
$match = [regex]::Match($source, '(?s)visuals:\s*(\[\s*\{.*?\}\s*\])\s*,\s*computations:')
Assert-State $match.Success 'Unable to read Visual records from content.js.'
$json = [regex]::Replace($match.Groups[1].Value, '(?m)^(\s*)([A-Za-z][A-Za-z0-9]*):', '$1"$2":')
$visuals = $json | ConvertFrom-Json
Assert-State ($visuals.Count -gt 0) 'No Visual records were found.'

$homepage = Get-Content -Raw -Encoding utf8 -LiteralPath (Join-Path $Root 'index.html')
$mainScript = Get-Content -Raw -Encoding utf8 -LiteralPath (Join-Path $Root 'assets\js\main.js')
$visualScript = Get-Content -Raw -Encoding utf8 -LiteralPath (Join-Path $Root 'assets\js\visual.js')
$sitemap = Get-Content -Raw -Encoding utf8 -LiteralPath (Join-Path $Root 'sitemap.xml')

Assert-State ($mainScript -match '/visuals/\$\{encodeURIComponent\(study\.slug') 'The enhanced Visual cards do not build URLs from their own record slug.'
Assert-State ($visualScript -match 'document\.body\.dataset\.visualSlug' -and $visualScript -match '/visuals/\$\{encodeURIComponent\(visual\.slug\)\}/') 'The Visual detail enhancer does not resolve and link clean Visual slugs.'

for ($index = 0; $index -lt $visuals.Count; $index++) {
  $visual = $visuals[$index]
  $previous = $visuals[($index - 1 + $visuals.Count) % $visuals.Count]
  $next = $visuals[($index + 1) % $visuals.Count]
  $route = "/visuals/$($visual.slug)/"
  $canonical = "$CanonicalBase$route"
  $title = "$($visual.title) | Ahmad Alhadidii"
  $file = Join-Path $Root ("visuals\{0}\index.html" -f $visual.slug)
  Assert-State (Test-Path -LiteralPath $file -PathType Leaf) ("Missing static Visual page: {0}" -f $visual.slug)
  $html = Get-Content -Raw -Encoding utf8 -LiteralPath $file

  Assert-State ($homepage -match [regex]::Escape("href=`"$route`"")) ("Homepage archive link is missing for {0}." -f $visual.slug)
  Assert-State ($sitemap -match [regex]::Escape("<loc>$canonical</loc>")) ("Sitemap route is missing for {0}." -f $visual.slug)
  Assert-State ($html -match [regex]::Escape("<title>$(Encode-Html $title)</title>")) ("Page title is incorrect for {0}." -f $visual.slug)
  Assert-State ($html -match [regex]::Escape("<h1>$(Encode-Html $visual.title)</h1>")) ("Visible heading is incorrect for {0}." -f $visual.slug)
  Assert-State ($html -match [regex]::Escape("<link rel=`"canonical`" href=`"$canonical`">")) ("Canonical URL is incorrect for {0}." -f $visual.slug)
  Assert-State ($html -match [regex]::Escape("<meta property=`"og:title`" content=`"$(Encode-Html $title)`">")) ("Open Graph title is incorrect for {0}." -f $visual.slug)
  Assert-State ($html -match '<meta property="og:description" content="[^\"]+">' -and $html -match '<meta property="og:image" content="https://[^\"]+">') ("Open Graph description or image is missing for {0}." -f $visual.slug)
  Assert-State ($html -match [regex]::Escape("<meta name=`"twitter:title`" content=`"$(Encode-Html $title)`">")) ("Twitter title is incorrect for {0}." -f $visual.slug)
  Assert-State ($html -match '<meta name="twitter:description" content="[^\"]+">' -and $html -match '<meta name="twitter:image" content="https://[^\"]+">') ("Twitter description or image is missing for {0}." -f $visual.slug)
  Assert-State ($html -match '<script type="application/ld\+json">' -and $html -match [regex]::Escape('"name":"' + $visual.title + '"')) ("Structured data is missing or mismatched for {0}." -f $visual.slug)
  Assert-State ($html -match [regex]::Escape("data-visual-slug=`"$($visual.slug)`"")) ("Embedded Visual slug is missing for {0}." -f $visual.slug)
  Assert-State ($html -match [regex]::Escape("src=`"/$(Encode-Html $visual.src)`"")) ("Primary image does not match the Visual record for {0}." -f $visual.slug)
  Assert-State ($html -match [regex]::Escape((Encode-Html $visual.description.Substring(0, [Math]::Min(80, $visual.description.Length))))) ("Description does not match the Visual record for {0}." -f $visual.slug)
  Assert-State ($html -match [regex]::Escape("href=`"/visuals/$($previous.slug)/`" rel=`"prev`"")) ("Previous route is incorrect for {0}." -f $visual.slug)
  Assert-State ($html -match [regex]::Escape("href=`"/visuals/$($next.slug)/`" rel=`"next`"")) ("Next route is incorrect for {0}." -f $visual.slug)
  Assert-State ($html -notmatch '(?i)(<title>[^<]*(?:selected visual|visual detail|file index|index\.html)[^<]*</title>|<h1>[^<]*(?:selected visual|visual detail|file index|index\.html)[^<]*</h1>)') ("Generic or filename-based Visual identity remains in {0}." -f $visual.slug)
  Assert-State ($html -notmatch '(?:href|content)="[^"]*index\.html') ("A visible or metadata URL exposes index.html in {0}." -f $visual.slug)

  $asset = Join-Path $Root ($visual.src -replace '/', '\')
  Assert-State (Test-Path -LiteralPath $asset -PathType Leaf) ("Visual image asset is missing for {0}." -f $visual.slug)
}

Write-Output ("Visual route verification PASS: {0} Visuals, {1} assertions." -f $visuals.Count, $Assertions)
