# Gestión de Utillajes

## Objetivo

Mantener el **catálogo de utillajes** de la fábrica: mordazas, matrices, troqueles, calibres, plantillas y cualquier otro elemento auxiliar que una máquina necesita montar para poder fabricar.

El catálogo es la fuente única de verdad: cada utillaje se da de alta una sola vez aquí, y el resto de pantallas del planificador lo seleccionan de esta lista en lugar de escribir su código a mano. Así se evita que el mismo utillaje aparezca escrito de tres formas distintas.

Los utillajes son datos **propios del planificador**: no vienen del ERP ni se envían a él. Se crean y se mantienen únicamente desde esta pantalla.

## La pantalla

Un **listado** con todos los utillajes dados de alta, ordenados por el campo Orden y después por código. El listado es de solo lectura: el detalle de cada utillaje se edita en su **ficha**.

Cada fila muestra:

- **ID**: identificador interno, asignado por el sistema.
- **Código**: el identificador corto con el que se conoce el utillaje en planta.
- **Descripción**: qué es el utillaje.
- **Tipo**: la familia a la que pertenece (mordaza, matriz, troquel...).
- **Ubicación**: dónde se guarda físicamente cuando no está montado.
- **Estado**: lo que **tú declaras** en la ficha (disponible, montado, en mantenimiento, averiado...).
- **Situación**: lo que **dice la planificación** ahora mismo. No se escribe a mano, se calcula:
  - *Libre*: ningún trabajo planificado lo necesita.
  - *En uso (N)*: hay N trabajos usándolo en este momento.
  - *Reservado (N)*: ahora está libre, pero tiene N trabajos por delante.
- **Libre a partir de**: cuándo termina el último trabajo que lo está usando. Vacío si ya está libre.
- **OFs afectadas**: las órdenes de fabricación que dependen de este utillaje.
- **Ejemplares**: cuántas unidades intercambiables hay. Es el dato que decide cuántos trabajos pueden usarlo a la vez.
- **Vida útil**: el porcentaje consumido. Las filas con la vida agotada (100% o más) se marcan en rojo.
- **Disponible** y **Activo**: las marcas de uso y de alta en el catálogo.

### Estado y Situación no son lo mismo

**Estado** es lo que tú declaras; **Situación** es lo que ocurre en el plan. Que no coincidan es información valiosa, no un error de la pantalla.

El caso importante: si marcas un utillaje como *Averiado* o *En mantenimiento* pero la planificación lo sigue usando, la fila se marca en **naranja**. Significa que hay trabajos planificados con un utillaje que, según tú, no se puede usar. Es justo lo que interesa detectar antes de que el problema llegue a planta.

### Barra de botones

- **Nuevo**: abre una ficha en blanco para dar de alta un utillaje.
- **Editar**: abre la ficha del utillaje seleccionado. También se abre haciendo **doble clic** sobre la fila.
- **Eliminar**: borra el utillaje seleccionado tras confirmar. Se borran también sus relaciones con centros, artículos y operaciones.
- **Cerrar**: cierra la ventana.

## Cómo trabajar

1. Pulsa **Nuevo** para dar de alta un utillaje, o haz **doble clic** sobre uno existente para abrir su ficha.
2. Rellena los datos en la ficha y pulsa **Guardar**. El listado se actualiza al volver.
3. Para retirar un utillaje que ya no se usa, abre su ficha y desmarca **Activo** en lugar de eliminarlo: así el histórico sigue siendo consultable.

Puedes ordenar y filtrar el listado pulsando en las cabeceras de las columnas.

## Errores frecuentes

- **Dos utillajes con el mismo código**: el código debe ser único. La ficha avisa si repites uno existente.
- **No se puede eliminar**: si el utillaje está asignado a algún molde, el borrado se rechaza. Desmarca **Activo** en su ficha para retirarlo.
- **Eliminar en lugar de desactivar**: si el utillaje ya se ha usado, es preferible desmarcar **Activo**.

## Modo demostración

Al activar el modo Demo y regenerar el Gantt, se crean automáticamente unos utillajes de ejemplo (con el código empezando por `DEMO-`) ligados a las operaciones del plan de demostración. Sirven para ver el funcionamiento sin dar nada de alta.

Al regenerar la demo se borran y se vuelven a crear. **Solo se tocan los que empiezan por `DEMO-`**: los utillajes reales no se ven afectados nunca.

## Por qué es útil

Un utillaje mal identificado es una parada de máquina: el operario llega al cambio y no encuentra la mordaza, o monta la que no es. Tener el catálogo al día, con la ubicación y el estado de disponibilidad correctos, permite que la planificación cuente con medios que realmente existen y están libres.

Las columnas **Situación** y **Libre a partir de** responden de un vistazo a la pregunta más frecuente de planta: *"¿puedo contar con este utillaje ahora, y si no, cuándo?"*.

Pulsa **F1** en cualquier momento para volver a esta ayuda.
