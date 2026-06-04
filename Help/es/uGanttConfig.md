# Preferencias del Gantt

## ¿Qué hace esta pantalla?

Reúne en un solo sitio **todos los ajustes del Gantt y de la auto-planificación**, guardados **para su usuario**. Cada persona puede tener sus propias preferencias sin afectar a las de los demás.

Lo que configure aquí actúa como **valores por defecto**: cuando lance una auto-planificación desde el Backlog, la ventana de planificación ya aparecerá con estos valores puestos, y podrá ajustarlos puntualmente para esa tanda concreta sin cambiar los de aquí.

Los ajustes están agrupados en categorías que puede plegar y desplegar.

---

## Planificación

Define **cómo** se reparte el trabajo cuando se auto-planifica.

- **Modo**
  - **Forward**: empieza en la fecha indicada y va colocando el trabajo hacia delante.
  - **Backward**: parte de la fecha de entrega de cada trabajo y va hacia atrás.
- **Orden**: con qué criterio se ordena la cola antes de colocarla.
  - **Por FechaCompromiso**: primero lo que vence antes.
  - **Por Prioridad**: primero lo más prioritario.
- **Colocación**: qué hacer frente a los trabajos que **ya están** en el centro.
  - **Añadir al final de la cola**: el trabajo nuevo se pone siempre detrás del último, sin buscar huecos.
  - **Rellenar huecos válidos**: busca el primer hueco libre que cumpla los umbrales (ver abajo) y coloca ahí; si no hay ninguno, al final.
  - **Rellenar huecos y desplazar**: igual, pero si el hueco sirve aunque el trabajo no quepa entero, empuja hacia delante los trabajos posteriores para hacerle sitio (nunca mueve los que ya están consolidados).

---

## Huecos

Estos límites evitan que el plan se llene de **huecos minúsculos** difíciles de seguir en planta. Un hueco solo se usa para insertar si cumple **las dos condiciones**:

- **Hueco mínimo (min)**: un hueco más corto que esto nunca se usa. Por ejemplo, con 30 minutos, un hueco de 10 minutos entre dos trabajos se ignora.
- **% mínimo del nodo**: el hueco debe ser al menos ese porcentaje de la duración del trabajo. Con 50 %, en un trabajo de 4 horas solo se aprovechan huecos de 2 horas o más.
- **Mínima distancia entre nodos (min)**: separación obligatoria que se deja **entre un trabajo y el siguiente** en el mismo centro. Útil cuando entre dos tareas hace falta un margen (preparación, limpieza, traslado). Con 0 no se deja separación.

> Consejo: si nota que la planificación "mete" trabajos en huecos demasiado pequeños, suba el **hueco mínimo** o el **% mínimo del nodo**.

---

## Visualización

Ajustes del aspecto del Gantt. Se aplican al momento al aceptar.

- **Ocultar fines de semana**: no muestra sábados y domingos, para ver más compacto.
- **Mostrar links**: cuándo se ven las líneas de dependencia entre trabajos (nunca, solo en el seleccionado, o siempre).
- **Marcadores automáticos**: muestra marcas automáticas en la línea de tiempo.
- **Zoom (px/min)**: nivel de detalle horizontal. Un valor mayor amplía; uno menor muestra más periodo de un vistazo.

---

## Cómo se usa

1. Abra el menú **Configuración → Preferencias del Gantt...**
2. Ajuste los valores en cada categoría.
3. Pulse **Aceptar** para guardar. Los cambios de visualización se aplican enseguida al Gantt; los de planificación se usarán la próxima vez que planifique.

Sus preferencias quedan guardadas y se recuperan automáticamente cada vez que entra.
