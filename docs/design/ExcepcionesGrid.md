# Excepciones del calendario - Grid DevExpress

## Contexto

Form `uCalendarExceptionsEdit` muestra la lista de excepciones de un calendario.
Hasta ahora usaba `TStringGrid` con dibujo manual. Migrado a **DevExpress `TcxGrid`** para obtener gratis:

- Multiselect con checkbox por fila + header (marcar/desmarcar todo).
- Sort por columna (clic en header).
- Filtro por columna (filter row con caja de texto / combo según tipo).
- Autowidth: la columna Descripción absorbe el espacio restante.
- Look & feel coherente con el resto de la app (DevExpress 23.2.10).

## Componentes usados

- `TcxGrid` + `TcxGridLevel` + `TcxGridDBTableView` (en una primera version la fuente es un `TClientDataSet` en memoria; permite sort/filter sin recargar).
- `TcxGridDBColumn` para cada campo.
- Columna "Sel" con `RepositoryItem = TcxCheckBoxRepositoryItem` (multiselect manual; el built-in `OptionsSelection.CheckBoxVisibility` tambien serviria).
- `FilterRow` activado: `OptionsView.HeaderAutoHeight=True`, `OptionsCustomize.ColumnFiltering=True`, `FilterRow.Visible=True`.

## Columnas

| Col | Caption        | Width                | Sort | Filter | Notas                       |
|-----|----------------|----------------------|------|--------|-----------------------------|
| Sel | (checkbox)     | 36 px fijo           | No   | No     | OnEditValueChanged toggla   |
| 0   | Fecha          | 140 px               | Sí   | DateBetween | DataType date          |
| 1   | Tipo           | 130 px               | Sí   | combo  | Festivo / Pausa             |
| 2   | Horario        | 110 px               | Sí   | text   | Solo cuando Tipo=Pausa      |
| 3   | Descripción    | autowidth (resto)    | Sí   | text   | `Options.HorzSizing=False` al resto y True a esta |

## Dataset

`TClientDataSet` con campos:
- `ExceptionId` (INT, hidden)
- `Fecha` (TDateField)
- `EsLaborable` (TBooleanField, hidden — solo para distinguir tipos al pintar)
- `Tipo` (TStringField) — calculado al cargar
- `Horario` (TStringField) — calculado al cargar
- `Descripcion` (TStringField)
- `Sel` (TBooleanField, no persistente) — bound a la columna checkbox

La pestaña Tipo/Horario se calcula al `Reload` desde `TCalendarExceptionRec`.

## Acciones toolbar

- **Añadir...** / **Editar...** / **Eliminar**: igual que antes (sobre fila seleccionada).
- **Eliminar seleccionadas**: itera el dataset, recoge `ExceptionId` donde `Sel=True`, confirma y llama `FRepo.DeleteException` por cada uno.

## Decisión: por qué cxGrid y no cxVerticalGrid o un StringGrid retocado

- Sort manual en StringGrid son ~80 líneas (TList<Record> + comparator + repaint).
- Filtro manual son ~200 líneas (input row + filtrar arrays + repintar).
- Multiselect manual ya implementado pero requiere mantener consistencia.
- Migrar a cxGrid: ~50 líneas de configuración, todo gratis. Mantenimiento futuro mucho menor.

## Patron reutilizable

Este grid debe servir de plantilla para otros editores de "lista plana con CRUD" en el proyecto (centros, máquinas, etc.) que aún están en `TStringGrid`.
