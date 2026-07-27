# Ingeniería (proyectos y tareas)

## Objetivo

Planificar **proyectos por tareas**: trabajos de ingeniería, diseño, desarrollo, montaje o puesta en marcha, donde lo que importa es el **encadenado de actividades** y las fechas de entrega.

Es la otra mitad del planificador. **Producción** planifica la fábrica: cada centro de trabajo es una fila y dentro caben muchos trabajos a la vez. **Ingeniería** planifica proyectos: cada tarea es una fila, y las tareas se anidan unas dentro de otras formando el árbol del proyecto.

Ambas comparten calendarios laborables, festivos y operarios, de modo que un proyecto de ingeniería y una orden de fabricación cuentan los días laborables de la misma manera.

## Los indicadores de la cabecera

Arriba a la derecha, cinco indicadores resumen la situación sin abrir nada. El **color de fondo es el semáforo**:

- **Fin previsto**: la fecha de entrega del conjunto. En rojo si ya ha pasado, en ámbar si es esta semana.
- **Avance**: porcentaje de trabajo dedicado sobre el previsto. No lleva color a propósito: un 30 % no es bueno ni malo por sí solo, hay que compararlo con el tiempo consumido, y eso lo hace el Resumen del proyecto.
- **Camino crítico**: cuántas tareas no admiten ni un día de retraso.
- **Retrasadas**: tareas que deberían haber terminado y no constan hechas. En verde cuando no hay ninguna.
- **Sobreasignados**: cuántas **personas** superan su jornada (no cuántos tramos: la misma persona puede aparecer varias veces y sonaría peor de lo que es). **Se puede pulsar** para ver el detalle.

## La pantalla

Dos zonas sincronizadas:

- **Izquierda, el árbol de tareas**: la estructura del proyecto. Cada tarea puede tener subtareas, sin límite de niveles.
- **Derecha, el diagrama de Gantt**: la misma lista, dibujada en el tiempo.

Las dos zonas van siempre a la par: si pliegas una rama en el árbol, sus barras desaparecen del Gantt; si te desplazas en una, la otra la sigue.

### Columnas del árbol

- **Nombre**: el título de la tarea. La sangría indica de quién depende.
- **Duración**: cuántos días laborables ocupa. En las tareas resumen no se escribe: sale de sus hijas.
- **Inicio** y **Fin**: las fechas que calcula el planificador.
- **Holgura**: cuántos días se puede retrasar la tarea **sin retrasar el proyecto**. Con holgura cero, la tarea está en el camino crítico.
- **Avance**: el porcentaje realizado, calculado a partir de las horas dedicadas.
- **Desv.**: la desviación frente a la línea base, si la has fijado.

### Tipos de fila

- **Tarea**: un trabajo real, con su duración. Se dibuja como una barra.
- **Resumen**: agrupa a otras. No se planifica por sí misma: empieza cuando arranca la primera de sus hijas y termina con la última. Se dibuja como una barra gruesa con las puntas en pico.
- **Hito**: una fecha señalada sin duración (una entrega, una aprobación, una firma). Se dibuja como un rombo ◆.

Una tarea se convierte en resumen **sola**, en cuanto le cuelgas la primera subtarea, y vuelve a ser tarea normal si le quitas la última.

## Cómo trabajar

### Construir el proyecto

Sobre el árbol, con el **botón derecho** o con el teclado:

- **Insert**: nueva tarea, al mismo nivel que la seleccionada.
- **Mayús + Insert**: nueva subtarea, colgando de la seleccionada.
- **Supr**: eliminar. Si la tarea tiene subtareas, se avisa antes: se borra la rama entera.
- **F2**: renombrar.
- **Tab** y **Mayús + Tab**: aumentar o disminuir la sangría, es decir, mover la tarea un nivel adentro o afuera.
- **Alt + ↑** y **Alt + ↓**: subir o bajar la tarea entre sus hermanas.

También puedes escribir directamente en las columnas **Nombre**, **Duración** e **Inicio**. Fin, Holgura y Avance no se escriben: los calcula el planificador.

### La ficha de la tarea

**Doble clic** sobre una tarea (en el árbol o en su barra) abre su ficha, con cuatro pestañas:

- **Tarea**: nombre, tipo, estado, prioridad, responsable y etiquetas de color.
- **Tiempo**: duración, trabajo, restricción de fecha y horas dedicadas.
- **Operarios**: quién trabaja en ella y con qué porcentaje de dedicación.
- **Comentarios**: notas libres.

