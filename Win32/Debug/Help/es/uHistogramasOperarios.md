# Histogramas de operarios

## Objetivo

Tres vistas complementarias del equipo en un mismo periodo de tiempo, pensadas para responder a preguntas concretas del día a día:

- **¿Quién está saturado y quién tiene margen?** (Carga por operario)
- **¿Cómo está la salud global de carga del equipo?** (Distribución de ocupación)
- **¿Cuánto nos cuesta el trabajo planificado por operario?** (Coste laboral)

## La pantalla

Todas las vistas comparten los mismos filtros en la barra superior; cambia entre ellas con las pestañas.

En la parte superior de la mayoría de pestañas hay una **banda de indicadores** del equipo: número de operarios, ocupación media, cuántos están sobrecargados, capacidad ociosa (horas libres) y coste total. Son las cifras clave de un vistazo, sin tener que leer las barras.

### Filtros (barra superior)

- **Desde / Hasta**: rango de fechas del periodo a analizar.
- **Operarios**: combo con selección múltiple. La opción "(Todos)" marca o desmarca el resto.
- **Departamento**: muestra solo los operarios de un departamento concreto. Elige "(Todos los departamentos)" para volver a verlos todos. Un operario puede pertenecer a varios departamentos.
- **Exportar CSV / Exportar PNG** (arriba a la derecha): CSV guarda la tabla completa del equipo (horas, capacidad, ocupación, tarifa y coste) para llevarla a una hoja de cálculo; PNG guarda la pestaña que estés viendo como imagen para informes o presentaciones.
- **Recalcular**: fuerza el recálculo manual (también se recalcula al cambiar cualquier filtro).

### Pestaña 1: Carga por operario

Una barra por operario en formato **bullet**: sobre una banda de fondo con tres zonas (holgado / al límite / sobrecarga) se dibuja la barra de ocupación.

- **Bandas de fondo grises**: contexto visual — claro hasta 75%, medio 75-100%, más oscuro por encima del 100% (zona de riesgo).
- **Color de la barra**: verde si la ocupación es holgada, amarillo/naranja cerca del límite y **rojo apilado** en el tramo que excede la capacidad.
- **Marca negra vertical**: la ocupación **media del equipo**, para ver de un vistazo quién está por encima o por debajo del promedio.
- **Etiqueta a la derecha**: horas asignadas / horas de capacidad y % de ocupación.
- **Ordenar**: haz clic en la cabecera "Operario" para ordenar por nombre, o en la cabecera del gráfico para ordenar por % de ocupación. Un segundo clic invierte el orden; una flecha indica el sentido.

Lectura rápida: si la barra queda dentro de la zona clara, hay holgura; si entra en la zona oscura, hay sobrecarga.

### Pestaña 2: Distribución de ocupación

Arriba, un **diagrama de caja (box plot)** resume la ocupación del equipo en una sola figura: la caja abarca del primer al tercer cuartil (el 50% central del equipo), la línea gruesa es la mediana, los bigotes llegan al mínimo y máximo normales, y los puntos rojos sueltos son casos extremos (operarios muy por encima o por debajo del resto).

Debajo, un histograma vertical con cinco columnas que cuentan **cuántos operarios** caen en cada rango de ocupación: 0-25%, 25-50%, 50-75%, 75-100% y más del 100%.

Es la vista de **salud de equipo**:

- Mucha gente en los rangos 50-75% → equipo bien dimensionado.
- Concentración en 75-100% → equipo al límite, poco margen para imprevistos.
- Cola en >100% → exceso de compromiso, hay que reorganizar o reforzar plantilla.

### Pestaña 3: Coste laboral

Una barra horizontal por operario, ordenadas de mayor a menor coste.

- **Cálculo**: horas asignadas en el periodo × sueldo por hora del operario.
- **Etiqueta a la derecha**: coste total y desglose (horas × sueldo/hora).
- **Línea discontinua vertical**: marca el coste **medio del equipo**.
- **"Sin sueldo definido"**: el operario no tiene tarifa configurada en su ficha.
- **"Sin horas asignadas"**: no tiene trabajo planificado en el periodo.
- **Ordenar**: clic en la cabecera "Operario" para ordenar por nombre, o en la del gráfico para ordenar por coste. Segundo clic invierte el orden.

> **Nota:** la versión actual usa la tarifa base de la ficha del operario. No aplica todavía los recargos de turno de noche o festivos (previstos para una versión próxima).

### Pestaña 4: Plan vs Capacidad

