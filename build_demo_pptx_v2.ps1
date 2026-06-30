# Genera v2 del PowerPoint de demo FS Planner.
# Novedades: paleta verde Sage, splash blueprint Gantt, iconos outline marca de
# agua, badge Sage Tech Partner en cada slide, slide credibilidad ISV, acentos.

$ErrorActionPreference = 'Stop'

# --- Paleta (BGR para PowerPoint COM) ---
$BG        = 0x2B2620   # fondo oscuro
$BG2       = 0x1E1A16   # fondo mas oscuro (degradado)
$WHITE     = 0xFFFFFF
$SAGE      = 0x39D600   # verde Sage #00d639 -> BGR 0x39D600
$SAGE_DIM  = 0x2E7A1A   # verde apagado para marcas de agua
$GREY      = 0xB8B8B8
$DARKPANEL = 0x3A332B
$LINEGREY  = 0x4A443C

$msoTrue = -1; $msoFalse = 0
$ppLayoutBlank = 12
$msoShapeRectangle = 1
$msoShapeRoundedRectangle = 5
$msoShapeOval = 9
$msoTextOrientationHorizontal = 1
$ppAlignLeft = 1; $ppAlignCenter = 2
$ppAnchorMiddle = 3; $ppAnchorTop = 1
$msoConnectorStraight = 1

$AssetDir = 'd:\PROJECTES\GANTT\GANTT\_demo_assets'
$BadgeSage = "$AssetDir\sage_isv.png"      # "Sage Tech Partner"
$LogoSage  = "$AssetDir\sage_logo.png"
$OutPath   = 'd:\PROJECTES\GANTT\GANTT\Demo_Comercial_Planner_v2.pptx'

$pp = New-Object -ComObject PowerPoint.Application
$pres = $pp.Presentations.Add($msoFalse)
$pres.PageSetup.SlideSize = 15  # 16:9
$SW = $pres.PageSetup.SlideWidth
$SH = $pres.PageSetup.SlideHeight
$ML = $SW * 0.08
$CW = $SW * 0.84

function New-Slide {
    param([bool]$withBadge = $true)
    $slide = $pres.Slides.Add($pres.Slides.Count + 1, $ppLayoutBlank)
    $slide.FollowMasterBackground = $msoFalse
    $slide.Background.Fill.Solid()
    $slide.Background.Fill.ForeColor.RGB = $BG
    if ($withBadge -and (Test-Path $BadgeSage)) {
        # Badge "Sage Tech Partner" en la esquina inferior derecha, pequeno.
        $bw = $SW * 0.16
        $bh = $bw * (100.0/436.0)
        $slide.Shapes.AddPicture($BadgeSage, $msoFalse, $msoTrue, ($SW - $bw - $SW*0.03), ($SH - $bh - $SH*0.05), $bw, $bh) | Out-Null
    }
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
    $sh.Fill.Solid(); $sh.Fill.ForeColor.RGB = $color; $sh.Line.Visible = $msoFalse
    return $sh
}

function Add-Line {
    param($slide, $x1, $y1, $x2, $y2, $color, $weight, $transparency)
    $ln = $slide.Shapes.AddConnector($msoConnectorStraight, $x1, $y1, $x2, $y2)
    $ln.Line.ForeColor.RGB = $color
    $ln.Line.Weight = $weight
    if ($transparency) { $ln.Line.Transparency = $transparency }
    return $ln
}

function Set-Notes {
    param($slide, $text)
    $ns = $slide.NotesPage.Shapes
    for ($i = 1; $i -le $ns.Count; $i++) {
        if ($ns.Item($i).HasTextFrame -eq $msoTrue) {
            try {
                if ($ns.Item($i).PlaceholderFormat.Type -eq 2) {
                    $ns.Item($i).TextFrame.TextRange.Text = $text; return
                }
            } catch {}
        }
    }
}

