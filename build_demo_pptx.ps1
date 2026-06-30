# Genera el PowerPoint de demo comercial FS Planner via PowerPoint COM.
# Diseno minimalista PRO: fondo oscuro, acento azul, tipografia limpia, mucho aire.

$ErrorActionPreference = 'Stop'

# --- Paleta ---
$BG      = 0x2B2620   # fondo oscuro (azul-gris muy oscuro) en BGR
$INK     = 0x000000
$WHITE   = 0xFFFFFF
$ACCENT  = 0xC87828   # azul medio (BGR) -> coherente con nodos manuales
$ACCENT2 = 0xDCB45A   # azul claro
$GREY    = 0xB0B0B0   # gris texto secundario
$DARKPANEL = 0x3A332B

# Enums PowerPoint
$msoTrue = -1
$msoFalse = 0
$ppLayoutBlank = 12
$msoShapeRectangle = 1
$msoTextOrientationHorizontal = 1
$ppAlignLeft = 1
$ppAlignCenter = 2
$ppAnchorMiddle = 3
$ppAnchorTop = 1

$OutPath = 'd:\PROJECTES\GANTT\GANTT\Demo_Comercial_Planner.pptx'

$pp = New-Object -ComObject PowerPoint.Application
# 16:9
$pres = $pp.Presentations.Add($msoFalse)
$pres.PageSetup.SlideSize = 15  # ppSlideSizeOnScreen16x9
$SW = $pres.PageSetup.SlideWidth
$SH = $pres.PageSetup.SlideHeight

function New-Slide {
    $slide = $pres.Slides.Add($pres.Slides.Count + 1, $ppLayoutBlank)
    # fondo
    $slide.FollowMasterBackground = $msoFalse
    $slide.Background.Fill.Solid()
    $slide.Background.Fill.ForeColor.RGB = $BG
    return $slide
}

function Add-Text {
    param($slide, $left, $top, $width, $height, $text, $size, $color, $bold, $align, $fontName, $anchor)
    if (-not $fontName) { $fontName = 'Segoe UI' }
    if (-not $align) { $align = $ppAlignLeft }
    if (-not $anchor) { $anchor = $ppAnchorTop }
    $tb = $slide.Shapes.AddTextbox($msoTextOrientationHorizontal, $left, $top, $width, $height)
    $tf = $tb.TextFrame
    $tf.WordWrap = $msoTrue
    $tf.VerticalAnchor = $anchor
    $tf.MarginLeft = 0; $tf.MarginRight = 0; $tf.MarginTop = 0; $tf.MarginBottom = 0
    $tr = $tf.TextRange
    $tr.Text = $text
    $tr.Font.Size = $size
    $tr.Font.Name = $fontName
    $tr.Font.Color.RGB = $color
    if ($bold) { $tr.Font.Bold = $msoTrue } else { $tr.Font.Bold = $msoFalse }
    $tr.ParagraphFormat.Alignment = $align
    return $tb
}

function Add-Rect {
    param($slide, $left, $top, $width, $height, $color)
    $sh = $slide.Shapes.AddShape($msoShapeRectangle, $left, $top, $width, $height)
    $sh.Fill.Solid()
    $sh.Fill.ForeColor.RGB = $color
    $sh.Line.Visible = $msoFalse
    return $sh
}

function Set-Notes {
    param($slide, $text)
    $ns = $slide.NotesPage.Shapes
    for ($i = 1; $i -le $ns.Count; $i++) {
        if ($ns.Item($i).HasTextFrame -eq $msoTrue -and $ns.Item($i).PlaceholderFormat) {
            try {
                if ($ns.Item($i).PlaceholderFormat.Type -eq 2) {  # ppPlaceholderBody
                    $ns.Item($i).TextFrame.TextRange.Text = $text
                    return
                }
            } catch {}
        }
    }
}

