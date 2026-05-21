# Histogramas de operarios

## Objetivo

Tres vistas complementarias del equipo en un mismo periodo de tiempo, pensadas para responder a preguntas concretas del día a día:

- **¿Quién está saturado y quién tiene margen?** (Carga por operario)
- **¿Cómo está la salud global de carga del equipo?** (Distribución de ocupación)
- **¿Cuánto nos cuesta el trabajo planificado por operario?** (Coste laboral)

## La pantalla

Todas las vistas comparten los mismos filtros en la barra superior; cambia entre ellas con las pestañas.

### Filtros (barra superior)

- **Desde / Hasta**: rango de fechas del periodo a analizar.
- **Operarios**: combo con selección múltiple. La opción "(Todos)" marca o desmarca el resto.
- **Recalcular**: fuerza el recálculo manual (también se recalcula al cambiar cualquier filtro).

### Pestaña 1: Carga por operario

Una barra horizontal por operario, ordenadas de más cargado a menos.

- **Color de la barra**: verde si la ocupación es holgada, amarillo cuando se acerca al límite, naranja cerca del 100% y **rojo apilado** en el tramo que excede la capacidad.
- **Línea fina vertical**: marca la capacidad real del operario para ese periodo.
- **Etiqueta a la derecha**: horas asignadas / horas de capacidad y % de ocupación.

Lectura rápida: si una barra termina antes de la línea fina, hay holgura; si la rebasa con un trozo rojo, hay sobrecarga real.

### Pestaña 2: Distribución de ocupación

Histograma vertical con cinco columnas que cuentan **cuántos operarios** caen en cada rango de ocupación: 0-25%, 25-50%, 50-75%, 75-100% y más del 100%.

Es la vista de **salud de equipo**:

- Mucha gente en los rangos 50-75% → equipo bien dimensionado.
- Concentración en 75-100% → equipo al límite, poco margen para imprevistos.
- Cola en >100% → exceso de compromiso, hay que reorganizar o reforzar plantilla.

### Pestaña 3: Coste laboral

Una barra horizontal por operario, ordenadas de mayor a menor coste.

- **Cálculo**: horas asignadas en el periodo × sueldo por hora del operario.
- **Etiqueta a la derecha**: coste total y desglose (horas × sueldo/hora).
- **"Sin sueldo definido"**: el operario no tiene tarifa configurada en su ficha.
- **"Sin horas asignadas"**: no tiene trabajo planificado en el periodo.

> **Nota:** la versión actual usa la tarifa base de la ficha del operario. No aplica todavía los recargos de turno de noche o festivos (previstos para una versión próxima).

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