# --- Marca de agua: icono outline gigante en el lado derecho ---
# Tipo: 'gantt','plug','spark','arrows','person','boxes','gear','stock','puzzle','shield','growth','chart','flag'
function Add-Watermark {
    param($slide, $type)
    $cx = $SW * 0.80; $cy = $SH * 0.50
    $S  = $SH * 0.30   # tamano base
    $col = $SAGE_DIM
    $w = 2.0
    $tr = 70  # transparencia linea (%)
    switch ($type) {
        'gantt' {
            for ($i=0; $i -lt 4; $i++) {
                $yy = $cy - $S*0.45 + $i*($S*0.30)
                $x1 = $cx - $S*0.6 + ($i*$S*0.12)
                $x2 = $x1 + $S*0.7 - ($i*$S*0.05)
                $r = $slide.Shapes.AddShape($msoShapeRoundedRectangle, $x1, $yy, ($x2-$x1), $S*0.16)
                $r.Fill.Visible=$msoFalse; $r.Line.ForeColor.RGB=$col; $r.Line.Weight=$w; $r.Line.Transparency=0.7
            }
        }
        'plug' {
            $r = $slide.Shapes.AddShape($msoShapeRoundedRectangle, ($cx-$S*0.5), ($cy-$S*0.4), $S, $S*0.8)
            $r.Fill.Visible=$msoFalse; $r.Line.ForeColor.RGB=$col; $r.Line.Weight=$w; $r.Line.Transparency=0.7
            Add-Line $slide ($cx-$S*0.5) $cy ($cx-$S*0.9) $cy $col $w 0.7 | Out-Null
            Add-Line $slide ($cx+$S*0.5) $cy ($cx+$S*0.9) $cy $col $w 0.7 | Out-Null
        }
        'spark' {
            $o = $slide.Shapes.AddShape($msoShapeOval, ($cx-$S*0.4), ($cy-$S*0.4), $S*0.8, $S*0.8)
            $o.Fill.Visible=$msoFalse; $o.Line.ForeColor.RGB=$col; $o.Line.Weight=$w; $o.Line.Transparency=0.7
            Add-Line $slide $cx ($cy-$S*0.7) $cx ($cy-$S*0.45) $col $w 0.7 | Out-Null
            Add-Line $slide ($cx+$S*0.6) $cy ($cx+$S*0.45) $cy $col $w 0.7 | Out-Null
        }
        'arrows' {
            Add-Line $slide ($cx-$S*0.6) ($cy-$S*0.2) ($cx+$S*0.6) ($cy-$S*0.2) $col $w 0.7 | Out-Null
            Add-Line $slide ($cx+$S*0.6) ($cy+$S*0.2) ($cx-$S*0.6) ($cy+$S*0.2) $col $w 0.7 | Out-Null
            Add-Line $slide ($cx+$S*0.6) ($cy-$S*0.2) ($cx+$S*0.4) ($cy-$S*0.35) $col $w 0.7 | Out-Null
            Add-Line $slide ($cx-$S*0.6) ($cy+$S*0.2) ($cx-$S*0.4) ($cy+$S*0.35) $col $w 0.7 | Out-Null
        }
        'person' {
            $o = $slide.Shapes.AddShape($msoShapeOval, ($cx-$S*0.2), ($cy-$S*0.5), $S*0.4, $S*0.4)
            $o.Fill.Visible=$msoFalse; $o.Line.ForeColor.RGB=$col; $o.Line.Weight=$w; $o.Line.Transparency=0.7
            $b = $slide.Shapes.AddShape($msoShapeRoundedRectangle, ($cx-$S*0.35), ($cy-$S*0.05), $S*0.7, $S*0.6)
            $b.Fill.Visible=$msoFalse; $b.Line.ForeColor.RGB=$col; $b.Line.Weight=$w; $b.Line.Transparency=0.7
        }
        'boxes' {
            foreach ($p in @(@(-0.4,-0.4),@(0.05,-0.4),@(-0.4,0.05),@(0.05,0.05))) {
                $r = $slide.Shapes.AddShape($msoShapeRectangle, ($cx+$S*$p[0]), ($cy+$S*$p[1]), $S*0.35, $S*0.35)
                $r.Fill.Visible=$msoFalse; $r.Line.ForeColor.RGB=$col; $r.Line.Weight=$w; $r.Line.Transparency=0.7
            }
        }
        'gear' {
            $o = $slide.Shapes.AddShape($msoShapeOval, ($cx-$S*0.4), ($cy-$S*0.4), $S*0.8, $S*0.8)
            $o.Fill.Visible=$msoFalse; $o.Line.ForeColor.RGB=$col; $o.Line.Weight=$w; $o.Line.Transparency=0.7
            $o2 = $slide.Shapes.AddShape($msoShapeOval, ($cx-$S*0.15), ($cy-$S*0.15), $S*0.3, $S*0.3)
            $o2.Fill.Visible=$msoFalse; $o2.Line.ForeColor.RGB=$col; $o2.Line.Weight=$w; $o2.Line.Transparency=0.7
        }
        'stock' {
            $r = $slide.Shapes.AddShape($msoShapeRectangle, ($cx-$S*0.4), ($cy-$S*0.4), $S*0.8, $S*0.8)
            $r.Fill.Visible=$msoFalse; $r.Line.ForeColor.RGB=$col; $r.Line.Weight=$w; $r.Line.Transparency=0.7
            Add-Line $slide ($cx-$S*0.4) ($cy-$S*0.1) ($cx+$S*0.4) ($cy-$S*0.1) $col $w 0.7 | Out-Null
            Add-Line $slide $cx ($cy-$S*0.4) $cx ($cy-$S*0.1) $col $w 0.7 | Out-Null
        }
        'puzzle' {
            $r = $slide.Shapes.AddShape($msoShapeRectangle, ($cx-$S*0.4), ($cy-$S*0.4), $S*0.45, $S*0.45)
            $r.Fill.Visible=$msoFalse; $r.Line.ForeColor.RGB=$col; $r.Line.Weight=$w; $r.Line.Transparency=0.7
            $r2 = $slide.Shapes.AddShape($msoShapeRectangle, ($cx+$S*0.0), ($cy+$S*0.0), $S*0.45, $S*0.45)
            $r2.Fill.Visible=$msoFalse; $r2.Line.ForeColor.RGB=$col; $r2.Line.Weight=$w; $r2.Line.Transparency=0.7
        }
        'shield' {
            $r = $slide.Shapes.AddShape($msoShapeRoundedRectangle, ($cx-$S*0.35), ($cy-$S*0.45), $S*0.7, $S*0.9)
            $r.Fill.Visible=$msoFalse; $r.Line.ForeColor.RGB=$col; $r.Line.Weight=$w; $r.Line.Transparency=0.7
        }
        'growth' {
            Add-Line $slide ($cx-$S*0.5) ($cy+$S*0.4) ($cx-$S*0.1) ($cy-$S*0.0) $col $w 0.7 | Out-Null
            Add-Line $slide ($cx-$S*0.1) ($cy-$S*0.0) ($cx+$S*0.5) ($cy-$S*0.5) $col $w 0.7 | Out-Null
            Add-Line $slide ($cx+$S*0.5) ($cy-$S*0.5) ($cx+$S*0.2) ($cy-$S*0.5) $col $w 0.7 | Out-Null
            Add-Line $slide ($cx+$S*0.5) ($cy-$S*0.5) ($cx+$S*0.5) ($cy-$S*0.2) $col $w 0.7 | Out-Null
        }
        'chart' {
            for ($i=0; $i -lt 4; $i++) {
                $h = $S*0.3 + $i*$S*0.18
                $xx = $cx - $S*0.5 + $i*$S*0.28
                $r = $slide.Shapes.AddShape($msoShapeRectangle, $xx, ($cy+$S*0.5-$h), $S*0.18, $h)
                $r.Fill.Visible=$msoFalse; $r.Line.ForeColor.RGB=$col; $r.Line.Weight=$w; $r.Line.Transparency=0.7
            }
        }
        'flag' {
            Add-Line $slide ($cx-$S*0.4) ($cy-$S*0.5) ($cx-$S*0.4) ($cy+$S*0.5) $col $w 0.7 | Out-Null
            $r = $slide.Shapes.AddShape($msoShapeRectangle, ($cx-$S*0.4), ($cy-$S*0.5), $S*0.7, $S*0.4)
            $r.Fill.Visible=$msoFalse; $r.Line.ForeColor.RGB=$col; $r.Line.Weight=$w; $r.Line.Transparency=0.7
        }
        'levels' {
            # Capas apiladas (niveles de planificacion)
            for ($i=0; $i -lt 4; $i++) {
                $yy = $cy - $S*0.45 + $i*($S*0.28)
                $ww = $S*1.0 - $i*$S*0.14
                $r = $slide.Shapes.AddShape($msoShapeRoundedRectangle, ($cx-$ww/2), $yy, $ww, $S*0.18)
                $r.Fill.Visible=$msoFalse; $r.Line.ForeColor.RGB=$col; $r.Line.Weight=$w; $r.Line.Transparency=0.7
            }
        }
        'sliders' {
            # Controles deslizantes (reglas / parametros)
            for ($i=0; $i -lt 3; $i++) {
                $yy = $cy - $S*0.35 + $i*($S*0.35)
                Add-Line $slide ($cx-$S*0.5) $yy ($cx+$S*0.5) $yy $col $w 0.7 | Out-Null
                $knob = $slide.Shapes.AddShape($msoShapeOval, ($cx - $S*0.5 + $S*(0.2+0.3*$i) - $S*0.07), ($yy-$S*0.07), $S*0.14, $S*0.14)
                $knob.Fill.Visible=$msoFalse; $knob.Line.ForeColor.RGB=$col; $knob.Line.Weight=$w; $knob.Line.Transparency=0.7
            }
        }
    }
}

