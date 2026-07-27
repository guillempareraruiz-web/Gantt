# Nivelar recursos

## Objetivo

Resolver las **sobreasignaciones**: retrasar tareas hasta que ninguna persona supere su jornada.

Se abre desde la pantalla de Ingeniería con **botón derecho → Nivelar recursos**. Si no hay ninguna sobreasignación, la opción aparece desactivada: no hay nada que resolver.

Nivelar **solo mueve tareas en el tiempo**. No acorta trabajos, no cambia de persona y no parte tareas por la mitad: es el cambio más pequeño que arregla el problema, y el único que no altera el plan que has construido.

## Nada se aplica sin que lo veas

La ventana es una **previsualización**. Muestra lo que pasaría, y no toca nada hasta que pulsas **Aplicar**.

## Las cifras de arriba

Responden a *"¿me compensa?"* de un vistazo:

- **Sobrecargas antes** y **después**: si la segunda no baja, la propuesta no ha resuelto el problema y conviene mirar el bloque inferior.
- **Tareas que se mueven**: el tamaño del cambio.
- **El proyecto se retrasa**: si la fecha de entrega se ve afectada, y cuánto.
- **Sin resolver**: cuántos conflictos quedan.

## Las dos opciones

Cambiar cualquiera de las dos **recalcula la propuesta al instante**, para que puedas comparar escenarios antes de decidir.

- **Nivelar sólo dentro de la holgura**: no retrasa la fecha de entrega. Solo mueve tareas hasta donde su holgura lo permite. Es más conservador, pero puede dejar sobreasignaciones sin resolver — y en ese caso lo dice.
- **Mover también las tareas ya iniciadas**: normalmente desactivado. Mover algo que ya tiene horas dedicadas es replanificar el pasado.

## La lista de cambios

Una fila por tarea que se mueve: de cuándo a cuándo, cuánto se retrasa y **por quién espera**.

Esa última columna es la explicación del retraso. Sin ella verías que una tarea se mueve tres días sin saber por qué.

## Qué se mueve antes

Cuando dos tareas se disputan a la misma persona, alguien tiene que esperar. El orden es:

1. Las que **no se pueden mover** reservan su sitio primero.
2. Las **críticas** antes que las que tienen holgura: retrasar una crítica retrasa el proyecto entero; retrasar una con holgura no cuesta nada.
3. A igualdad, la más apretada de holgura.
4. Y después, la que empieza antes.

**Nunca se mueven**: las tareas con fecha clavada (*debe comenzar el* / *debe finalizar el*), las de *lo más tarde posible*, los hitos, las tareas resumen y las que ya tienen horas dedicadas.

El resultado es siempre el mismo con los mismos datos: la propuesta no cambia sola entre una consulta y la siguiente.

## Qué pasa al aplicar

Cada tarea movida queda con la restricción **"no comenzar antes del"** en su nueva fecha.

No es una fecha clavada: si más adelante se acorta una tarea anterior, esta podrá adelantarse hasta ese tope, pero no más.

Para deshacer la nivelación de una tarea concreta, abre su ficha y devuelve la restricción a **lo antes posible**.

## Si quedan conflictos sin resolver

Es normal, sobre todo con *sólo dentro de la holgura* activado. El bloque inferior lo explica caso por caso. Las salidas:

- Desactivar *sólo dentro de la holgura* y aceptar que el proyecto se alargue.
- Repartir la tarea entre más gente, o bajar la dedicación de alguien.
- Revisar si esas fechas clavadas tienen que estarlo de verdad.

## Errores frecuentes

- **No se mueve nada**: si está marcado *sólo dentro de la holgura* y las tareas en conflicto son críticas, no hay margen. Desmárcalo para ver la alternativa.
- **El botón Aplicar está desactivado**: la propuesta no mueve ninguna tarea, así que no hay nada que guardar.
- **Sigue habiendo sobreasignación después de aplicar**: mira las tareas que quedaron sin resolver. Con varios proyectos a la vez, una persona repartida entre ellos puede seguir solapada.

## Por qué es útil

Detectar que alguien está al 200 % es la mitad del trabajo; la otra mitad es recolocar el plan, y hacerlo a mano en un proyecto de cierto tamaño lleva horas y sale mal.

La diferencia con hacerlo tú mismo no es solo la velocidad: el motor respeta el camino crítico y las fechas comprometidas, que es justo lo que se pierde de vista cuando se arrastran tareas una a una.

Pulsa **F1** en cualquier momento para volver a esta ayuda.
