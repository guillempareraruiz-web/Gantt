# Convierte un documento comercial de FS Planner (HTML) a PDF listo para enviar.
#
#   .\html-a-pdf.ps1 fs-planner-innovacionessubbetica.html
#   .\html-a-pdf.ps1 fs-planner-universalsleeve.html
#
# Por que hace falta este envoltorio y no basta con "imprimir a PDF" desde el
# navegador:
#
#   1. Los HTML de docs\ son FRAGMENTOS (empiezan por <title>, sin <html> ni
#      <head>): estan pensados para publicarse como artifact, que ya los
#      envuelve. Para imprimirlos hay que anadirles el doctype y el charset, o
#      los acentos salen mal.
#   2. Llevan tema oscuro automatico. En un equipo con Windows en modo oscuro,
#      el PDF saldria con fondo negro. Se fuerza data-theme="light".
#   3. Chrome NO imprime colores de fondo salvo que se le pida: sin
#      print-color-adjust, la franja oscura de "El impacto" saldria en blanco.
#   4. En pantalla las ventajas van en una columna; en A4 caben dos y ahorran
#      paginas sin apretar el texto.

param(
    [Parameter(Mandatory = $true)]
    [string]$Html,

    # Cuerpo del texto. 10.5 = version aireada (por defecto); 9.5 = compacta,
    # unas dos paginas menos.
    [double]$Cuerpo = 10.5
)

$ErrorActionPreference = 'Stop'
$docs = $PSScriptRoot

$origen = Join-Path $docs $Html
if (-not (Test-Path $origen)) { throw "No se encuentra $origen" }

$destino = Join-Path $docs ([System.IO.Path]::GetFileNameWithoutExtension($Html) + '.pdf')
$temporal = Join-Path $env:TEMP ('fsplanner-print-' + [System.IO.Path]::GetFileNameWithoutExtension($Html) + '.html')

# Buscar Chrome; Edge sirve igual (mismo motor).
$navegador = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $navegador) { throw 'No se ha encontrado Chrome ni Edge.' }

$margen = if ($Cuerpo -ge 10) { '14mm' } else { '12mm' }
$titular = if ($Cuerpo -ge 10) { '26pt' } else { '23pt' }
$lede    = if ($Cuerpo -ge 10) { '12pt' } else { '11pt' }

$cabecera = @'
<!doctype html>
<html lang="es" data-theme="light">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
'@

$pie = @"
<style>
  /* Ajustes SOLO para la version impresa: el documento en pantalla no cambia. */
  @page { size: A4; margin: $margen 0; }
  html, body { background: #FFFFFF !important; }
  body { font-size: ${Cuerpo}pt; line-height: 1.5; }
  .wrap { max-width: 100%; padding: 0 16mm; }

  /* Sin esto Chrome no imprime fondos y la franja oscura del impacto, las
     tarjetas y las pastillas de color saldrian en blanco. */
  * { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }

  /* Ni secciones partidas por la mitad ni titulos huerfanos al pie de pagina. */
  section { break-inside: auto; padding: 8mm 0; }
  h1, h2, h3 { break-after: avoid; }
  .adv, .stat, .cap-row, .trust-item, .contact, .cert-row { break-inside: avoid; }

  .hero { padding: 6mm 0 8mm; }
  h1 { font-size: $titular; }
  .hero .lede { font-size: $lede; }
  h2 { font-size: 17pt; }
  .sec-intro { font-size: 11pt; }

  @media print {
    /* En A4 caben dos columnas de ventajas. */
    .adv-grid { grid-template-columns: 1fr 1fr; gap: 5mm; }
    .adv { padding: 4mm 5mm; }
    .stat-grid { grid-template-columns: repeat(4, 1fr); }
    a { text-decoration: none; }
  }
</style>
</body>
</html>
"@

$cabecera | Out-File -FilePath $temporal -Encoding utf8
Get-Content $origen -Raw -Encoding UTF8 | Out-File -FilePath $temporal -Encoding utf8 -Append
$pie | Out-File -FilePath $temporal -Encoding utf8 -Append

$uri = 'file:///' + $temporal.Replace('\', '/')

# virtual-time-budget da margen a que el navegador aplique fuentes y estilos
# antes de capturar; sin el, el PDF puede salir a medio maquetar.
#
# Chrome escribe su traza en stderr, tambien cuando todo va bien. En PowerShell
# 5.1 eso basta para que el script aborte con NativeCommandError, asi que se
# usa Start-Process con la salida a ficheros en vez de capturarla en linea.
$logSalida = Join-Path $env:TEMP 'fsplanner-chrome-out.txt'
$logError  = Join-Path $env:TEMP 'fsplanner-chrome-err.txt'

$argumentos = @(
    '--headless', '--disable-gpu', '--no-sandbox',
    "--print-to-pdf=$destino", '--no-pdf-header-footer',
    '--virtual-time-budget=6000', $uri
)

Start-Process -FilePath $navegador -ArgumentList $argumentos -Wait -NoNewWindow `
    -RedirectStandardOutput $logSalida -RedirectStandardError $logError

Remove-Item $temporal, $logSalida, $logError -ErrorAction SilentlyContinue

if (Test-Path $destino) {
    $kb = [math]::Round((Get-Item $destino).Length / 1KB, 1)
    $txt = [System.Text.Encoding]::GetEncoding(28591).GetString([System.IO.File]::ReadAllBytes($destino))
    $pags = ([regex]::Matches($txt, '/Type\s*/Page[^s]')).Count
    Write-Output "OK  $destino"
    Write-Output "    $pags paginas, $kb KB"
} else {
    throw "No se ha generado $destino"
}