$ML = $SW * 0.08   # margen izquierdo
$CW = $SW * 0.84   # ancho contenido

# ============================================================
# SLIDE 1 — Portada
# ============================================================
$s = New-Slide
Add-Rect $s $ML ($SH*0.40) ($SW*0.10) 6 $ACCENT | Out-Null
Add-Text $s $ML ($SH*0.44) $CW ($SH*0.20) "La planificacion de tu fabrica, por fin bajo control." 40 $WHITE $true $ppAlignLeft 'Segoe UI Light' | Out-Null
Add-Text $s $ML ($SH*0.70) $CW ($SH*0.08) "Integrado con Sage 200" 18 $ACCENT2 $false $ppAlignLeft | Out-Null
Set-Notes $s "Gracias por el tiempo. En esta hora os voy a ensenar algo que creo que os va a gustar. No vengo a deciros como trabajais hoy, eso ya lo sabeis vosotros mejor que nadie, vengo a ensenaros como podriais trabajar."

# ============================================================
# SLIDE 2 — La promesa
# ============================================================
$s = New-Slide
Add-Text $s $ML ($SH*0.20) $CW ($SH*0.10) "Tres ideas para toda la sesion" 20 $GREY $false $ppAlignLeft | Out-Null
Add-Text $s $ML ($SH*0.40) $CW ($SH*0.20) "Simple   .   Conectado   .   A tu medida" 38 $WHITE $true $ppAlignLeft 'Segoe UI Semibold' | Out-Null
Add-Rect $s $ML ($SH*0.62) ($SW*0.20) 4 $ACCENT | Out-Null
Set-Notes $s "Tres ideas: es facil de usar, habla con vuestro Sage solo, y se adapta a como trabajais vosotros. Cada cosa que os ensene encajara en una de estas tres."

# ============================================================
# Helper para slides de contenido
# ============================================================
function Content-Slide {
    param($titular, $subtitulo, $cuerpo, $producto, $notas)
    $s = New-Slide
    # banda lateral de acento
    Add-Rect $s 0 0 ($SW*0.012) $SH $ACCENT | Out-Null
    $y = $SH*0.16
    Add-Text $s $ML $y $CW ($SH*0.16) $titular 32 $WHITE $true $ppAlignLeft 'Segoe UI Semibold' | Out-Null
    $y = $SH*0.34
    if ($subtitulo) {
        Add-Text $s $ML $y $CW ($SH*0.10) $subtitulo 20 $ACCENT2 $false $ppAlignLeft | Out-Null
        $y = $SH*0.46
    }
    if ($cuerpo) {
        Add-Text $s $ML $y $CW ($SH*0.30) $cuerpo 19 $GREY $false $ppAlignLeft | Out-Null
    }
    if ($producto) {
        $py = $SH*0.80
        $panel = Add-Rect $s $ML $py ($CW) ($SH*0.11) $DARKPANEL
        Add-Text $s ($ML+18) ($py+8) ($CW-36) ($SH*0.09) ("DEMO EN VIVO   >   " + $producto) 15 $ACCENT2 $true $ppAlignLeft | Out-Null
    }
    if ($notas) { Set-Notes $s $notas }
    return $s
}

# Helper para slides de impacto (cierre de bloque, frase grande)
function Impact-Slide {
    param($frase, $notas)
    $s = New-Slide
    Add-Rect $s ($SW*0.40) ($SH*0.30) ($SW*0.20) 5 $ACCENT | Out-Null
    Add-Text $s ($SW*0.10) ($SH*0.40) ($SW*0.80) ($SH*0.22) $frase 34 $WHITE $true $ppAlignCenter 'Segoe UI Light' $ppAnchorMiddle | Out-Null
    if ($notas) { Set-Notes $s $notas }
    return $s
}

