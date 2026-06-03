# Mapeo de campos ERP

> Pantalla para el **integrador** (quien conoce el ERP). Permite que una columna personalizada del Backlog se rellene automáticamente desde Sage durante la sincronización.

## ¿Qué hace?

Cada columna personalizada del Backlog puede:
- Rellenarse **a mano** (lo que ya se hace tecleando en la celda), o
- Rellenarse **automáticamente desde el ERP**, si aquí le indicamos de qué campo de Sage sale.

Esta pantalla asocia cada columna a una **expresión SQL** contra Sage. Durante la sincronización, el valor del ERP se guarda en la columna; los valores que el usuario haya puesto a mano **nunca se pisan**.

## Cómo se usa

1. En la lista de arriba, seleccione la columna personalizada que quiere alimentar desde el ERP.
2. En **Expresión SQL**, escriba de dónde sale el valor en Sage. La tabla base depende del nivel de la columna seleccionada, y se usa el alias indicado:
   - Nivel de orden de fabricación → alias `[of]` (Órdenes de Fabricación)
   - Nivel de orden de trabajo → alias `[ot]` (Órdenes de Trabajo)
   - Nivel de operación → alias `[op]` (Operaciones)

   Ejemplos (nivel orden de fabricación):
   - `[of].CampoLibre1`
   - `LTRIM([of].Observaciones)`
   - `art.Acabado` (si añade el JOIN correspondiente abajo)
3. En **JOINs adicionales** (opcional), añada los JOIN que su expresión necesite. Ejemplo:
   `LEFT JOIN Articulos art ON art.CodigoArticulo = [of].CodigoArticulo`
4. Pulse **Probar**: ejecuta una consulta de prueba contra Sage —sobre la tabla del nivel de la columna— y muestra unas muestras del valor (o el error de SQL). Úselo siempre antes de guardar.
5. Marque **Activo** si quiere que se aplique en las sincronizaciones.
6. Pulse **Guardar**.

Para desvincular una columna del ERP (que vuelva a ser solo manual), use **Quitar mapeo**.

## Importante

- Los valores que un usuario haya editado a mano (origen MANUAL) **tienen prioridad** y la sincronización del ERP no los sobrescribe.
- Las expresiones SQL las escribe el integrador. Una expresión mal formada se detecta con **Probar** antes de guardar.
- De momento el mapeo aplica al **Backlog**. Otras entidades se podrán añadir más adelante.
