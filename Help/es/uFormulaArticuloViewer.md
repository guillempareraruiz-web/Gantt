# Fórmula del artículo (escandallo)

## ¿Qué hace esta pantalla?

Muestra **de qué está hecho un artículo**: los materiales que lo componen y las operaciones necesarias para fabricarlo, tal y como están definidos en su ERP.

Es una pantalla de **solo consulta**. Nada de lo que vea aquí se modifica desde el programa: los datos se leen directamente del ERP cada vez que abre la pantalla, así que siempre ve la información actualizada.

## Las tres zonas

**Izquierda — Estructura.** El árbol del artículo, con dos ramas:

- **Componentes**: los materiales y piezas que lo forman.
- **Operaciones**: los pasos de fabricación.

**Arriba a la derecha — Componentes.** El detalle de cada material: unidades necesarias, mermas previstas y coste.

**Abajo a la derecha — Operaciones.** Cada paso de fabricación con su centro de trabajo y sus tiempos de preparación y fabricación.

En la cabecera, dos contadores le indican de un vistazo **cuántos componentes y cuántas operaciones** tiene lo que está viendo en ese momento.

## Artículos dentro de artículos

Algunos componentes no son materiales simples, sino **semielaborados**: piezas que a su vez se fabrican y tienen su propia fórmula. Aparecen marcados como *Semielab.* en la columna Tipo.

Para ver de qué está hecho un semielaborado, **haga doble clic sobre él** en el árbol de la izquierda. Su fórmula se despliega en ese momento, y puede seguir bajando tantos niveles como tenga el artículo.

Se cargan solo al abrirlos, no todos de golpe: así la pantalla abre rápido aunque el artículo tenga una estructura muy profunda.

## Versiones de la fórmula

Un artículo puede tener **varias versiones** de su fórmula (por ejemplo, una anterior y otra vigente). Use el desplegable **Fórmula** de arriba a la izquierda para cambiar de una a otra.

La casilla **Ver solo componentes con fórmula** deja a la vista únicamente los semielaborados, ocultando los materiales simples. Resulta útil cuando quiere centrarse en la estructura de fabricación y no en el detalle de materiales.

## Nota

Si al abrir la pantalla aparece un aviso de que no hay ningún ERP activo, revise la configuración de conexión con el ERP. Sin ella, esta pantalla no tiene de dónde leer las fórmulas.
