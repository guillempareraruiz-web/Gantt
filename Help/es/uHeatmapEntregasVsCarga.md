# Heatmap de entregas vs capacidad

## Objetivo

Visualizar el **compromiso comercial** de la empresa frente a su capacidad productiva: cuántas horas de trabajo hemos prometido entregar en cada periodo, comparadas con la capacidad disponible.

Responde a la pregunta clave del comercial y del jefe de producción:

- **¿Podemos aceptar más pedidos para la semana X?**

Y permite anticiparlo **antes** de planificar, solamente con las fechas de entrega comprometidas con el cliente.

## La pantalla

Una **matriz** con los centros de trabajo en las filas y los periodos en las columnas. Cada celda muestra el % de compromiso del centro en ese periodo.

### Filtros (barra superior)

- **Granularidad**: Días, Semanas (por defecto) o Meses.
- **Número periodos**: cuántos periodos mostrar.
- **Desde**: fecha del primer periodo.
- **Centros**: combo con selección múltiple. La opción "(Todos)" marca o desmarca el resto.
- **Recalcular**: fuerza el recálculo manual.

### Lectura de la matriz

- **Filas**: centros de trabajo activos.
- **Columnas**: periodos consecutivos.
- **Celda**: % de compromiso del centro en ese periodo (horas prometidas vs capacidad disponible).
- **"---"**: el centro no tiene calendario o no tiene horas laborables en ese periodo.

### Leyenda de colores

- **0%**: sin compromisos en ese periodo.
- **1-75%**: tonos verdes (margen amplio para aceptar más pedidos).
- **76-100%**: amarillo / naranja (el periodo se está llenando).
- **>100%**: rojo (más compromiso que capacidad: o se traslada trabajo, o se renegocia entrega, o se subcontrata).

## Diferencia clave respecto al "Heatmap de carga por centro"

| | **Carga por centro** | **Entregas vs capacidad** |
|---|---|---|
| **Qué imputa** | El trabajo se cuenta en los periodos donde está colocado en el Gantt | El trabajo se cuenta **íntegro** en el periodo en el que se entrega al cliente |
| **Cuándo es útil** | Una vez planificado: ver cómo queda el plan | Antes de planificar: ver el compromiso "comercial" puro |
| **Pregunta que responde** | ¿Cuándo trabajamos cada cosa? | ¿Qué hemos prometido entregar y cuándo? |

## Qué datos se usan

- **Los compromisos** salen de las operaciones del plan activo cuya fecha de entrega cae dentro del horizonte mostrado. Las operaciones sin fecha de entrega o con fecha fuera del horizonte no se contabilizan.
- **La capacidad** sale del calendario asignado al centro (horario laboral, festivos y excepciones definidos en **Gestión de Calendarios**).

## Por qué es útil

Es la pantalla que **comercial y producción** miran juntos antes de comprometer una entrega nueva:

- Si el centro está en verde durante la semana objetivo, se puede aceptar el pedido sin reorganizar.
- Si está en amarillo, conviene valorar si se puede dar una fecha algo más tardía.
- Si está en rojo, hay que renegociar la fecha, mover trabajo a otra semana o derivar a subcontratación.

Es complementario al Gantt (que muestra el plan ya hecho) y al **Heatmap de carga por centro** (que muestra el reparto real del trabajo en el tiempo).