# ============================================================
# SLIDE 1 — PORTADA SPLASH (blueprint Gantt)
# ============================================================
$s = New-Slide $false
# Fondo degradado
$s.Background.Fill.TwoColorGradient(1, 1)
$s.Background.Fill.ForeColor.RGB = $BG2
$s.Background.Fill.BackColor.RGB = $BG
# Blueprint: lineas verticales tenues (timeline)
for ($i=1; $i -lt 14; $i++) {
    $x = $SW * ($i/14.0)
    Add-Line $s $x 0 $x $SH $LINEGREY 0.75 0.6 | Out-Null
}
# Blueprint: barras Gantt tenues
$bars = @(@(0.10,0.30,0.28),@(0.32,0.42,0.20),@(0.18,0.55,0.30),@(0.40,0.66,0.18),@(0.25,0.78,0.35))
foreach ($b in $bars) {
    $r = $s.Shapes.AddShape($msoShapeRoundedRectangle, ($SW*$b[0]), ($SH*$b[1]), ($SW*$b[2]), ($SH*0.045))
    $r.Fill.Solid(); $r.Fill.ForeColor.RGB = $SAGE; $r.Fill.Transparency = 0.82; $r.Line.Visible=$msoFalse
}
# Barra de acento + titulo
Add-Rect $s $ML ($SH*0.38) ($SW*0.10) 6 $SAGE | Out-Null
Add-Text $s $ML ($SH*0.42) ($CW*0.92) ($SH*0.22) "La planificacion de tu fabrica, por fin bajo control." 42 $WHITE $true $ppAlignLeft 'Segoe UI Light' | Out-Null
Add-Text $s $ML ($SH*0.70) $CW ($SH*0.08) "Integrado y certificado con Sage 200" 18 $SAGE $false $ppAlignLeft | Out-Null
# Badge en portada (un poco mayor, centrado abajo opcional). Lo ponemos arriba-dcha.
if (Test-Path $BadgeSage) {
    $bw = $SW * 0.18; $bh = $bw * (100.0/436.0)
    $s.Shapes.AddPicture($BadgeSage, $msoFalse, $msoTrue, ($SW - $bw - $SW*0.05), ($SH*0.07), $bw, $bh) | Out-Null
}
Set-Notes $s "Gracias por el tiempo. En esta hora os voy a ensenar algo que creo que os va a gustar. No vengo a deciros como trabajais hoy, eso ya lo sabeis vosotros mejor que nadie, vengo a ensenaros como podriais trabajar."

