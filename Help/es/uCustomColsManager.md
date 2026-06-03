# Campos personalizados (columnas)

## ¿Qué hace esta pantalla?

Es el **punto único** para crear y gestionar las **columnas personalizadas** que se muestran en las distintas listas del programa: el Backlog de pendientes, los centros de trabajo, los operarios y las máquinas.

Una columna personalizada le permite guardar y ver información propia de su empresa que el programa no trae de serie (por ejemplo: un lote, un acabado, una observación, una referencia interna...).

## Cómo se usa

1. En **Entidad**, elija a qué lista quiere añadir o quitar columnas:
   - **Backlog (pendientes)**: las columnas del grid de operaciones pendientes.
   - **Centros de trabajo**, **Operarios**, **Máquinas**: las columnas de cada listado.
2. Pulse **Gestionar columnas...**. Se abre la lista de columnas de esa entidad, donde puede:
   - **Añadir** una columna nueva (nombre visible, tipo de dato y, en el Backlog, a qué origen y nivel se asocia).
   - **Editar** una existente.
   - **Quitar** una (no se pierden los datos ya guardados; solo deja de mostrarse).

## El caso del Backlog

Las columnas del Backlog tienen dos opciones extra, porque los pendientes vienen de documentos del ERP con jerarquía:

- **Origen**: si el campo pertenece a la **OF / Pedido / Proyecto**.
- **Nivel**: si se asocia al documento (OF), a su línea (OT), o a la operación (OP).

Así, por ejemplo, puede tener una columna "Acabado" que viva a nivel de operación (OP) y otra "Cliente final" a nivel de OF.

## Nota

Los campos personalizados de los **nodos del Gantt** (los que usan el motor de reglas y las tarjetas) se gestionan por separado, en **Campos de nodos (reglas/cards)**. Está previsto unificarlo todo más adelante.
