# Alertas de planificación

## Objetivo

El panel **Salud del plan** del Gantt muestra, de un vistazo, una puntuación de
0 a 100 que resume el estado de la planificación. Al pulsarlo se abre este listado
detallado, agrupado por tipo de alerta, para que puedas revisarlas y corregirlas.

## La puntuación de salud (0-100)

El sistema calcula un **índice de salud del plan** ponderando todas las
incidencias por su **peso** (importancia). Cuantas más incidencias y más
importantes, menor es la salud:

| Salud | Etiqueta | Significado |
|-------|----------|-------------|
| 90-100 | **Excelente** | Plan prácticamente limpio. |
| 75-89 | **Bueno** | Pocas incidencias o de poca importancia. |
| 50-74 | **Regular** | Conviene revisar y corregir. |
| 25-49 | **Malo** | Bastantes problemas relevantes. |
| 0-24 | **Crítico** | Plan con problemas graves. |

El **color del panel** (verde/amarillo/naranja/rojo) refleja ese grado. El número
grande es la salud; al pasar el ratón por encima verás el detalle.

> La salud no cuenta todas las incidencias por igual: una alerta de **peso** alto
> (p. ej. "fuera de plazo", peso 95) penaliza mucho más que una de peso bajo
> (p. ej. "sin fecha de entrega", peso 15). Los pesos se ajustan en **Configurar...**.

## Cuándo usarlo

- Antes de dar por buena una planificación, para detectar problemas (nodos sin
  operarios, fuera de plazo, en días no laborables…).
- Tras una replanificación automática, para comprobar qué ha quedado pendiente.

## La pantalla

Cada fila es un **tipo de alerta** con:

- Una **marca de color** según la gravedad:
  - 🔴 **Rojo**: incidencia importante (nodo activo en el pasado, fuera de plazo,
    en un centro no permitido).
  - 🟠 **Naranja**: a revisar (sin operarios, sin stock, en día no laborable).
  - 🟡 **Amarillo**: aviso (operarios parciales, próximo a la fecha de entrega,
    duración o cantidad nula).
  - 🔵 **Azul**: informativo (sin fecha de entrega definida).
- El **número** de nodos afectados.
- La **descripción** de la alerta.

Algunas filas aparecen **atenuadas (en gris)**: son tipos de alerta que aún no
están disponibles y se mostrarán próximamente. Sirven para conocer qué controles
están previstos. No tienen contador.

## Operaciones frecuentes

- **Ver en el Gantt los nodos afectados**: haz **doble clic** sobre una alerta (o
  selecciónala y pulsa **Ver en Gantt**). El diálogo se cierra y el Gantt muestra
  **solo** esos nodos. Para volver a verlos todos, quita el filtro desde el panel
  de KPIs. (Solo se pueden ver en el Gantt las alertas con incidencias; las
  cumplidas y las pendientes no son seleccionables.)
- **Ver todas**: por defecto solo se listan las alertas con incidencias (y las
  pendientes). Pulsa **Ver todas** para mostrar también los controles que se
  **cumplen** (marcados con un tic verde y "OK"), y así ver el cuadro completo.
- **Ordenar**: haz clic en una cabecera de columna para ordenar (clic de nuevo
  invierte el orden). Por defecto se ordena por importancia.
- **Configurar...**: abre la configuración de alertas, donde puedes **activar o
  desactivar** cada tipo y ajustar su **peso** (importancia, 1-100). El peso
  determina el orden por defecto y permite priorizar (no pesa igual "fuera de
  plazo" que "mismo utillaje"). Los cambios se guardan en la base de datos y son
  por empresa.
- **Cerrar** sin cambios: botón **Cerrar** o tecla `Esc`.

## El peso (importancia)

Cada tipo de alerta tiene un **peso de 1 a 100** que refleja su impacto en el
plan. El peso se usa para dos cosas:

1. **Ordenar** las alertas: las de más peso aparecen primero.
2. **Calcular la salud del plan**: cada incidencia resta salud en proporción a su
   peso y al número de nodos afectados.

Puedes ajustar el peso de cada alerta en **Configurar...** según las prioridades
de tu planta (la columna **Peso** del listado lo muestra en todo momento).

## Tipos de alerta

Cada alerta tiene un **código** estable (A01, R02…) para poder referenciarla.
Las marcadas con _(Próximamente)_ aún no están disponibles y se muestran atenuadas.

### Disponibles

| Cód. | Alerta | Significado |
|------|--------|-------------|
| A01 | Nodos activos antes de la fecha actual | Empiezan en el pasado y no están finalizados. |
| A02 | Nodos fuera de plazo de entrega | Terminan después de su fecha de entrega. |
| A03 | Nodos próximos a la fecha de entrega | Terminan muy cerca de su fecha de entrega. |
| A04 | Nodos sin fecha de entrega definida | No tienen fecha de entrega. |
| O01 | Nodos sin operarios asignados | Necesitan operarios y no tienen ninguno. |
| O02 | Nodos con operarios parciales | Tienen menos operarios de los necesarios. |
| M01 | Nodos sin stock suficiente | El stock no cubre las unidades a fabricar. |
| R01 | Nodos en un centro no permitido | Colocados en un centro que no admiten. |
| C01 | Nodos en zona no laborable | Caen íntegramente en festivo, fin de semana o fuera de turno. |
| D03 | Nodos con duración o cantidad nula | Sin duración o sin unidades a fabricar. |
| D05 | Nodos no optimizados | Su duración actual es mayor que la prevista originalmente. |

### Próximamente (roadmap)

| Cód. | Alerta | Significado |
|------|--------|-------------|
| A05 | Margen de entrega insuficiente | La cadena hasta la entrega no cabe en plazo. |
| A06 | Órdenes de fabricación en riesgo | Alguna OT de la OF está fuera de plazo. |
| O03 | Operarios sobrecargados | Un operario asignado a dos nodos solapados. |
| O04 | Operarios sin competencia | El operario no tiene la cualificación requerida. |
| M02 | Nodos con stock parcial | Cubre parte pero no todo. |
| M03 | Material no disponible | Operación antes de tener su materia prima. |
| R02 | Utillaje en conflicto | Mismo molde/utillaje usado a la vez. |
| R03 | Máquina no operativa | Nodo en máquina en mantenimiento. |
| R04 | Nodos solapados en centro secuencial | Dos nodos en un centro que solo admite uno a la vez. |
| C02 | Días sobrecargados | Carga por encima de la capacidad del centro/día. |
| C03 | Cuellos de botella sobrecargados | Centro crítico por encima del umbral. |
| D01 | Dependencias no respetadas | Un nodo empieza antes de terminar aquel del que depende. |
| D02 | Saltos de tiempo excesivos en una OF | Demasiado tiempo muerto entre operaciones. |
| D04 | Duración incoherente | No cuadra con unidades × tiempo por unidad. |
| D06 | Nodos bloqueados planificados | Estado bloqueado pero aún en el plan. |
| D07 | Prioridad alta planificada tarde | Va detrás de nodos de prioridad menor. |
| D08 | Sin centro asignado | Sin centro o centro inexistente/deshabilitado. |
| D09 | Fuera del plan maestro | Movido fuera de la ventana del plan. |
| D10 | Fuera del horizonte | Demasiado adelante o atrás en el tiempo. |
