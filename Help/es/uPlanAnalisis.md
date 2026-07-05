# Análisis del plan

## Objetivo

Es el **cuadro de mando** de la planificación: un conjunto de gráficos que responden, de un vistazo, a las preguntas de gestión que el Gantt no contesta bien porque muestra el detalle operación a operación.

Sirve para responder preguntas como:

- ¿Está equilibrada la carga entre centros y personas, o hay cuellos de botella?
- ¿Vamos a cumplir las fechas de entrega comprometidas?
- ¿Cuánta capacidad libre queda para aceptar más trabajo?
- ¿Dónde se va el tiempo: en producir o en preparar máquinas (setup)?

## La pantalla

- **Árbol de la izquierda**: la lista de gráficos, agrupados por categoría (Capacidad, Entregas, Tiempos, Mix, Recursos, Eficiencia…). Haz clic en cualquiera para verlo.
- **Página "Resumen"** (primer nodo del árbol): una parrilla con los cuatro indicadores más importantes juntos, como portada ejecutiva.
- **Gráficos "(pendiente)"**: aparecen en gris y en cursiva. Son la hoja de ruta de lo que se irá añadiendo; todavía no se pueden abrir.

### Filtros (barra superior)

Los tres filtros afectan a **todos** los gráficos a la vez:

- **Desde**: fecha de inicio del horizonte que se analiza.
- **Granularidad**: Días, Semanas o Meses. Cambia el ancho de cada periodo.
- **Periodos**: cuántos periodos mostrar a partir de la fecha de inicio.
- **Actualizar**: recalcula todos los gráficos con los filtros actuales.

## Los gráficos

### General — la foto de conjunto

- **Salud del plan**: un indicador único (0-100) que combina cumplimiento, ocupación y sobrecarga.
- **Cronograma por proyecto**: un mini-Gantt que sitúa cada proyecto en el tiempo (inicio → fin), para ver de un vistazo qué se solapa.
- **Avance del plan**: qué porcentaje de las unidades a fabricar ya está hecho.

### Capacidad — ¿está equilibrado el taller?

- **Carga vs capacidad por centro**: barras de horas planificadas frente a la línea de capacidad de cada centro. Las barras rojas superan la capacidad.
- **Ocupación por centro**: el % de uso de cada centro (verde saludable, ámbar al límite, rojo saturado).
- **Curva de carga temporal**: cómo evoluciona la carga total del taller periodo a periodo frente a la capacidad disponible.
- **Carga acumulada vs capacidad (CRP)**: las dos curvas acumuladas. Si la carga cruza por encima de la capacidad, a partir de ahí el plan no cabe con los recursos actuales.
- **Ocupación por centro y periodo**: un mapa de calor que revela *cuándo* se calienta cada centro, no solo el total.
- **Carga apilada por centro**: la carga temporal, viendo qué centro aporta cada tramo.
- **Balance de línea (desequilibrio)**: cuánto se aleja cada centro de la ocupación media. Barras largas a un lado = taller descompensado.
- **Pareto de carga por centro**: los pocos centros que concentran la mayor parte de la carga (regla del 80/20).
- **Sobrecarga por centro**: en cuántos periodos cada centro pasa de su capacidad.

### Entregas — ¿cumpliremos las fechas?

- **Cumplimiento de entregas (OTD)**: reparto entre "a tiempo", "en riesgo", "retrasadas" y "sin compromiso".
- **Distribución de retrasos**: cuántas entregas se adelantan o se retrasan, en días.
- **Margen hasta la entrega**: las órdenes con menos colchón (o ya en retraso). Es el radar de lo que puede incumplirse.
- **Prioridad vs retraso**: cada orden como un punto (prioridad frente a días de retraso). Las de arriba a la derecha son las urgentes de verdad: importan y además van tarde.
- **Entregas por semana**: resumen del cumplimiento.
- **Top OF más retrasadas**: el ranking de las órdenes que peor van, para atacarlas primero.

### Dependencias

- **Cadenas más largas (camino crítico)**: las secuencias de operaciones encadenadas que más duran. Son las que marcan el plazo total: acortarlas es lo único que adelanta la entrega.

### Tiempos

- **Makespan por proyecto**: cuánto dura, de principio a fin, cada proyecto del plan.
- **Distribución de duraciones**: qué tamaño tienen las operaciones (muchas cortas, pocas largas…).

### Mix / producto

- **Carga por artículo** y **por tipo de operación**: dónde se concentran las horas.
- **Carga por cliente**: a qué clientes dedicamos la capacidad.
- **Nº operaciones por centro**: qué centros mueven más operaciones.

### Recursos

- **Carga vs capacidad por operario** y **Ocupación de operarios**: el análisis de capacidad a nivel de personas, para ver quién está saturado y quién tiene holgura.
- **Cobertura de personal por centro**: operarios necesarios frente a asignados. Revela dónde falta gente.
- **Trabajo en curso por estado (WIP)**: cuántas operaciones están pendientes, en curso o hechas.

### Eficiencia

- **% tiempo productivo vs setup**: qué parte de las horas de cada centro es producción real y qué parte es preparación.
- **Utilización media global**: el indicador resumen de ocupación de todo el taller.

## Modo demostración

Si activas el botón **Demo** de la barra de herramientas **antes** de abrir esta pantalla, todos los gráficos se rellenan con datos de ejemplo realistas. Es útil para presentaciones y formación, y nunca modifica tus datos: al desactivarlo, vuelven los valores reales del plan.

## Por qué es útil

Es la **vista de dirección** de la planificación. El Gantt es imprescindible para trabajar operación a operación, pero para decidir (aceptar un pedido, reforzar un centro, avisar de un retraso) hace falta el agregado: esta pantalla lo da en segundos y con el semáforo puesto.

Combínalo con:

- **Heatmap de carga por centro**: para ver la saturación centro × periodo con todo el detalle.
- **Heatmap de entregas vs capacidad**: para anticipar compromisos comerciales antes de meterlos en el plan.