### Encadenar tareas

Las dependencias dicen qué va antes que qué. Hay cuatro tipos:

- **Fin → Inicio**: la habitual. B empieza cuando acaba A.
- **Inicio → Inicio**: las dos arrancan a la vez.
- **Fin → Fin**: las dos terminan a la vez.
- **Inicio → Fin**: la menos frecuente.

Cada dependencia admite un **desfase**: días de espera entre una y otra (el hormigón que tiene que fraguar), o negativo, para solapar (empezar la segunda tres días antes de que acabe la primera).

## Duración, trabajo y personas

Tres números que hablan entre sí, con una regla:

> **Trabajo = Duración × Personas**

- **Duración**: lo que la tarea ocupa en el calendario.
- **Trabajo**: lo que cuesta en horas de persona.
- **Personas**: la suma de las dedicaciones de los asignados (uno al 100 % y otro al 50 % son 1,5).

Una tarea puede durar 5 días y costar 8 horas (una persona al 20 %), o durar 1 día y costar 16 (dos personas a jornada completa).

Como son tres cantidades con una sola ecuación, al cambiar una hay que decidir cuál de las otras dos se recalcula. Eso lo dice el **tipo de tarea**, en la pestaña Tiempo:

- **Duración fija**: la duración manda. Poner más gente no acorta la tarea, reparte el mismo calendario entre más manos. *(Una reunión de dos horas dura dos horas vengan los que vengan, pero cuesta más horas de trabajo cuanta más gente asista.)*
- **Trabajo fijo**: el esfuerzo está cerrado. Poner más gente **acorta** la tarea; quitarla la alarga.
- **Personas fijas**: el equipo está cerrado. Más trabajo significa más días.

Si no asignas a nadie, se cuenta como una persona a jornada completa.

## Restricciones de fecha

Por defecto cada tarea se coloca **lo antes posible**, en cuanto sus predecesoras se lo permiten. Cuando hay un compromiso externo, se ata con una restricción, en la pestaña Tiempo:

- **Lo antes posible**: sin atar. Es lo normal.
- **Lo más tarde posible**: pegada al final sin retrasar el proyecto.
- **No comenzar antes del** / **No comenzar después del**: un tope por un lado, libre por el otro.
- **No finalizar antes del** / **No finalizar después del**: lo mismo, mirando el final.
- **Debe comenzar el** / **Debe finalizar el**: fecha clavada. El planificador no la mueve.

Usa las fechas clavadas solo cuando de verdad lo sean: cuantas más pongas, menos puede ayudarte el planificador a recolocar el trabajo.

## El camino crítico

Al recalcular, el planificador marca en **rojo** las tareas cuya holgura es cero: las que, si se retrasan un solo día, retrasan la entrega del proyecto entero.

Es la lista de lo que hay que vigilar. Las tareas con holgura pueden esperar; las críticas, no.

Una tarea resumen se marca como crítica cuando alguna de sus tareas lo es.

## Varios proyectos a la vez

La pantalla puede mostrar **varios proyectos simultáneamente**, cada uno como una rama de primer nivel. Se eligen con el selector de proyectos, y la selección se recuerda para la próxima vez.

Cada proyecto conserva su propio camino crítico y su propia fecha de fin: no se mezclan, porque no hay dependencias entre proyectos.

Lo que sí es común son **las personas**: alguien no deja de estar saturado porque sus dos tareas sean de proyectos distintos. Por eso la sobreasignación se calcula mirando todos los proyectos a la vez.

## Personas y sobreasignación

En la pestaña **Operarios** de la ficha asignas quién hace cada tarea y con qué dedicación. La **banda de carga**, bajo el Gantt, muestra qué hace cada persona y cuándo.

Cuando alguien supera el 100 % de su jornada porque tiene dos tareas solapadas, el planificador lo detecta solo:

- La fila se marca en **ámbar**, en el árbol y en el Gantt.
- El subtítulo de la pantalla avisa con el pico de carga (*"Ana Ruiz sobreasignada (pico 180 %)"*).
- **Botón derecho → Ver sobreasignación** da el detalle: quién, entre qué fechas y por culpa de qué tareas.

Un plan con alguien al 200 % es tan inviable como uno con fechas imposibles, con el agravante de que a simple vista parece correcto.

## Nivelar recursos

