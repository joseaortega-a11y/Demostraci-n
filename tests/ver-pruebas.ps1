# Abre las pruebas en una ventana de Edge (o Chrome) para verlas correr.
# Uso:  powershell -ExecutionPolicy Bypass -File tests\ver-pruebas.ps1
# Usa un perfil aparte, con permiso para que la página de pruebas acceda a index.html.
$candidatos = @(
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
)
$nav = $candidatos | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $nav) { Write-Error 'No se encontró Edge ni Chrome.'; exit 2 }

$url = 'file:///' + ((Join-Path $PSScriptRoot 'pruebas.html') -replace '\\', '/')
$perfil = Join-Path $env:TEMP 'pruebas-troncal-visible'
Start-Process $nav -ArgumentList "--user-data-dir=`"$perfil`"", '--no-first-run', '--allow-file-access-from-files', '--new-window', $url
