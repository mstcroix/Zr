# doc.companion.server.ps1
# Minimal HTTP server for doc.companion.html
# Serves files from the bitacora directory on http://localhost:7000
# Usage: powershell -ExecutionPolicy Bypass -File doc.companion.server.ps1

$port = 7000
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$url  = "http://localhost:$port/"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
$listener.Start()

Write-Host ""
Write-Host "  Zr Companion Server" -ForegroundColor Cyan
Write-Host "  Serving: $root" -ForegroundColor Gray
Write-Host "  Open  -> $url`doc.companion.html" -ForegroundColor Green
Write-Host "  Stop  -> Ctrl+C" -ForegroundColor Gray
Write-Host ""

$mime = @{
  '.html' = 'text/html; charset=utf-8'
  '.md'   = 'text/plain; charset=utf-8'
  '.js'   = 'application/javascript'
  '.css'  = 'text/css'
  '.json' = 'application/json'
  '.png'  = 'image/png'
  '.ico'  = 'image/x-icon'
}

try {
  while ($listener.IsListening) {
    $ctx  = $listener.GetContext()
    $req  = $ctx.Request
    $resp = $ctx.Response

    $rawPath = $req.Url.LocalPath.TrimStart('/')
    $file    = Join-Path $root $rawPath

    # Default to companion
    if ($rawPath -eq '' -or $rawPath -eq '/') {
      $file = Join-Path $root 'doc.companion.html'
    }

    $ext  = [System.IO.Path]::GetExtension($file)
    $ct   = if ($mime[$ext]) { $mime[$ext] } else { 'application/octet-stream' }

    if (Test-Path $file -PathType Leaf) {
      $bytes = [System.IO.File]::ReadAllBytes($file)
      $resp.ContentType   = $ct
      $resp.ContentLength64 = $bytes.Length
      $resp.StatusCode    = 200
      $resp.OutputStream.Write($bytes, 0, $bytes.Length)
      Write-Host "  200  $rawPath" -ForegroundColor Green
    } else {
      $msg   = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $rawPath")
      $resp.StatusCode    = 404
      $resp.ContentType   = 'text/plain'
      $resp.ContentLength64 = $msg.Length
      $resp.OutputStream.Write($msg, 0, $msg.Length)
      Write-Host "  404  $rawPath" -ForegroundColor Red
    }
    $resp.OutputStream.Close()
  }
} finally {
  $listener.Stop()
  Write-Host "Server stopped." -ForegroundColor Gray
}