Dos barras grandes enfrentadas: la **capacidad total** del equipo en el periodo frente a las **horas planificadas**. La barra de planificado se pinta en verde hasta la capacidad y en **rojo apilado** si la supera.

Debajo, un resumen en una línea:

- **Margen: X h libres** (verde) cuando aún queda capacidad para aceptar más trabajo.
- **Exceso: +X h sobre capacidad** (rojo) cuando el plan compromete más horas de las disponibles.

Es la vista ejecutiva de una ojeada: ¿el equipo en su conjunto va sobrado o va justo?

### Pestaña 5: Evolución temporal

Un gráfico de línea con la **ocupación media del equipo semana a semana** dentro del rango de fechas elegido. Cada punto es una semana; la línea cambia de color según el nivel (verde holgado, azul al límite, rojo sobrecarga) y una guía horizontal marca el 100%.

Responde a la pregunta que las otras pestañas (foto fija del periodo) no contestan: **¿vamos a más o a menos carga?** Una línea que sube semana a semana avisa de una saturación que se acerca; una que baja, de capacidad que se libera.

### Pestaña 6: Proyección

Extiende la evolución **hacia el futuro**: a la parte real del plan (línea continua) le añade las próximas semanas (línea discontinua, sobre fondo sombreado) con la carga que **ya está comprometida** en el plan. No es una adivinación: proyecta los compromisos reales; si nada cambia, así irá.

- **Línea vertical "proyección →"**: separa lo ya planificado de lo proyectado.
- **Marcador rojo de aviso**: señala la **primera semana en la que se prevé sobrecarga** (>100%), con su etiqueta.
- **Resumen inferior**: en verde si no hay sobrecargas previstas; en rojo con la semana concreta si conviene reprogramar o reforzar antes de esa fecha.

Es la vista para **anticipar cuellos de botella**: ver el problema semanas antes de que llegue, cuando aún hay margen para mover trabajo o reforzar plantilla.

> **Nota:** la proyección se basa en el trabajo ya comprometido en el plan. Cuanto más lejos esté una semana, menos trabajo suele haber cargado todavía en ella, así que las últimas semanas del horizonte son orientativas.

### Pestaña 7: Pareto

Un diagrama de Pareto sobre el **coste**: barras de coste por operario ordenadas de mayor a menor, y encima una línea de **porcentaje acumulado** con una guía en el 80%.

Responde a la pregunta clásica de dirección: **¿qué pocos operarios concentran la mayor parte del coste?** El resumen inferior lo dice directamente ("X de Y operarios concentran el 80% del coste"). Útil para saber dónde enfocar cualquier análisis de coste: casi siempre una minoría explica la mayoría.

### Pestaña 8: Ocupación vs Coste

Un gráfico de dispersión donde cada operario es una **burbuja**: su posición horizontal es la ocupación (%), la vertical el coste, y el **tamaño de la burbuja** las horas asignadas. El color sigue el nivel de ocupación (verde/naranja/rojo).

Dos líneas discontinuas marcan la media del equipo, dividiendo el gráfico en cuatro zonas. La lectura interesante está en las esquinas:

- **Arriba a la izquierda** (caro y poco ocupado): candidatos a revisar — cuestan mucho para lo que producen.
- **Abajo a la derecha** (muy ocupado y barato): los más eficientes.

Es una vista de análisis puro para detectar desequilibrios entre lo que cuesta cada persona y cuánto se le está aprovechando.

## Qué datos se usan

- **Las horas asignadas** salen de las asignaciones del operario a operaciones planificadas en el plan activo, recortadas al rango de fechas que indiques.
- **La capacidad** es la de su calendario asignado (definida en **Gestión de Calendarios**).
- **La tarifa** es el sueldo por hora de la ficha del operario.

## Por qué es útil

Pensado para tres perfiles distintos:

- **Jefe de producción**: la pestaña *Carga por operario* es la foto rápida de quién tira del equipo y quién está descargado, ordenada para que los problemas aparezcan arriba.
- **Dirección / RRHH**: la pestaña *Distribución* es la métrica ejecutiva — una sola imagen para decidir si la plantilla está bien dimensionada.
- **Controlling / Administración**: la pestaña *Coste* da el coste del periodo por persona, base para presupuestos y comparativas mensuales.

Las tres comparten filtros, así que cambiar de pestaña reutiliza los datos: una sola consulta sirve para los tres ángulos.

Combínalo con:

- **Heatmap de carga por operario**: para ver cómo evoluciona en el tiempo (semana a semana), no solo el agregado del periodo.
- **Heatmap de entregas vs capacidad**: para anticipar si el equipo va a poder con los compromisos comerciales antes de planificar.