# ============================================================
# SLIDE 3 — Sage 200
Content-Slide "No cambies nada de lo que ya tienes" "Tus ordenes ya estan en Sage 200." $null "Backlog con las ordenes reales de Sage 200" "Lo primero: no teneis que cambiar nada. Estas son vuestras ordenes, directas de Sage, sin teclear nada. El planner se conecta solo." | Out-Null

# SLIDE 4 — Cierre conexion
Impact-Slide "Conectado. Cero trabajo doble." "Lo que ahora copiais a mano a un Excel cada manana, aqui ya esta." | Out-Null

# SLIDE 5 — De la lista al plan (ESTRELLA)
Content-Slide "Y aqui empieza la magia" "De una lista de ordenes... a un plan real, en segundos." "1. Seleccionar ordenes y planificar (Express / wizard)`n2. El Gantt se llena, ordenado`n3. Heatmap: rojos de sobrecarga -> reequilibrar -> verdes`n4. Arrastrar un urgente -> todo se recoloca solo" "Planificacion Express -> Gantt -> Heatmap -> arrastrar urgente" "Mira que facil. En segundos: un plan completo, respetando calendarios, turnos, sin que dos cosas choquen. Y lo que mas me gusta: ver donde os vais a saturar ANTES de que pase. Rojo... y ahora verde. Si entra un urgente, lo moveis y todo se recoloca solo. (Silencio 2 segundos.)" | Out-Null

# SLIDE 6 — Cierre magia
Impact-Slide "De horas de Excel... a segundos." "Esto en Excel es imposible, o os lleva horas y aun asi con errores." | Out-Null

# SLIDE 7 — Varias formas de planificar
Content-Slide "Tu eliges como planificar" $null "Automatica hacia adelante (desde hoy) o hacia atras (desde la entrega)`nManual, a tu ritmo`nPor reglas de prioridad`nComparas metodos y te quedas con el mejor" "Wizard con distintos modos / comparativa de metodos" "No os imponemos una forma de planificar. Hacia adelante desde hoy, hacia atras desde la fecha de entrega, por reglas, o a mano. Incluso podeis comparar metodos y quedaros con el mejor." | Out-Null

# SLIDE 8 — Capacidad finita [MODULAR]
Content-Slide "Maquinas, centros... y personas" "[MODULAR]" "Capacidad finita real: centros, maquinas y operarios con habilidades.`nEl plan sabe quien puede hacer que." "Capacidad finita de operarios / habilidades / heatmap por operario" "No solo maquinas. Tambien personas, con sus habilidades. El plan sabe quien puede hacer que, y os avisa si alguien esta sobrecargado." | Out-Null

# SLIDE 9 — Lotes [MODULAR]
Content-Slide "Agrupa lo que va junto" "[MODULAR]" "Pintura por color, hornada de horno...`nAgrupa operaciones en un lote y planificalas juntas." "Crear un lote en el Gantt" "Si teneis procesos que van juntos, todas las piezas del mismo color en una pasada de pintura, varias en una misma hornada, los agrupais en un lote y se planifican juntos." | Out-Null

# SLIDE 10 — Moldes [MODULAR]
Content-Slide "Control de moldes y utillajes" "[MODULAR]" "Que molde esta en que maquina, su estado y su mantenimiento." "Gestion de moldes / utillajes" "Si trabajais con moldes o utillajes, sabeis en todo momento cual esta en cada maquina, su estado y su mantenimiento." | Out-Null

# SLIDE 11 — MRP [MODULAR]
Content-Slide "El plan mira tambien el material" "[MODULAR]" "Stock proyectado y MRP enlazado al plan:`nplanificas sabiendo si tendras material." "Modulo Plan Stock / MRP" "De que sirve un plan perfecto si os falta el material? El planner proyecta el stock y os avisa, enlazado con la planificacion." | Out-Null

