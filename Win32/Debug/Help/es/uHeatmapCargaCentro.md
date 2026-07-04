# Heatmap de carga por centro

## Objetivo

Visualizar de un vistazo **cómo está cargado cada centro de trabajo** a lo largo del tiempo, comparando las horas de trabajo planificadas con la capacidad real de cada centro.

Sirve para responder preguntas como:

- ¿Qué centros están saturados las próximas semanas?
- ¿Dónde hay holgura para meter más trabajo?
- ¿Qué periodos están sobrecargados y necesitan replanificación?

## La pantalla

La pantalla tiene tres pestañas que comparten los mismos filtros:

- **Matriz**: la vista principal (centros × periodos con color de saturación).
- **Pareto de sobrecarga**: qué pocos centros concentran el exceso de carga.
- **Capacidad (cascada)**: dónde se consume la capacidad del taller y cuánto margen queda.

### Pestaña Matriz

Una **matriz** con los centros en las filas y los periodos de tiempo en las columnas. Cada celda muestra el % de ocupación del centro durante ese periodo, con un código de color que va del verde claro (poco uso) al rojo intenso (sobrecarga).

### Filtros (barra superior)

- **Granularidad**: Días, Semanas (por defecto) o Meses. Cambia la anchura de cada periodo.
- **Periodos**: cuántos periodos mostrar a partir de la fecha de inicio.
- **Desde**: fecha del primer periodo. Para semanas se ajusta al lunes; para meses al día 1.
- **Centros**: combo con selección múltiple para filtrar qué centros aparecen. La opción "(Todos)" marca o desmarca el resto.
- **Área**: muestra solo los centros de un área concreta de la empresa. Elige "(Todas las áreas)" para volver a verlos todos.
- **Ver detalle**: activa una vista ampliada donde cada celda muestra, además del %, las horas planificadas frente a las disponibles y el número de tareas.
- **Exportar CSV / Exportar PNG** (arriba a la derecha): guardan la matriz tal como se ve, para llevarla a una hoja de cálculo o incrustarla en un informe o presentación.
- **Recalcular**: fuerza el recálculo manual (también se recalcula al cambiar cualquier filtro).

### Lectura de la matriz

- **Filas**: centros de trabajo activos del plan actual.
- **Columnas**: periodos consecutivos según la granularidad escogida.
- **Celda**: porcentaje de ocupación del centro durante ese periodo.
- **"---"**: el centro no tiene calendario asignado o el calendario no tiene horas laborables en ese periodo.
- **Columna Promedio** (derecha): ocupación media del centro en todo el horizonte mostrado.
- **Columna Tendencia** (derecha): una minigráfica que resume de un vistazo si el centro sube o baja de carga a lo largo de los periodos, con una guía en el 100%.
- **Fila RESUMEN TOTALES** (abajo): saturación global del conjunto de centros seleccionados en cada periodo, y el total general alineado con la columna Promedio.

### Interacción

- **Pasa el ratón** sobre cualquier celda para ver un detalle emergente con las horas planificadas, la capacidad disponible, el número de tareas y, si procede, el exceso de carga.
- **Haz clic en la cabecera "Centro"** para ordenar las filas por nombre, o en **"Promedio"** para ordenarlas por carga (de más a menos cargado). Un segundo clic invierte el orden; una flecha indica el sentido.

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

### Pestaña Pareto de sobrecarga

La matriz te muestra *dónde* hay rojo, pero para actuar necesitas saber *por dónde empezar*. Esta pestaña suma, por centro, todas las horas que quedan **por encima de su capacidad** en el horizonte, ordena los centros de mayor a menor exceso (barras) y dibuja encima la línea de **porcentaje acumulado** con una guía en el 80%.

La lectura es directa: casi siempre unos pocos centros concentran la mayor parte de la sobrecarga. El resumen inferior lo dice ("X de Y centros concentran el 80% de la sobrecarga"): son los que hay que atacar primero (mover trabajo, reforzar o subcontratar).

Si no hay ningún centro por encima de su capacidad, la pestaña lo indica: no hay sobrecarga que repartir.

### Pestaña Capacidad (cascada)

Un diagrama de **cascada**: empieza con la capacidad total del taller, va restando la carga planificada centro a centro, y termina con la **capacidad restante**. De un vistazo se ve dónde se consume la capacidad y cuánto margen libre queda.

El resumen inferior da la ocupación global del taller y las horas de margen (o el déficit, si el conjunto está sobrecargado). Es la foto ejecutiva del equilibrio carga/capacidad de todo el taller en una sola imagen.

## Por qué es útil

Es la **vista ejecutiva de la planificación**: en pocos segundos identifica los cuellos de botella y los huecos. Complementa al Gantt, que muestra el detalle por operación pero hace más difícil ver el agregado por centro y semana.

Combínalo con:

- **Heatmap de entregas vs capacidad**: para anticipar compromisos comerciales antes de que entren al plan.
- **Heatmap de carga por operario**: para bajar al detalle de quién está saturado dentro del centro.
