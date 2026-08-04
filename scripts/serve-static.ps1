param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot),
  [int]$Port = 4173
)

$ErrorActionPreference = 'Stop'
$Root = [System.IO.Path]::GetFullPath($Root)
$Listener = [System.Net.HttpListener]::new()
$Listener.IgnoreWriteExceptions = $true
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
    try {
      $Path = [Uri]::UnescapeDataString($Context.Request.Url.AbsolutePath.TrimStart('/'))
      if (-not $Path) { $Path = 'index.html' }
      $Candidate = Join-Path $Root ($Path -replace '/', [System.IO.Path]::DirectorySeparatorChar)
      if (Test-Path -LiteralPath $Candidate -PathType Container) { $Candidate = Join-Path $Candidate 'index.html' }
      $Resolved = [System.IO.Path]::GetFullPath($Candidate)

      if (-not $Resolved.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $Resolved -PathType Leaf)) {
        $Context.Response.StatusCode = 404
        $Context.Response.Headers['Cache-Control'] = 'no-store'
        $Resolved = Join-Path $Root '404.html'
      }

      $Bytes = [System.IO.File]::ReadAllBytes($Resolved)
      $Extension = [System.IO.Path]::GetExtension($Resolved).ToLowerInvariant()
      $Context.Response.ContentType = if ($Mime.ContainsKey($Extension)) { $Mime[$Extension] } else { 'application/octet-stream' }
      if ($Context.Response.StatusCode -ne 404) {
        $Context.Response.Headers['Cache-Control'] = if ($Extension -eq '.html') { 'no-cache' } else { 'public, max-age=3600' }
      }
      $Context.Response.ContentLength64 = $Bytes.Length
      $Context.Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
    }
    catch [System.Net.HttpListenerException] {
      # Navigations legitimately cancel in-flight image responses; keep serving subsequent requests.
    }
    catch [System.IO.IOException] {
      # A browser can close the connection while a large image is being streamed.
    }
    finally {
      try { $Context.Response.OutputStream.Close() } catch {}
    }
  }
}
finally {
  $Listener.Stop()
  $Listener.Close()
}