# SLIDE 12 — Se adapta
Content-Slide "No es un traje de talla unica" $null "Campos propios que Sage no tiene`nCada usuario ve la pantalla a su manera`nGantt, Kanban o analisis: el mismo plan, como tu lo quieras ver" "Campos personalizados + layout por usuario + cambio de vista (Kanban / dashboard)" "Esto se ajusta a COMO trabajais vosotros, no al reves. Vuestros propios datos, vuestra forma de verlo. El mismo plan en Gantt, en Kanban o en graficos." | Out-Null

# SLIDE 13 — Crece contigo
Impact-Slide "Crece con vosotros." "Empezais con lo que necesitais hoy, y el dia que querais mas, ya esta ahi." | Out-Null

# SLIDE 14 — Tranquilidad
Content-Slide "Y si algo sale mal..." $null "Alertas automaticas`nPuntos de restauracion del plan`nDeshacer / rehacer el plan entero" "Alertas + snapshot/restaurar + undo del plan" "Os habeis equivocado? Volveis atras el plan entero con un clic. Algo se tuerce? El sistema os avisa. Dormis tranquilos." | Out-Null

# SLIDE 15 — Analisis [MODULAR]
Content-Slide "Ves la foto completa" "[MODULAR]" "Dashboard con graficos: carga, cumplimiento de entregas, ocupacion de centros." "Dashboard de analisis del plan" "Para gerencia: la foto completa de la fabrica en graficos. Donde estais justos, si cumplis entregas, como aprovechais cada centro." | Out-Null

# SLIDE 16 — ROI
$s = New-Slide
Add-Rect $s 0 0 ($SW*0.012) $SH $ACCENT | Out-Null
Add-Text $s $ML ($SH*0.16) $CW ($SH*0.18) "No es un gasto. Es una inversion que se paga sola." 30 $WHITE $true $ppAlignLeft 'Segoe UI Semibold' | Out-Null
Add-Text $s $ML ($SH*0.42) $CW ($SH*0.12) "Horas de planificacion  ->  minutos" 22 $ACCENT2 $true $ppAlignLeft | Out-Null
Add-Text $s $ML ($SH*0.56) $CW ($SH*0.12) "Mas entregas a tiempo" 22 $ACCENT2 $true $ppAlignLeft | Out-Null
Add-Text $s $ML ($SH*0.70) $CW ($SH*0.12) "Maquinas y personas mejor aprovechadas" 22 $ACCENT2 $true $ppAlignLeft | Out-Null
Set-Notes $s "Recapitulando: el tiempo que hoy dedicais a planificar se reduce a una fraccion, os adelantais a los problemas, y aprovechais mejor lo que ya teneis. Esto se paga solo. (NO decir precio: lo lleva comercial despues.)"

# SLIDE 17 — Lunes ideal
Impact-Slide "Imagina tu proximo lunes." "En vez de pelearte con un Excel, abres el plan, ves que hacer, donde estas justo, y si entra un urgente lo resuelves en segundos." | Out-Null

# SLIDE 18 — Cierre
$s = New-Slide
Add-Rect $s $ML ($SH*0.38) ($SW*0.10) 6 $ACCENT | Out-Null
Add-Text $s $ML ($SH*0.42) $CW ($SH*0.16) "Hablemos de tu fabrica" 38 $WHITE $true $ppAlignLeft 'Segoe UI Light' | Out-Null
Add-Text $s $ML ($SH*0.64) $CW ($SH*0.10) "El siguiente paso: verlo con vuestros propios datos." 18 $ACCENT2 $false $ppAlignLeft | Out-Null
Set-Notes $s "Que os ha parecido? Lo siguiente que me encantaria es ensenaros esto con mas datos vuestros, para que lo veais con vuestra realidad completa."

# ============================================================
# Guardar
# ============================================================
if (Test-Path $OutPath) { Remove-Item $OutPath -Force }
$pres.SaveAs($OutPath)
$pres.Close()
$pp.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($pp) | Out-Null
Write-Output "OK: $OutPath ($($pres.Slides.Count) slides)"
