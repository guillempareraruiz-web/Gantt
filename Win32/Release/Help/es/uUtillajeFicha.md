# Ficha de utillaje

## Objetivo

Describir **un utillaje concreto** con todo el detalle que el planificador necesita: qué es, dónde está, en qué estado se encuentra, cuántos ejemplares hay, cuánta vida le queda y qué trabajos lo requieren.

La ficha se abre desde el catálogo de utillajes, pulsando **Nuevo**, **Editar** o haciendo doble clic sobre una fila.

## La pantalla

La ficha tiene tres pestañas.

### Datos generales

- **Código**: identificador corto y único. Obligatorio.
- **Descripción**, **Tipo**, **Fabricante**, **Nº de serie**, **Año de fabricación**: la identificación del utillaje.
- **Ubicación**: dónde se guarda físicamente cuando no está montado.
- **Centro actual**: el centro donde está montado o asignado ahora mismo. Puede quedar sin asignar.
- **Estado**: la situación real del utillaje.
  - *Disponible*: libre y listo para usar.
  - *Montado*: instalado en una máquina.
  - *Reservado*: apartado para un trabajo concreto.
  - *Mantenimiento*, *Averiado*, *Bloqueado*, *Baja*: no se puede usar.
- **Ejemplares**: cuántas unidades intercambiables tienes de este utillaje. Es el dato que decide si dos trabajos pueden usarlo a la vez. Con **1 ejemplar**, dos operaciones solapadas son un conflicto. Con **3 ejemplares**, caben tres operaciones a la vez.
- **Disponible**: marca manual. Desmárcala cuando el utillaje esté prestado o en reparación.
- **Disponible para planificar**: es la marca que **tiene en cuenta el planificador**. Si la desmarcas, el utillaje deja de vigilarse al detectar conflictos.
- **Activo**: desmárcala para retirar el utillaje sin borrarlo.
- **Orden**: posición en el listado y en los desplegables.

### Vida útil y tiempos

- **Se mide en**: la unidad en la que cuentas el uso (ciclos, horas, golpes o piezas).
- **Vida útil total**: cuántas unidades aguanta antes de necesitar mantenimiento. Déjalo en **0** si este utillaje no lleva control de vida.
- **Contador actual**: cuánto lleva consumido.
- La barra muestra el **porcentaje consumido**. Se pone en naranja al llegar al 80% y en rojo al llegar al 100%.
- **Próximo mantenimiento**: la fecha prevista. Marca *Sin fecha prevista* si no la hay.
- **Tiempos de cambio**: los minutos de **montaje**, **desmontaje** y **ajuste**. Son el coste real de cambiar de utillaje en la máquina.

### Relaciones

Aquí se define **cuándo hace falta este utillaje**. Es lo que permite que el planificador lo vigile.

- **Centros donde puede montarse**: marca los centros compatibles. Puedes señalar uno como **preferente** y darle un **tiempo de montaje específico** si en ese centro se tarda distinto (0 = usar el tiempo general).
- **Operaciones que requieren este utillaje**: la vía habitual. Si una operación necesita el utillaje, todos los trabajos que pasen por esa operación lo heredan automáticamente.
- **Artículos que requieren este utillaje**: para cuando el requisito depende del artículo y no de la operación.

En ambos listados, **Obligatorio** indica que el trabajo no puede hacerse sin el utillaje. Solo los requisitos obligatorios se vigilan al detectar conflictos.

## Cómo trabajar

1. Rellena el **código** y la descripción en *Datos generales*.
2. Indica cuántos **ejemplares** tienes. Es el dato más importante para la planificación: define cuántos trabajos pueden usarlo a la vez.
3. Si controlas el desgaste, ve a *Vida útil* y fija la **vida total** y la unidad.
4. En *Relaciones*, añade las **operaciones** que lo requieren. Sin esto, el utillaje queda en el catálogo pero el planificador no lo vigila.
5. Pulsa **Guardar**.

## Por qué es útil

Declarar las relaciones y los ejemplares es lo que convierte el catálogo en algo operativo: a partir de ese momento, si dos trabajos que necesitan el mismo utillaje se solapan y no hay ejemplares suficientes, el plan lo avisa antes de que el problema llegue a planta.

Pulsa **F1** en cualquier momento para volver a esta ayuda.