# ============================================================
# SLIDE 2 — Promesa
# ============================================================
$s = New-Slide
Add-Watermark $s 'spark'
Add-Text $s $ML ($SH*0.20) $CW ($SH*0.10) "Tres ideas para toda la sesion" 20 $GREY $false $ppAlignLeft | Out-Null
Add-Text $s $ML ($SH*0.40) $CW ($SH*0.20) "Simple   .   Conectado   .   A tu medida" 38 $WHITE $true $ppAlignLeft 'Segoe UI Semibold' | Out-Null
Add-Rect $s $ML ($SH*0.62) ($SW*0.20) 4 $SAGE | Out-Null
Set-Notes $s "Tres ideas: es facil de usar, habla con vuestro Sage solo, y se adapta a como trabajais vosotros."

# ============================================================
# Helpers de contenido / impacto
# ============================================================
function Content-Slide {
    param($titular, $subtitulo, $cuerpo, $producto, $notas, $icon)
    $s = New-Slide
    if ($icon) { Add-Watermark $s $icon }
    Add-Rect $s 0 0 ($SW*0.012) $SH $SAGE | Out-Null
    Add-Text $s $ML ($SH*0.16) ($CW*0.95) ($SH*0.16) $titular 32 $WHITE $true $ppAlignLeft 'Segoe UI Semibold' | Out-Null
    $y = $SH*0.34
    if ($subtitulo) { Add-Text $s $ML $y ($CW*0.95) ($SH*0.10) $subtitulo 20 $SAGE $false $ppAlignLeft | Out-Null; $y = $SH*0.46 }
    if ($cuerpo) { Add-Text $s $ML $y ($CW*0.72) ($SH*0.30) $cuerpo 19 $GREY $false $ppAlignLeft | Out-Null }
    if ($producto) {
        $py = $SH*0.78
        Add-Rect $s $ML $py ($CW*0.72) ($SH*0.11) $DARKPANEL | Out-Null
        Add-Text $s ($ML+18) ($py+8) ($CW*0.70) ($SH*0.09) ("DEMO EN VIVO   >   " + $producto) 15 $SAGE $true $ppAlignLeft | Out-Null
    }
    if ($notas) { Set-Notes $s $notas }
    return $s
}

