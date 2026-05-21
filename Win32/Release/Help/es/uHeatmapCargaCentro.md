# Heatmap de carga por centro

## Objetivo

Visualizar de un vistazo **cómo está cargado cada centro de trabajo** a lo largo del tiempo, comparando las horas de trabajo planificadas con la capacidad real de cada centro.

Sirve para responder preguntas como:

- ¿Qué centros están saturados las próximas semanas?
- ¿Dónde hay holgura para meter más trabajo?
- ¿Qué periodos están sobrecargados y necesitan replanificación?

## La pantalla

Una **matriz** con los centros en las filas y los periodos de tiempo en las columnas. Cada celda muestra el % de ocupación del centro durante ese periodo, con un código de color que va del verde claro (poco uso) al rojo intenso (sobrecarga).

### Filtros (barra superior)

- **Granularidad**: Días, Semanas (por defecto) o Meses. Cambia la anchura de cada periodo.
- **Número periodos**: cuántos periodos mostrar a partir de la fecha de inicio.
- **Desde**: fecha del primer periodo. Para semanas se ajusta al lunes; para meses al día 1.
- **Centros**: combo con selección múltiple para filtrar qué centros aparecen. La opción "(Todos)" marca o desmarca el resto.
- **Recalcular**: fuerza el recálculo manual (también se recalcula al cambiar cualquier filtro).

### Lectura de la matriz

- **Filas**: centros de trabajo activos del plan actual.
- **Columnas**: periodos consecutivos según la granularidad escogida.
- **Celda**: porcentaje de ocupación del centro durante ese periodo.
- **"---"**: el centro no tiene calendario asignado o el calendario no tiene horas laborables en ese periodo.

### Leyenda de colores

Escala fina de 9 rangos:

- **0%**: vacío.
- **1-50%**: tonos de verde (margen amplio).
- **51-90%**: amarillo / verde-amarillo (carga creciente pero saludable).
- **91-100%**: naranja (capacidad casi al límite).
- **101-120%**: rojo claro (sobrecarga moderada, replanificable).
- **>120%**: rojo intenso (sobrecarga grave, requiere acción inmediata).

## Qué datos se usan

- **La carga** se calcula a partir de las operaciones planificadas en el plan activo. Si una operación cubre varios periodos, sus horas se reparten proporcionalmente al tiempo que ocupa en cada uno.
- **La capacidad** sale del calendario asignado al centro (horario laboral, festivos y excepciones definidos en **Gestión de Calendarios**).

Si modificas el plan o los calendarios, basta con pulsar **Recalcular** (o cambiar cualquier filtro) para ver los nuevos valores.

## Por qué es útil

Es la **vista ejecutiva de la planificación**: en pocos segundos identifica los cuellos de botella y los huecos. Complementa al Gantt, que muestra el detalle por operación pero hace más difícil ver el agregado por centro y semana.

Combínalo con:

- **Heatmap de entregas vs capacidad**: para anticipar compromisos comerciales antes de que entren al plan.
- **Heatmap de carga por operario**: para bajar al detalle de quién está saturado dentro del centro.
