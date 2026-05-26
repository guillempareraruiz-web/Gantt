# Planificador de capacidad finita

## Objetivo

Asignar las operaciones de fabricación pendientes a los **centros de trabajo** disponibles, respetando la capacidad real de cada centro y de forma visual e interactiva.

Sirve para responder preguntas como:

- ¿Qué operaciones tengo sin asignar todavía?
- ¿Qué centro queda libre para meter más trabajo esta semana?
- ¿Cómo redistribuyo si un centro se ha quedado saturado?

## La pantalla

Está dividida en dos zonas principales:

- **Izquierda — OT pendientes**: lista de operaciones aún no asignadas a ningún centro. Cada tarjeta muestra OF, artículo, cliente, duración, prioridad y fecha de entrega.
- **Derecha — Centros de trabajo**: una columna por centro con las operaciones asignadas en orden. Una barra superior indica la **ocupación del centro** dentro del rango de planificación seleccionado.

Para asignar una operación, basta con **arrastrarla** desde el panel izquierdo a la columna del centro deseado. También se pueden mover entre centros o devolver al panel de pendientes.

### Barra superior

- **Fecha + Rango**: define el horizonte de planificación que se muestra (1 día, 1 semana, 2 semanas, 1 mes...). Las barras de ocupación de cada centro se recalculan según este rango.
- **Layout**: combo con los layouts personales guardados. Permite recordar qué centros se ven y en qué orden.
  - `(por defecto)`: muestra todos los centros del plan ordenados alfabéticamente.
  - **+**: crea un nuevo layout a partir de la configuración actual (centros visibles + orden).
  - **Guardar**: actualiza el layout seleccionado con la configuración actual.
  - **Eliminar**: borra el layout seleccionado (`(por defecto)` no se puede borrar).
- **Centros**: selector múltiple para mostrar u ocultar centros. La opción `(Todos)` marca o desmarca el resto.
- **UNDO / REDO**: deshacer y rehacer asignaciones recientes.

### Panel de pendientes (izquierda)

- **Buscador**: filtra por OF, artículo o cliente.
- **Botón "..."**: opciones de orden, filtros por estado y operación, y editor del layout de tarjeta.
- **Selección múltiple**: Ctrl+clic para marcar varias y arrastrarlas juntas.

### Columnas de centros (derecha)

- **Cabecera**: nombre del centro, número de operaciones asignadas y barra de capacidad ocupada.
- **Tarjetas**: cada operación con sus datos. Doble clic abre el inspector con el detalle completo.
- **Separadores de día**: cuando las operaciones cruzan días, una franja indica el cambio de fecha.
- **Arrastrar la cabecera**: permite **reordenar los centros** horizontalmente.

## Layouts personales

Cada usuario puede guardar layouts propios para distintos escenarios de trabajo (por ejemplo "Línea de montaje", "Mecanizado", "Solo turno A").

Un layout almacena:

- **Qué centros se ven** (los marcados en el combo Centros).
- **En qué orden** aparecen las columnas (resultado del drag de cabeceras).

Si quieres que un layout se cargue al abrir la pantalla, márcalo como **predeterminado** desde el editor de layouts (próximamente desde el botón `Guardar`).

## Capacidad y horas

La **barra de ocupación** de cada centro compara las horas de las operaciones asignadas con las horas laborables del centro en el rango seleccionado. Las horas laborables salen del calendario asignado al centro en **Gestión de Calendarios**.

- Verde: holgura.
- Amarillo / naranja: capacidad casi al límite.
- Rojo: sobrecarga.

## Guardado

Los cambios se persisten automáticamente al **cerrar la pantalla** o al cambiar de vista (Dashboard, Gantt). No hay botón "Aceptar" porque las asignaciones quedan registradas en cuanto las haces.

## Cuándo usar esta pantalla

- Después de **sincronizar el ERP** y traer al Backlog las nuevas OF: aquí decides a qué centros van.
- Para **rebalancear** cuando un centro se ha saturado y otros tienen huecos.
- Para **revisar el plan a corto plazo** (1-2 semanas) sin entrar al detalle del Gantt.

Combínalo con:

- **Heatmap de carga por centro**: visión agregada de la ocupación por periodo.
- **Gantt**: detalle temporal de las operaciones ya planificadas.