function Impact-Slide {
    param($frase, $notas, $icon)
    $s = New-Slide
    if ($icon) { Add-Watermark $s $icon }
    Add-Rect $s ($SW*0.40) ($SH*0.30) ($SW*0.20) 5 $SAGE | Out-Null
    Add-Text $s ($SW*0.10) ($SH*0.40) ($SW*0.80) ($SH*0.22) $frase 34 $WHITE $true $ppAlignCenter 'Segoe UI Light' $ppAnchorMiddle | Out-Null
    if ($notas) { Set-Notes $s $notas }
    return $s
}

# ============================================================
# SLIDE 3 — Sage 200
Content-Slide "No cambies nada de lo que ya tienes" "Tus ordenes ya estan en Sage 200." $null "Backlog con las ordenes reales de Sage 200" "Lo primero: no teneis que cambiar nada. Estas son vuestras ordenes, directas de Sage, sin teclear nada." 'plug' | Out-Null

# SLIDE 4 — CREDIBILIDAD ISV (nueva)
$s = New-Slide $false
Add-Rect $s 0 0 ($SW*0.012) $SH $SAGE | Out-Null
Add-Text $s $ML ($SH*0.18) $CW ($SH*0.16) "No te lo decimos solo nosotros." 32 $WHITE $true $ppAlignLeft 'Segoe UI Semibold' | Out-Null
Add-Text $s $ML ($SH*0.38) ($CW*0.9) ($SH*0.18) "Somos ISV certificados de Sage. Nuestro software esta homologado. De hecho, el propio Sage lo vende como fabricante." 22 $GREY $false $ppAlignLeft | Out-Null
if (Test-Path $LogoSage) {
    $lw = $SW*0.16; $lh = $lw * (630.0/1122.0)
    $s.Shapes.AddPicture($LogoSage, $msoFalse, $msoTrue, $ML, ($SH*0.66), $lw, $lh) | Out-Null
}
if (Test-Path $BadgeSage) {
    $bw = $SW*0.16; $bh = $bw*(100.0/436.0)
    $s.Shapes.AddPicture($BadgeSage, $msoFalse, $msoTrue, ($ML+$SW*0.22), ($SH*0.69), $bw, $bh) | Out-Null
}
Set-Notes $s "Esto es importante: no somos un proveedor cualquiera. Somos ISV certificados, nuestro software esta homologado por Sage, y Sage nos vende como fabricante. La version 1 de este planner ya la vende el propio Sage."

# SLIDE 5 — Cierre conexion
Impact-Slide "Conectado. Cero trabajo doble." "Lo que ahora copiais a mano a un Excel cada manana, aqui ya esta." 'arrows' | Out-Null

