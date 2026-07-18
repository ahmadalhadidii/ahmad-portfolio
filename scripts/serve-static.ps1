param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot),
  [int]$Port = 4173
)

$ErrorActionPreference = 'Stop'
$Root = [System.IO.Path]::GetFullPath($Root)
$Listener = [System.Net.HttpListener]::new()
$Listener.Prefixes.Add("http://127.0.0.1:$Port/")
$Listener.Start()

$Mime = @{
  '.html'='text/html; charset=utf-8'; '.css'='text/css; charset=utf-8';
  '.js'='text/javascript; charset=utf-8'; '.json'='application/json; charset=utf-8';
  '.webmanifest'='application/manifest+json; charset=utf-8'; '.xml'='application/xml; charset=utf-8';
  '.txt'='text/plain; charset=utf-8'; '.png'='image/png'; '.jpg'='image/jpeg';
  '.jpeg'='image/jpeg'; '.webp'='image/webp'; '.svg'='image/svg+xml'; '.pdf'='application/pdf';
  '.mp4'='video/mp4'
}

try {
  while ($Listener.IsListening) {
    $Context = $Listener.GetContext()
    $Path = [Uri]::UnescapeDataString($Context.Request.Url.AbsolutePath.TrimStart('/'))
    if (-not $Path) { $Path = 'index.html' }
    $Candidate = Join-Path $Root ($Path -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (Test-Path -LiteralPath $Candidate -PathType Container) { $Candidate = Join-Path $Candidate 'index.html' }
    $Resolved = [System.IO.Path]::GetFullPath($Candidate)

    if (-not $Resolved.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $Resolved -PathType Leaf)) {
      $Context.Response.StatusCode = 404
      $Resolved = Join-Path $Root '404.html'
    }

    $Bytes = [System.IO.File]::ReadAllBytes($Resolved)
    $Extension = [System.IO.Path]::GetExtension($Resolved).ToLowerInvariant()
    $Context.Response.ContentType = if ($Mime.ContainsKey($Extension)) { $Mime[$Extension] } else { 'application/octet-stream' }
    $Context.Response.ContentLength64 = $Bytes.Length
    $Context.Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
    $Context.Response.OutputStream.Close()
  }
}
finally {
  $Listener.Stop()
  $Listener.Close()
}
