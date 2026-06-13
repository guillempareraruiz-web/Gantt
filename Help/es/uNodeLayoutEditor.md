# Diseñador de Nodos del Gantt

## Objetivo

Personalizar **qué información muestra cada nodo del Gantt y con qué aspecto**, de forma distinta para cada Vista (Normal, Fabricación, Fecha de entrega, Stock...).

Cada empresa trabaja de una manera: unos quieren ver la OF y el operario, otros el artículo y la fecha de entrega, otros un color de aviso cuando una entrega se retrasa. Esta pantalla permite que cada cliente diseñe el contenido del nodo a su gusto, sin tocar el tamaño (el ancho lo marca la duración y el alto la fila del centro).

## La pantalla

- **Vista** (arriba): elige para qué Vista del Gantt estás diseñando. Cada Vista guarda su propio diseño.
- **Filas y elementos** (izquierda): el contenido del nodo se organiza en filas, y cada fila contiene elementos (un texto, una etiqueta de color "badge", una barra de progreso...). Puedes añadir, quitar, reordenar y editar cada elemento.
- **Previsualización** (derecha): muestra en tiempo real cómo quedará el nodo con datos de ejemplo, usando exactamente la misma técnica de dibujo que el Gantt.
- **Propiedades** (abajo a la derecha): ajustes globales del nodo para esa Vista: márgenes, radio de esquina, color de fondo y de borde, grosor del borde y tipo de letra.

## Cómo diseñar un nodo

1. Elige la **Vista** que quieres personalizar.
2. Añade las **filas** que necesites y, dentro de cada una, los **elementos**.
3. Edita un elemento (doble clic o botón Editar) para definir:
   - **Tipo**: texto, badge (etiqueta con fondo de color), barra de progreso o espaciador.
   - **Expresión**: el texto a mostrar, donde puedes insertar campos entre llaves, p.ej. `OF {NumeroOrdenFabricacion} - {Operacion}`.
   - **Fuente, color, alineación y ancho**.
   - **Reglas condicionales**: cambian el color o el estilo según el valor de un campo. Por ejemplo: "si la fecha de entrega es anterior a HOY, fondo rojo". Es la opción que más valor aporta para detectar de un vistazo lo importante.
4. Mira la **previsualización** y ajusta hasta que quede como quieres.
5. Pulsa **Aceptar** para guardar.

## Diseños por usuario

El diseño se guarda **por usuario**: cada persona puede tener el suyo. Existe siempre un diseño "Por defecto (sistema)" como punto de partida. Al guardar tus cambios se crea o actualiza tu diseño personal, sin afectar al de los demás.

## Consejo

El nodo del Gantt es **bajo y de ancho variable** (depende de la duración de la operación). Lo más útil es mostrar 1-3 líneas con lo esencial (OF, estado, operarios, fecha) y apoyarse en las **reglas condicionales** de color para resaltar avisos, más que intentar meter mucha información que no cabrá en los nodos cortos.

Pulsa **F1** en cualquier momento para volver a esta ayuda.