Detectar la sobrecarga es la mitad; resolverla es lo que hace **botón derecho → Nivelar recursos**.

Nivelar consiste en **retrasar tareas** hasta que nadie supere su jornada. No se acortan tareas, no se cambia de persona y no se parten trabajos por la mitad: solo se mueven en el tiempo, que es el cambio más pequeño que resuelve el problema.

### Qué se mueve antes

Cuando dos tareas se disputan a la misma persona, alguien tiene que esperar. El orden es este:

1. Las que **no se pueden mover** reservan su sitio primero (fechas clavadas, tareas ya empezadas).
2. Las **críticas** antes que las que tienen holgura: retrasar una crítica retrasa el proyecto; retrasar una con holgura no cuesta nada.
3. A igualdad, la más apretada de holgura.
4. Y después, la que empieza antes.

**Nunca se mueven**: las tareas con fecha clavada (*debe comenzar el* / *debe finalizar el*), las de *lo más tarde posible*, los hitos, las tareas resumen y las que ya tienen horas dedicadas. Mover algo que ya está en marcha es replanificar el pasado.

### La previsualización

No se aplica nada sin enseñártelo antes. La ventana muestra:

- **Arriba**, las cifras que deciden si compensa: sobreasignaciones antes y después, cuántas tareas se mueven, y si el proyecto se retrasa.
- **En medio**, una fila por tarea movida: de cuándo a cuándo, cuánto se retrasa y **por quién espera** (la columna *Espera por*, que es la explicación del retraso).
- **Abajo**, si las hay, las tareas que **no se han podido resolver** y por qué.

Dos interruptores, que recalculan la propuesta al instante para que puedas comparar escenarios:

- **Nivelar sólo dentro de la holgura**: no retrasa la fecha de entrega. Solo mueve tareas hasta donde su holgura lo permite. Es más conservador, pero puede dejar sobrecargas sin resolver, y en tal caso lo dice.
- **Mover también las tareas ya iniciadas**: normalmente desactivado.

Pulsa **Aplicar** para aceptar la propuesta, o **Cancelar** para no tocar nada.

### Qué pasa al aplicar

Cada tarea movida queda con la restricción **"no comenzar antes del"** en su nueva fecha. No es una fecha clavada: si más adelante se acorta una tarea anterior, esta podrá adelantarse hasta ese tope, pero no más.

Puedes deshacer la nivelación de una tarea concreta abriendo su ficha y devolviendo la restricción a **lo antes posible**.

### Si no resuelve todo

Es normal, sobre todo con *sólo dentro de la holgura* activado. El bloque inferior de la ventana lo explica caso por caso. Cuando aparece, las salidas son:

- Desactivar *sólo dentro de la holgura* y aceptar que el proyecto se alargue.
- Repartir la tarea entre más gente, o bajar la dedicación de alguien.
- Revisar si esas fechas clavadas tienen que estarlo de verdad.

## Línea base

La línea base es una **foto del plan** en el momento de aprobarlo. Sirve para responder más tarde a *"¿vamos como dijimos que iríamos?"*.

- **Botón derecho → Fijar línea base**: congela las fechas y el trabajo actuales.
- La columna **Desv.** pasa a mostrar los días de adelanto o de retraso frente a esa foto.
- En el Gantt aparece una **barra fantasma** bajo cada barra real: dónde debería estar la tarea según el plan aprobado.
- **Botón derecho → Quitar línea base** la borra.

Fíjala cuando el plan esté aprobado, no antes: rehacerla borra el histórico de desviaciones y con él la capacidad de explicar qué pasó.

## Resumen del proyecto

**Botón derecho → Resumen del proyecto** abre la ventana que contesta *"¿cómo vamos?"* de un vistazo, en cuatro pestañas.

### General

Las cifras de los cuatro ejes, en tarjetas:

- **Calendario**: inicio, fin previsto, desviación frente a la línea base, días restantes y porcentaje de calendario consumido. Si el proyecto ya debería haber terminado, la tarjeta pasa a *Fuera de plazo*.
- **Esfuerzo**: trabajo planificado, dedicado, restante y exceso sobre el plan.
- **Coste**: lo mismo en euros, calculado con la **tarifa por hora de cada persona asignada** (la de su ficha de operario).
- **Estado del plan**: cuántas tareas hay, porcentaje completado, hechas y en curso, retrasadas, bloqueadas, cuántas están en el camino crítico y cómo van los hitos.

