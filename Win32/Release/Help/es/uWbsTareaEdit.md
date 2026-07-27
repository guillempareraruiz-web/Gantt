# Ficha de tarea

## Objetivo

Editar todo lo que define una tarea de un proyecto de ingeniería: qué es, cuánto dura, cuánto cuesta, quién la hace y cuándo puede o debe ocurrir.

Se abre con **doble clic** sobre una tarea, tanto en el árbol como en su barra del diagrama.

Arriba, junto al nombre, se muestra el **avance** de la tarea, calculado a partir de las horas dedicadas.

## Pestaña Tarea

Qué es la tarea y en qué punto está.

- **Nombre**: el título que aparece en el árbol y en la barra.
- **Tipo**:
  - *Tarea*: un trabajo real, con duración. Se dibuja como una barra.
  - *Resumen*: agrupa a otras. No se planifica sola: sus fechas salen de sus hijas.
  - *Hito*: una fecha señalada sin duración (una entrega, una aprobación). Se dibuja como un rombo ◆.

  Normalmente no hace falta tocarlo: una tarea pasa a resumen sola en cuanto le cuelgas una subtarea, y vuelve a ser tarea al quitarle la última.

- **Estado**: *Pendiente*, *En curso*, *Bloqueada*, *Hecha* o *Cancelada*. Es una declaración tuya sobre la marcha del trabajo; no cambia las fechas.
- **Prioridad**: *Baja*, *Normal*, *Alta* o *Crítica*. No debe confundirse con el **camino crítico**, que lo calcula el planificador a partir de las dependencias: la prioridad es tu criterio, el camino crítico es un hecho del plan.
- **Responsable**: la persona que responde de la tarea. Es distinto de los operarios que la ejecutan (pestaña Operarios): el responsable no consume horas por figurar aquí.
- **Etiquetas**: marcas de color reutilizables para clasificar tareas (disciplina, cliente, fase...). Se definen una vez y se asignan a las tareas que haga falta.

## Pestaña Tiempo

Lo que más influye en el plan.

### Duración, trabajo y personas

Tres cantidades ligadas por una regla:

> **Trabajo = Duración × Personas**

- **Duración**: lo que la tarea ocupa en el calendario, en días laborables.
- **Trabajo**: lo que cuesta, en horas de persona.
- **Personas**: la suma de las dedicaciones de los asignados en la pestaña Operarios (uno al 100 % y otro al 50 % suman 1,5). Sin nadie asignado se cuenta como una persona a jornada completa.

Una tarea puede durar 5 días y costar 8 horas (una persona al 20 %), o durar 1 día y costar 16 (dos personas a jornada completa). Duración y trabajo **no son lo mismo**, y confundirlos es el error más habitual al planificar proyectos.

### Tipo de tarea

Como son tres cantidades con una sola regla, al cambiar una hay que decidir cuál de las otras dos se recalcula. Eso es lo que dice este campo:

- **Duración fija**: la duración manda. Poner más gente no acorta la tarea, reparte el mismo calendario entre más manos, así que sube el trabajo.
  *Ejemplo: una reunión de dos horas dura dos horas vengan los que vengan, pero cuesta más horas cuanta más gente asista.*
- **Trabajo fijo**: el esfuerzo está cerrado (lo dice el presupuesto). Poner más gente **acorta** la tarea; quitarla la alarga.
  *Ejemplo: pintar 400 m² son 400 m² los pinte uno o los pinten cuatro.*
- **Unidades fijas**: el equipo está cerrado (son estos y no hay más). Más trabajo significa más días.

Si al añadir gente la tarea no se acorta y esperabas que lo hiciera, casi siempre es porque el tipo es *duración fija*. Cámbialo a *trabajo fijo*.

### Restricción de fecha

Por defecto la tarea se coloca **lo antes posible**, en cuanto sus predecesoras lo permiten. Cuando hay un compromiso externo, se ata aquí:

| Restricción | Qué significa |
|---|---|
| **Lo antes posible** | Sin atar. Lo normal. |
| **Lo más tarde posible** | Pegada al final, sin retrasar el proyecto. |
| **No comenzar antes del** | Un suelo: puede empezar ese día o después. |
| **No comenzar después del** | Un techo por el inicio. |
| **No finalizar antes del** | Un suelo por el final. |
| **No finalizar después del** | Un techo por el final: el compromiso de entrega. |
| **Debe comenzar el** | Fecha clavada de inicio. |
| **Debe finalizar el** | Fecha clavada de fin. |

Las dos últimas el planificador **no las mueve nunca**, ni al recalcular ni al nivelar recursos. Úsalas solo cuando la fecha lo sea de verdad: cuantas más pongas, menos margen tiene el planificador para ayudarte a recolocar el trabajo.

Si tecleas una fecha de inicio directamente en el árbol, equivale a poner aquí *no comenzar antes del*.

### Horas dedicadas

Las horas realmente invertidas hasta la fecha. De aquí sale el **avance**: no se teclea un porcentaje, se anotan las horas y el porcentaje se calcula solo.

Puede pasar del 100 %: significa que has dedicado más de lo previsto. No es un error, es la desviación, y es justo lo que interesa ver.

## Pestaña Operarios

Quién trabaja en la tarea y con qué **porcentaje de dedicación**: 100 significa a jornada completa; 50, media jornada.

La dedicación no es decorativa. Tiene tres efectos:

1. Alimenta las **personas** de la ecuación de arriba, y por tanto puede recalcular la duración o el trabajo según el tipo de tarea.
2. Aparece en la **banda de carga** bajo el diagrama.
3. Si alguien supera el 100 % sumando tareas solapadas, el planificador lo marca como **sobreasignado** y puede resolverlo con *Nivelar recursos*.

Cada asignado tiene también sus **horas imputadas**, para saber quién ha dedicado qué.

En las tareas resumen no se asigna gente: se asigna en las tareas concretas, y el resumen agrega.

## Pestaña Comentarios

Notas libres: acuerdos, motivos de un retraso, pendientes. No afectan al cálculo, pero son lo que permite entender meses después por qué el plan es como es.

## Errores frecuentes

- **La duración no se deja escribir**: la tarea es un **resumen**. Su duración sale de sus hijas; cambia la de las subtareas.
- **Un hito no acepta duración**: por definición no dura. Si necesitas que dure, no es un hito: cámbialo a tarea.
- **Cambio la fecha de inicio y vuelve a moverse**: la restricción sigue en *lo antes posible* y manda la dependencia anterior. Ponle *no comenzar antes del*.
- **Añado gente y la tarea no se acorta**: el tipo es *duración fija*. Cámbialo a *trabajo fijo*.
- **La tarea no se mueve al nivelar recursos**: tiene una fecha clavada (*debe comenzar el* / *debe finalizar el*), o ya tiene horas dedicadas.
- **El avance pasa del 100 %**: has dedicado más horas de las estimadas. Es información, no un fallo.

## Por qué es útil

En un proyecto, casi todo lo que se tuerce se explica en esta ventana: una duración estimada a ojo, un compromiso de fecha que nadie apuntó, o una persona a la que se le ha asignado el 60 % de tres tareas a la vez.

Separar **duración**, **trabajo** y **personas** es lo que permite responder a la pregunta que un cronograma solo no contesta: *si le pongo otra persona, ¿acabamos antes o simplemente gastamos más?*

Pulsa **F1** en cualquier momento para volver a esta ayuda.