# SLIDE 6 — La magia (ESTRELLA)
Content-Slide "Y aqui empieza la magia" "De una lista de ordenes... a un plan real, en segundos." "1. Seleccionar ordenes y planificar (Express / wizard)`n2. El Gantt se llena, ordenado`n3. Heatmap: rojos de sobrecarga -> reequilibrar -> verdes`n4. Arrastrar un urgente -> todo se recoloca solo" "Planificacion Express -> Gantt -> Heatmap -> arrastrar urgente" "Mira que facil. En segundos: un plan completo, respetando calendarios, turnos, sin que dos cosas choquen. Y ver donde os vais a saturar ANTES de que pase. (Silencio 2 segundos.)" 'gantt' | Out-Null

# SLIDE 7 — Cierre magia
Impact-Slide "De horas de Excel... a segundos." "Esto en Excel es imposible, o os lleva horas y aun asi con errores." 'spark' | Out-Null

# SLIDE 8 — Formas de planificar
# SLIDE — Decide QUE planificar (nivel)
Content-Slide "Tu decides QUE planificar" $null "Ordenes de fabricacion enteras`nOrdenes de trabajo`nOperaciones o fases`nPedidos o lineas de pedido`nTareas de proyectos`nTareas personalizadas (no estan ni en el ERP)" "Backlog: elegir el nivel de planificacion" "Cada fabrica trabaja distinto. Aqui planificais al nivel que querais: la orden entera, una fase concreta, una linea de pedido, una tarea de proyecto... o tareas propias que ni estan en Sage." 'levels' | Out-Null

# SLIDE — Tu eliges COMO planificar
Content-Slide "Tu eliges COMO planificar" $null "Automatica hacia adelante (desde hoy) o hacia atras (desde la entrega)`nManual, a tu ritmo`nPor reglas de prioridad`nComparas metodos y te quedas con el mejor" "Wizard con distintos modos / comparativa de metodos" "Hacia adelante desde hoy, hacia atras desde la entrega, por reglas, o a mano. Incluso comparar metodos y quedaros con el mejor." 'arrows' | Out-Null

# SLIDE — Tus propias reglas, campos y algoritmos
Content-Slide "Planifica con TUS reglas" $null "Define tus propias reglas de prioridad`nUsa tus propios campos en la decision`nMotor de planificacion configurable a tu logica" "Motor de reglas / parametros de planificacion" "Y vais mas alla: definis vuestras propias reglas de prioridad, usais vuestros propios campos, y el motor planifica segun VUESTRA logica, no una generica." 'sliders' | Out-Null

# SLIDE 9 — Capacidad finita [MODULAR]
Content-Slide "Maquinas, centros... y personas" "[MODULAR]" "Capacidad finita real: centros, maquinas y operarios con habilidades.`nEl plan sabe quien puede hacer que." "Capacidad finita de operarios / habilidades / heatmap por operario" "No solo maquinas. Tambien personas, con sus habilidades. El plan sabe quien puede hacer que." 'person' | Out-Null

# SLIDE 10 — Lotes [MODULAR]
Content-Slide "Agrupa lo que va junto" "[MODULAR]" "Pintura por color, hornada de horno...`nAgrupa operaciones en un lote y planificalas juntas." "Crear un lote en el Gantt" "Procesos que van juntos, todas las piezas del mismo color en una pasada de pintura, los agrupais en un lote." 'boxes' | Out-Null

# SLIDE 11 — Moldes [MODULAR]
Content-Slide "Control de moldes y utillajes" "[MODULAR]" "Que molde esta en que maquina, su estado y su mantenimiento." "Gestion de moldes / utillajes" "Si trabajais con moldes, sabeis en todo momento cual esta en cada maquina, su estado y su mantenimiento." 'gear' | Out-Null

# SLIDE 12 — MRP [MODULAR]
Content-Slide "El plan mira tambien el material" "[MODULAR]" "Stock proyectado y MRP enlazado al plan:`nplanificas sabiendo si tendras material." "Modulo Plan Stock / MRP" "De que sirve un plan perfecto si os falta el material? El planner proyecta el stock y os avisa." 'stock' | Out-Null

