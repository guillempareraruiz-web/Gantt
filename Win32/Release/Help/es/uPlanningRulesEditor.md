# Reglas de Planificación

> Defina cómo quiere que el planificador ordene, filtre y agrupe los trabajos, y cuánto tiempo cuesta cada cambio de trabajo en una línea.

## ¿Qué hace?

Esta ventana tiene dos pestañas:

- **Ordenación y agrupación**: en qué orden entra la carga, qué se excluye y qué trabajos conviene juntar.
- **Tiempo de cambio**: cuántos minutos se pierden cuando un trabajo cambia de característica respecto al anterior en la misma línea.

Las reglas se guardan en **perfiles**, para que pueda tener varias configuraciones (por ejemplo una para el día a día y otra para urgencias) y cambiar de una a otra con el desplegable de arriba.

## Ordenación y agrupación

Trabaja con tarjetas, en tres columnas:

- **Criterios de orden**: por qué campo se ordena la cola (fecha, prioridad, o un campo suyo). Puede encadenar varios y darles peso.
- **Reglas de filtro**: incluir o excluir trabajos según una condición, o forzarlos a una línea concreta.
- **Agrupación**: juntar los trabajos que comparten un valor (por ejemplo el mismo color) para que caigan consecutivos y **evitar cambios innecesarios**.

En cada columna, pulse **+ Añadir** para crear una tarjeta y ajústela. La casilla **Activa** enciende o apaga la regla sin borrarla.

## Tiempo de cambio

Aquí indica **cuánto cuesta cada cambio** entre dos trabajos seguidos en la misma línea. Cada tarjeta es una regla:

- **Atributo**: qué característica, al cambiar, provoca el tiempo de preparación (por ejemplo *Color*, *Substrato* o el artículo).
- **+ min**: minutos que se suman cuando ese atributo cambia de un trabajo al siguiente.
- **Línea**: a qué línea se aplica la regla, o *(Todas las líneas)*.

Las reglas se **suman**: si un trabajo cambia de color y de substrato a la vez, se suman los minutos de ambas.

Abajo, un indicador muestra en todo momento el **tiempo de cambio total del plan actual** con las reglas que tenga puestas. Si agrupa bien los trabajos afines (pestaña anterior), verá cómo ese tiempo baja: es el ahorro real de máquina que consigue.

## Cómo se usa

1. Elija o cree un **perfil** arriba.
2. En **Ordenación y agrupación**, configure el orden, los filtros y las agrupaciones.
3. En **Tiempo de cambio**, añada las reglas de preparación de sus líneas y observe el indicador.
4. Pulse **Aceptar** para guardar. Las reglas se aplicarán la próxima vez que planifique.

## Consejo

Combine las dos pestañas: agrupe por *color* o *substrato* y ponga un tiempo de cambio para esos mismos atributos. Así el planificador no solo junta los trabajos afines, sino que **entiende cuánto le ahorra** hacerlo, y lo tiene en cuenta al colocar la carga.
