$ErrorActionPreference = 'Stop'

$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$outDir = Join-Path $env:TEMP 'ahmad-reference-inspection'
$runId = Get-Date -Format 'yyyyMMdd-HHmmssfff'
$url = 'https://frank-reservation-697225-6f928b65c.framer.app/'

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$captures = @(
  @{ Name = 'top'; Width = 1440; Height = 900 },
  @{ Name = 'long'; Width = 1440; Height = 5000 },
  @{ Name = 'mobile'; Width = 500; Height = 1200 }
)

foreach ($capture in $captures) {
  $BrowserProfilePath = Join-Path $outDir ("profile-$runId-$($capture.Name)")
  $shot = Join-Path $outDir ("$runId-$($capture.Name).png")
  $process = Start-Process -FilePath $chrome -ArgumentList @(
    '--headless=new',
    '--disable-gpu',
    '--hide-scrollbars',
    '--no-first-run',
    "--user-data-dir=$BrowserProfilePath",
    "--window-size=$($capture.Width),$($capture.Height)",
    '--virtual-time-budget=5000',
    "--screenshot=$shot",
    $url
  ) -PassThru -Wait -WindowStyle Hidden

  if (-not (Test-Path -LiteralPath $shot)) {
    throw "Reference screenshot was not created: $($capture.Name)"
  }

  Get-Item -LiteralPath $shot | Select-Object Name, Length, FullName
}

$domProfile = Join-Path $outDir ("profile-$runId-dom")
$domPath = Join-Path $outDir ("$runId-reference.html")
$errorPath = Join-Path $outDir ("$runId-reference.err.txt")
Start-Process -FilePath $chrome -ArgumentList @(
  '--headless=new',
  '--disable-gpu',
  '--no-first-run',
  "--user-data-dir=$domProfile",
  '--window-size=1440,900',
  '--virtual-time-budget=5000',
  '--dump-dom',
  $url
) -Wait -WindowStyle Hidden -RedirectStandardOutput $domPath -RedirectStandardError $errorPath

Get-Item -LiteralPath $domPath | Select-Object Name, Length, FullName
