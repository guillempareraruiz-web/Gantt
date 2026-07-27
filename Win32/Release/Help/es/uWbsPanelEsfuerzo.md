# Resumen del proyecto

## Objetivo

Responder a *"¿cómo va el proyecto?"* de un vistazo, en los cuatro ejes que se preguntan en cualquier seguimiento: **calendario**, **esfuerzo**, **coste** y **progreso**.

Se abre desde la pantalla de Ingeniería con **botón derecho → Resumen del proyecto**. Si estás viendo varios proyectos a la vez, las cifras son del conjunto.

La ventana no cambia nada: solo lee y presenta.

## Pestaña General

Las cifras de los cuatro ejes, en tarjetas.

### Calendario

Inicio, fin previsto, desviación frente a la línea base, días restantes y porcentaje de calendario consumido.

- El **fin previsto** se colorea según la línea base: rojo si llega más tarde de lo prometido, verde si llega en fecha o antes.
- Si el proyecto ya debería haber terminado, la tarjeta de días restantes pasa a **Fuera de plazo**.

### Esfuerzo

Trabajo planificado, dedicado, restante y exceso sobre el plan, más la desviación frente a la línea base.

### Coste

Lo mismo en euros, calculado con la **tarifa por hora de cada persona asignada**, que se toma de su ficha de operario.

Si nadie tiene tarifa, la tarjeta dice **No calculable** en lugar de mostrar ceros: cero euros significaría que el proyecto es gratis, y lo que ocurre es que falta el dato.

### Estado del plan

Cuántas tareas hay, porcentaje completado, hechas y en curso, retrasadas, bloqueadas, cuántas están en el camino crítico y cómo van los hitos.

### La lectura más útil de esta pestaña

Compara **calendario consumido** con **completado**. Si llevas gastado el 70 % del tiempo y solo has hecho el 40 % del trabajo, el proyecto va tarde aunque ninguna tarea lo parezca por separado. Es el aviso que ningún otro sitio del programa te da.

## Pestaña Esfuerzo

**Carga por persona**: trabajo asignado, dedicado, coste previsto y pico de sobreasignación de cada uno. Quien tenga un pico por encima del 100 % aparece marcado.

**Tareas con mayor desviación**: las que más se han pasado del tiempo estimado, ordenadas de peor a mejor. Es por donde conviene empezar a mirar.

## Pestaña Costes

El detalle en euros, persona a persona: tarifa, horas previstas y reales, coste previsto e incurrido.

Si alguien no tiene tarifa en su ficha, **no se le inventa una**: sus horas quedan fuera del cálculo y el pie de la pestaña avisa de cuántas personas y cuántas horas no están contadas.

Una cifra incompleta advertida sirve para decidir; una cifra inventada que parece exacta, no.

## Pestaña Avance

La **curva de avance** (curva S): cuánto trabajo debería estar hecho en cada semana del proyecto, con un punto verde que marca dónde estás hoy.

El título lo resume en una frase: *por delante* o *por detrás de lo previsto*, y cuántas horas.

**Cómo leerla**: si el punto verde queda por **encima** de la curva, llevas más trabajo hecho del que tocaba a estas alturas; si queda por **debajo**, vas retrasado aunque ninguna tarea lo parezca por separado.

Dos cosas que conviene saber para no pedirle al gráfico lo que no puede dar:

- La curva prevista reparte el trabajo de cada tarea **de forma uniforme entre sus fechas**. Es la misma hipótesis que usan MS Project y Primavera, y es lo único que se puede afirmar: una tarea dice cuándo empieza, cuándo acaba y cuánto cuesta, pero no cómo se reparte por dentro.
- **Del trabajo real solo consta el total, no en qué día se hizo.** Por eso hay un punto y no una segunda curva: dibujar la trayectoria pasada sería inventarla.

Si el proyecto **aún no ha empezado**, el gráfico lo dice y no da desviación: con cero trabajo previsto a día de hoy, cualquier hora dedicada saldría como adelanto, y sería falso.

## Pestaña Riesgos

Lo que conviene mirar hoy, ordenado por gravedad:

- **Retrasada**: debería haber terminado y no consta hecha.
- **Bloqueada**: así la has marcado en su ficha.
- **Hito vencido**: una fecha comprometida que ya ha pasado.
- **Vence pronto**: acaba en los próximos siete días.
- **Sobreasignación**: alguien supera su jornada en esa tarea.
- **Desviada**: se ha comido bastante más tiempo del estimado.

Una tarea puede aparecer por más de un motivo. No se oculta el segundo: si algo está retrasado **y** sobreasignado, lo segundo suele ser la causa de lo primero.

Cuando no hay nada que señalar, la pestaña lo dice.

## Errores frecuentes

- **El coste sale a cero o "No calculable"**: falta la tarifa por hora en la ficha de los operarios asignados.
- **La desviación de coste frente a la línea base no cuadra al céntimo**: la línea base congela fechas y trabajo, no importes, así que el coste de referencia se estima con la tarifa media del proyecto.
- **El porcentaje completado pasa del 100 %**: se han dedicado más horas de las estimadas. Es la desviación, no un fallo.
- **"vs. línea base" dice *sin fijar***: no has fijado ninguna línea base todavía. Se hace desde el árbol, con botón derecho → Fijar línea base.

## Por qué es útil

Un proyecto rara vez se tuerce de golpe: se tuerce un poco cada semana, y nadie lo ve hasta que la fecha de entrega ya es imposible.

Esta ventana junta en un sitio las cuatro señales que lo delatan antes: que el calendario se consume más rápido que el trabajo, que las horas dedicadas superan las previstas, que el coste se desvía y que hay tareas paradas o vencidas.

Pulsa **F1** en cualquier momento para volver a esta ayuda.