# SLIDE — Personaliza que ver y como
Content-Slide "Personaliza QUE quieres ver y COMO" $null "Elige las columnas y los datos que te importan`nOrdena, filtra y agrupa a tu manera`nGantt, Kanban o graficos: la misma realidad, tu vista`nCada usuario guarda su propia configuracion" "Personalizar columnas / vistas / layout por usuario" "No os imponemos una pantalla. Cada uno elige que datos ve, como los ordena, y en que formato: Gantt, Kanban o graficos. Y cada usuario guarda lo suyo." 'puzzle' | Out-Null

# SLIDE 13 — Se adapta
Content-Slide "No es un traje de talla unica" $null "Campos propios que Sage no tiene`nDatos que solo tu fabrica necesita`nEl planner se moldea a vuestro proceso" "Campos personalizados que Sage no tiene" "Esto se ajusta a COMO trabajais vosotros, no al reves. Vuestros propios datos, que ni Sage tiene, conviven en el plan." 'gear' | Out-Null

# SLIDE 14 — Crece contigo
Impact-Slide "Crece con vosotros." "Empezais con lo que necesitais hoy, y el dia que querais mas, ya esta ahi." 'growth' | Out-Null

# SLIDE 15 — Tranquilidad
Content-Slide "Y si algo sale mal..." $null "Alertas automaticas`nPuntos de restauracion del plan`nDeshacer / rehacer el plan entero" "Alertas + snapshot/restaurar + undo del plan" "Os habeis equivocado? Volveis atras el plan entero con un clic. Algo se tuerce? El sistema os avisa." 'shield' | Out-Null

# SLIDE 16 — Analisis [MODULAR]
Content-Slide "Ves la foto completa" "[MODULAR]" "Dashboard con graficos: carga, cumplimiento de entregas, ocupacion de centros." "Dashboard de analisis del plan" "Para gerencia: la foto completa de la fabrica en graficos." 'chart' | Out-Null

# SLIDE 17 — ROI
$s = New-Slide
Add-Watermark $s 'growth'
Add-Rect $s 0 0 ($SW*0.012) $SH $SAGE | Out-Null
Add-Text $s $ML ($SH*0.16) ($CW*0.9) ($SH*0.18) "No es un gasto. Es una inversion que se paga sola." 30 $WHITE $true $ppAlignLeft 'Segoe UI Semibold' | Out-Null
Add-Text $s $ML ($SH*0.42) $CW ($SH*0.12) "Horas de planificacion  ->  minutos" 22 $SAGE $true $ppAlignLeft | Out-Null
Add-Text $s $ML ($SH*0.56) $CW ($SH*0.12) "Mas entregas a tiempo" 22 $SAGE $true $ppAlignLeft | Out-Null
Add-Text $s $ML ($SH*0.70) $CW ($SH*0.12) "Maquinas y personas mejor aprovechadas" 22 $SAGE $true $ppAlignLeft | Out-Null
Set-Notes $s "El tiempo que hoy dedicais a planificar se reduce a una fraccion, os adelantais a los problemas. Se paga solo. (NO decir precio: lo lleva comercial.)"

# SLIDE 18 — Lunes ideal
Impact-Slide "Imagina tu proximo lunes." "En vez de pelearte con un Excel, abres el plan, ves que hacer, y si entra un urgente lo resuelves en segundos." 'flag' | Out-Null

# SLIDE 19 — Cierre
$s = New-Slide
Add-Rect $s $ML ($SH*0.36) ($SW*0.10) 6 $SAGE | Out-Null
Add-Text $s $ML ($SH*0.40) $CW ($SH*0.16) "Hablemos de tu fabrica" 38 $WHITE $true $ppAlignLeft 'Segoe UI Light' | Out-Null
Add-Text $s $ML ($SH*0.62) $CW ($SH*0.10) "El siguiente paso: verlo con vuestros propios datos." 18 $SAGE $false $ppAlignLeft | Out-Null
Set-Notes $s "Que os ha parecido? Lo siguiente: ensenaros esto con mas datos vuestros."

# Guardar
if (Test-Path $OutPath) { Remove-Item $OutPath -Force }
$pres.SaveAs($OutPath)
$n = $pres.Slides.Count
$pres.Close()
$pp.Quit()
Write-Output "OK: $OutPath ($n slides)"