Compara *calendario consumido* con *completado*: si llevas gastado el 70 % del tiempo y solo has hecho el 40 % del trabajo, el proyecto va tarde aunque ninguna tarea lo parezca por separado.

### Esfuerzo

La carga de cada persona (trabajo asignado, dedicado, coste previsto y pico de sobreasignación) y las tareas que más se han desviado de lo estimado.

### Costes

El detalle en euros persona a persona: tarifa, horas previstas y reales, coste previsto e incurrido.

Si alguien no tiene tarifa en su ficha, **no se le inventa una**: sus horas quedan fuera del cálculo y la ventana avisa de cuántas personas y horas no están contadas. Una cifra incompleta advertida es útil; una cifra inventada que parece exacta, no.

### Avance

La **curva de avance** (curva S): cuánto trabajo debería estar hecho en cada semana del proyecto, con un punto verde que marca dónde estás hoy.

El título lo resume en una frase: *por delante* o *por detrás de lo previsto*, y cuántas horas.

Cómo leerla: si el punto verde queda **por encima** de la curva, llevas más trabajo hecho del que tocaba a estas alturas; si queda **por debajo**, vas retrasado aunque ninguna tarea lo parezca por separado.

Dos cosas que conviene saber para no pedirle al gráfico lo que no puede dar:

- La curva prevista reparte el trabajo de cada tarea **de forma uniforme entre sus fechas**. Es la misma hipótesis que usan MS Project y Primavera, y es lo único que se puede afirmar: una tarea dice cuándo empieza, cuándo acaba y cuánto cuesta, pero no cómo se distribuye por dentro.
- **Del trabajo real solo consta el total, no en qué día se hizo.** Por eso hay un punto y no una segunda curva: dibujar la trayectoria pasada sería inventarla. Para tener el histórico completo haría falta anotar las horas con su fecha, que es otra cosa distinta de lo que hoy se registra.

### Riesgos

Lo que conviene mirar hoy, ordenado por gravedad: tareas retrasadas, bloqueadas, hitos vencidos, tareas que vencen esta semana, sobreasignaciones y tareas que se han comido mucho más tiempo del estimado.

Es la pestaña que sustituye a recorrer el árbol buscando problemas.

## Avance

El avance no se teclea como un porcentaje: sale de las **horas dedicadas** que anotas en la ficha, comparadas con las previstas.

En las tareas resumen es la media de sus hijas **ponderada por duración**: una tarea de diez días pesa diez veces más que una de un día.

Puede pasar del 100 %: significa que has dedicado más horas de las previstas. No es un error, es la desviación, y es justo lo que interesa ver. Se marca en ámbar a partir del 110 %.

## Errores frecuentes

- **"Hay dependencias circulares"**: dos tareas se esperan mutuamente, directa o indirectamente. El planificador calcula todo lo demás y te dice cuáles están implicadas; esas conservan sus fechas anteriores hasta que rompas el círculo.
- **Una tarea no se mueve por mucho que cambies lo anterior**: casi siempre tiene una fecha clavada. Ábrela y mira la restricción en la pestaña Tiempo.
- **La duración de un resumen no se deja escribir**: es correcto, sale de sus hijas. Cambia la duración de las subtareas.
- **Nivelar aparece desactivado**: no hay ninguna sobreasignación que resolver.
- **Nivelar no mueve nada**: si está marcado *sólo dentro de la holgura* y las tareas en conflicto son críticas, no hay margen. Desmárcalo para ver la alternativa.
- **Poner más gente no acorta la tarea**: el tipo de tarea es *duración fija*. Cámbialo a *trabajo fijo* en la pestaña Tiempo.

## Por qué es útil

Un proyecto de ingeniería se retrasa por dos motivos, y ninguno se ve a simple vista en una lista de tareas: una cadena de dependencias más larga de lo que parecía, o una persona a la que le hemos pedido tres cosas a la vez.

El **camino crítico** contesta lo primero: de cincuenta tareas, cuáles son las diez que de verdad marcan la fecha de entrega. La **detección de sobreasignación** y la **nivelación** contestan lo segundo, y además proponen el arreglo en lugar de limitarse a señalar el problema.

La **línea base** cierra el círculo: permite explicar, cuando el proyecto ha terminado, en qué momento se torció y por qué.

Pulsa **F1** en cualquier momento para volver a esta ayuda.
