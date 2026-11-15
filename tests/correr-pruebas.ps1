# Corre las pruebas de la página con Edge (o Chrome) en segundo plano.
# Uso:  powershell -ExecutionPolicy Bypass -File tests\correr-pruebas.ps1
#       (opcional) -Pagina C:\ruta\otra-copia.html  para probar otra versión de la página
param([string]$Pagina)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$candidatos = @(
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
)
$nav = $candidatos | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $nav) { Write-Error 'No se encontró Edge ni Chrome.'; exit 2 }

$url = 'file:///' + ((Join-Path $PSScriptRoot 'pruebas.html') -replace '\\', '/')
if ($Pagina) { $url += '?pagina=' + [uri]::EscapeDataString('file:///' + ((Resolve-Path $Pagina).Path -replace '\\', '/')) }
$perfil = Join-Path $env:TEMP ('pruebas-troncal-' + [guid]::NewGuid())

try {
  $ErrorActionPreference = 'Continue'   # Edge escribe avisos en stderr que no son errores
  $dom = & $nav --headless=new --disable-gpu --no-first-run --user-data-dir="$perfil" `
    --allow-file-access-from-files --virtual-time-budget=300000 --dump-dom $url 2>$null | Out-String
} finally {
  Remove-Item -Recurse -Force $perfil -ErrorAction SilentlyContinue
}

$m = [regex]::Match($dom, '===INICIO===([\s\S]*?)===FIN===')
if (-not $m.Success) { Write-Host 'No se obtuvieron resultados. Salida del navegador:'; Write-Host $dom; exit 2 }

$texto = [Net.WebUtility]::HtmlDecode(($m.Groups[1].Value -replace '<[^>]+>', '')).Trim()
foreach ($l in $texto -split "`n") {
  $color = if ($l -like 'OK*') { 'Green' } elseif ($l -like 'FALLO*' -or $l -like '   *') { 'Red' } else { 'White' }
  Write-Host $l -ForegroundColor $color
}
if ($texto -match 'FALLO') { exit 1 } else { exit 0 }
