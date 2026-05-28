# Gestión de Card Layouts

## Objetivo

Los **card layouts** controlan el aspecto de las tarjetas (cards) que se ven en el Planificador de capacidad finita, el Backlog y otras pantallas de planificación: qué campos aparecen, en qué fila, con qué color, tamaño y orden.

Esta ventana permite **crear, duplicar, editar y eliminar** conjuntos de layouts, y elegir cuál está activo en cada momento.

## La pantalla

A la izquierda hay una **lista** con todos los layouts disponibles:

- **Privados**: solo los ve el usuario que los creó.
- **Comunes**: visibles por todos los usuarios de la empresa.
- **Por defecto (sistema)**: el layout base que viene con la aplicación. No se puede editar ni eliminar.

A la derecha se ve una **vista previa** del layout seleccionado, con un combo para cambiar la categoría de tarjeta que se muestra (OF pendiente, OF planificada, Pedido, Proyecto, etc.).

## Acciones

- **Nuevo**: crea un layout vacío y abre el editor. Al guardar se pide nombre y si debe ser privado o común.
- **Editar**: abre el editor con el layout seleccionado. Doble clic sobre una fila hace lo mismo.
- **Duplicar**: crea una copia del layout seleccionado. Útil para partir de uno existente y ajustar pequeños cambios.
- **Eliminar**: borra el layout (excepto el "Por defecto (sistema)").
- **Activar**: marca el layout seleccionado como el que se usa en las pantallas de planificación.

## Filtro

El combo superior permite filtrar la lista por **Todos / Privados / Comunes**.

## Sugerencias

- Antes de modificar un layout que se usa en producción, **duplícalo** y trabaja sobre la copia para no afectar al resto del equipo.
- Los layouts **comunes** se pintan a todos los usuarios. Coordina cambios con el resto del equipo antes de tocarlos.
- Cada categoría de tarjeta (OF, Pedido, Proyecto…) tiene su propio layout dentro del conjunto. Recuerda revisar todas las categorías relevantes al editar.
