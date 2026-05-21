# Heatmap de carga por operario

## Objetivo

Ver **cuánto está cargado cada operario** a lo largo del tiempo, comparando las horas que tiene asignadas con la capacidad real de su calendario.

Responde a preguntas como:

- ¿Quién está saturado y quién tiene margen?
- ¿Hay operarios sobre-asignados en alguna semana?
- ¿Se reparte el trabajo de forma equilibrada dentro del equipo?

## La pantalla

Una **matriz** con los operarios en las filas y los periodos en las columnas. Cada celda muestra el % de ocupación del operario en ese periodo, con un código de color que va del verde claro (poca carga) al rojo intenso (sobrecarga grave).

### Filtros (barra superior)

- **Granularidad**: Días, Semanas (por defecto) o Meses.
- **Número periodos**: cuántos periodos mostrar.
- **Desde**: fecha del primer periodo.
- **Operarios**: combo con selección múltiple. La opción "(Todos)" marca o desmarca el resto.
- **Recalcular**: fuerza el recálculo manual.

### Lectura de la matriz

- **Filas**: operarios activos de la empresa.
- **Columnas**: periodos consecutivos.
- **Celda**: % de ocupación del operario en ese periodo.
- **"---"**: el operario no tiene calendario asignado o el calendario no tiene horas laborables en ese periodo.

### Leyenda de colores

Misma escala que los otros heatmaps:

- **0%**: vacío.
- **1-50%**: verde (margen amplio).
- **51-90%**: amarillo (carga creciente).
- **91-100%**: naranja (al límite).
- **101-120%**: rojo claro (sobrecarga moderada).
- **>120%**: rojo intenso (sobrecarga grave).

## Qué datos se usan

- **La carga** se calcula a partir de las asignaciones del operario a operaciones planificadas en el plan activo. Las horas de cada asignación se reparten proporcionalmente al tiempo que la operación ocupa en cada periodo.
- **La capacidad** sale del calendario asignado al operario (horario laboral, festivos y excepciones definidos en **Gestión de Calendarios**).

> **Nota:** la versión actual no descuenta automáticamente las ausencias registradas (vacaciones, bajas...). La capacidad mostrada es la del calendario nominal del operario.

## Por qué es útil

Convierte la lista de asignaciones (operario → operación → horas) en una **vista de equipo** inmediata. Detecta desequilibrios de carga antes de que se conviertan en retrasos o en horas extra:

- Si un operario aparece rojo varias semanas seguidas, hay que redistribuir trabajo o reforzar el equipo.
- Si hay muchas filas verdes claras, sobra capacidad o falta trabajo entrado en el plan.
- Si se ve un patrón "pico-valle" semana a semana, conviene suavizar la planificación.

Complementa al **Heatmap de carga por centro** (vista agregada por puesto de trabajo) y al **Heatmap de entregas vs capacidad** (compromiso comercial).
