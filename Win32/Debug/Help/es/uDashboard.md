# Panel de control (Dashboard)

## Objetivo

Es la **pantalla de inicio** de FS Planner 2.0: la foto de tu fábrica de un solo vistazo. Reúne, en tarjetas e indicadores, el estado de la planificación, de la producción, de los recursos y del material, para que sepas cómo va la semana **sin tener que abrir el Gantt ni consultar a nadie**.

Responde de un vistazo a preguntas como:

- ¿El plan de esta semana va bien o hay algo que revisar?
- ¿Vamos a cumplir las entregas comprometidas?
- ¿Qué centro está más cargado?
- ¿Tenemos material para lo que hay que fabricar?

## La pantalla

El panel está organizado en **secciones apiladas** que puedes recorrer con la barra de desplazamiento. Cada sección agrupa información relacionada.

### Cabecera

Muestra la **empresa**, el **proyecto activo** y el **usuario** con el que has entrado, junto con la fecha y la hora. Es tu punto de referencia: todo lo que ves debajo corresponde a ese proyecto.

### Proyecto activo

El resumen del plan que tienes cargado, con indicadores visuales:

- **Anillos (donuts)** de nodos, órdenes y comandas: la parte planificada frente al total. Cuanto más lleno el anillo, más trabajo ya está colocado en el plan.
- **Indicador de saturación**: el nivel de ocupación general del taller.
- Debajo, el **cronograma de carga semanal**: un mini-Gantt que muestra, por centro y semana, cómo de cargado está cada uno. El **color** funciona como semáforo (verde holgado, ámbar al límite, **rojo sobrecargado**), así que de un vistazo ves qué centro y qué semana se te complican.

### Indicadores clave (tarjetas)

Un conjunto de **tarjetas KPI**, agrupadas por familia, con el valor actual y una pequeña gráfica de evolución (sparkline). Las principales:

- **Salud del plan**: un número único (0-100) que resume si el plan es fiable. Verde es excelente; si baja, conviene revisarlo.
- **Entregas a tiempo (OTIF)**: el porcentaje de órdenes que, según el plan, llegarán dentro de su fecha comprometida. Es el indicador de servicio al cliente.
- **OFs en riesgo**: órdenes con entrega muy próxima que aún no están terminadas. Tu lista de vigilancia a corto plazo.
- **Volumen** (OFs en plan, nodos planificados): cuánto trabajo ha entrado ya en la planificación.
- **Recursos** (carga planificada, operarios asignados, saturación media, **centro cuello de botella**): el estado de tu capacidad. El cuello de botella señala el centro que limita todo el plan —muy probablemente el horno.
- **Material** (OFs con stock suficiente / OFs con rotura de stock): qué parte del plan tiene los ingredientes y envases disponibles a tiempo, y qué parte corre riesgo por falta de material. Son la referencia de compras y logística.
- **Pendientes del ERP**: órdenes que existen en tu sistema de gestión pero aún no se han incorporado al plan.

**Doble clic** sobre cualquier tarjeta abre su **ficha de detalle**: qué mide exactamente, para qué sirve y su evolución ampliada.

### Selector de periodo

Encima de las tarjetas hay un selector —**Semana, 7, 30 o 90 días**— que cambia el tramo de tiempo que muestran las pequeñas gráficas de evolución. Elige el horizonte con el que quieras mirar la tendencia.

### Sincronización con el ERP

Una sección que indica si hay órdenes nuevas o cambios en tu sistema de gestión pendientes de traer al plan, y permite lanzar la sincronización.

## Personalización

- **Reordena las tarjetas**: arrástralas para colocarlas en el orden que prefieras. FS Planner recuerda tu disposición.
- **Reordena las secciones**: usa los tiradores de cada bloque para organizarlas a tu gusto.
- El panel se adapta al ancho de la ventana: las tarjetas se recolocan solas.

## Accesos rápidos

Desde el panel puedes saltar directamente a las pantallas de trabajo relacionadas —abrir el **Gantt** o el **planificador de capacidad**— para pasar de la foto general a la acción concreta.

## Modo demostración

Si activas el botón **Demo** de la barra de herramientas, el panel se rellena con datos de ejemplo realistas —indicadores, cronograma y tarjetas incluidos— sin tocar tus datos. Es ideal para presentaciones y formación; al desactivarlo, vuelven los valores reales.

## Por qué es útil

Es tu **cuadro de mando diario**. En lugar de repartir la información entre hojas de cálculo, correos y la cabeza de cada responsable, la reúne en una sola pantalla que se actualiza sola. Un vistazo por la mañana te dice si la semana está bajo control o dónde hay que intervenir —en producción, en entregas o en compras— antes de que se convierta en un problema.

Combínalo con:

- **Gantt**: para trabajar el plan operación a operación.
- **Análisis del plan**: para el detalle de gestión con gráficos.
- **Análisis de artículo**: para la proyección de stock y las recomendaciones de compra o fabricación.
