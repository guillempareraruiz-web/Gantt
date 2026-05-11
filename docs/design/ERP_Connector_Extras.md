# Connector ERP — Escritura en `FS_PL_RawItem_Extra`

Documento de referencia para cuando se implementen (o se actualicen) los
conectores ERP que pueblen los campos custom del planificador.

> **Estado actual:** ningún conector escribe todavía aquí. Las taules
> antiguas `FS_PL_Raw_OF_Extra` / `FS_PL_Raw_Comanda_Extra` /
> `FS_PL_Raw_Projecte_Extra` (modelo pre-V016) están en desuso y serán
> eliminadas en una migración futura una vez se haya migrado su contenido
> a `FS_PL_RawItem_Extra`.

## 1. Modelo

Tabla única para todos los extras del Raw_Item, sin importar el nivel
(1 cabecera, 2 intermedio, 3 OP) ni la familia (OF, PED, PRJ).

```sql
FS_PL_RawItem_Extra (
    CodigoEmpresa  SMALLINT,
    RawItemId      BIGINT,        -- FK a FS_PL_Raw_Item.RawItemId
    FieldKey       VARCHAR(64),   -- p.ej. 'COLOR', 'DIM_ANCHO'
    FieldValue     NVARCHAR(MAX),
    Source         CHAR(6),       -- 'ERP' | 'MANUAL'
    UpdatedBy      NVARCHAR(64),
    UpdatedAt      DATETIME2,
    PRIMARY KEY (CodigoEmpresa, RawItemId, FieldKey)
)
```

`FieldKey` se corresponde con `FS_PL_Cfg_GridColumns.ColumnKey` (o con
`SourceExpression` si está informado), que es el catálogo de columnas
custom que ya entiende la pantalla Backlog.

## 2. Política Source

| Source     | Quién la escribe | Quién la puede sobreescribir |
|------------|------------------|------------------------------|
| `ERP`      | Conector ERP     | Conector ERP en cada import; usuario manual |
| `MANUAL`   | Usuario (UI)     | Usuario manual; **NUNCA** el conector ERP   |

**Regla clave del conector**: cualquier UPSERT debe excluir filas
`Source='MANUAL'`. El usuario que ha hecho un override gana.

## 3. Patrón de escritura recomendado (MERGE)

Para cada combinación (RawItemId, FieldKey) que el ERP quiera publicar:

```sql
MERGE FS_PL_RawItem_Extra AS T
USING (SELECT
        @CodigoEmpresa AS CodigoEmpresa,
        @RawItemId     AS RawItemId,
        @FieldKey      AS FieldKey
      ) AS S
   ON T.CodigoEmpresa = S.CodigoEmpresa
  AND T.RawItemId     = S.RawItemId
  AND T.FieldKey      = S.FieldKey
WHEN MATCHED AND T.Source <> 'MANUAL' THEN
     UPDATE SET
        FieldValue = @FieldValue,
        Source     = 'ERP',
        UpdatedBy  = @ConnectorId,        -- p.ej. 'SAGE200'
        UpdatedAt  = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
     INSERT (CodigoEmpresa, RawItemId, FieldKey, FieldValue,
             Source, UpdatedBy, UpdatedAt)
     VALUES (S.CodigoEmpresa, S.RawItemId, S.FieldKey, @FieldValue,
             'ERP', @ConnectorId, SYSUTCDATETIME());
```

Notas:

- La cláusula `WHEN MATCHED AND T.Source <> 'MANUAL'` es la que protege
  los overrides del usuario. Si la fila ya existe con `MANUAL`, el
  `MERGE` no la toca.
- `UpdatedBy` debe identificar el conector (p.ej. `'SAGE200'`,
  `'SAP_B1'`), no un usuario humano. Es útil para auditoría.

## 4. Borrado de valores que ya no vienen del ERP

Cuando un campo deja de aparecer en el ERP, el conector debe borrar la
fila correspondiente — pero **solo si era de origen ERP**:

```sql
DELETE FROM FS_PL_RawItem_Extra
 WHERE CodigoEmpresa = @CodigoEmpresa
   AND RawItemId     = @RawItemId
   AND FieldKey      = @FieldKey
   AND Source        = 'ERP';
```

Una fila `MANUAL` permanece aunque el ERP haya dejado de publicar el
valor: es un override consciente del usuario.

## 5. ¿A qué `RawItemId` apunto?

Depende del nivel al que aplique el campo. Lo sabe el catálogo:

- `FS_PL_Cfg_GridColumns.AppliesToNivel = 1` → `RawItemId` del Nivel=1
  (cabecera: OF / PEDIDO / PROYECTO).
- `AppliesToNivel = 2` → `RawItemId` del Nivel=2 (OT / LINEA / TAREA).
- `AppliesToNivel = 3` → `RawItemId` del Nivel=3 (OP).

El conector debe consultar el catálogo de columnas activas
(`IsCustomField=1 AND Activo=1`) para saber a qué nivel del Raw_Item
publicar cada `FieldKey`.

## 6. Operación masiva: staging + MERGE

Para importes grandes, el patrón eficiente es:

1. Bulk-insert en una tabla temporal `#StagingExtras` con todas las
   parejas `(RawItemId, FieldKey, FieldValue)` que el ERP publica en
   esta corrida.
2. Un solo `MERGE` con `USING #StagingExtras AS S` y la misma cláusula
   `WHEN MATCHED AND T.Source <> 'MANUAL'`.
3. Para los borrados (sección 4): un `DELETE` con join contra una tabla
   temporal de claves vivas, restringido a `Source = 'ERP'`.

## 7. Idempotencia y reintentos

El `MERGE` con clave (CodigoEmpresa, RawItemId, FieldKey) es idempotente:
ejecutarlo dos veces con los mismos datos deja la fila igual. El conector
puede reintentar sin riesgo de duplicar.

## 8. Migración desde las taules antiguas (futuro)

Cuando se haga el PR de retirada de `FS_PL_Raw_OF_Extra` /
`Raw_Comanda_Extra` / `Raw_Projecte_Extra`:

```sql
-- Ejemplo OF: el RawOFId antiguo se mapea al RawItemId del Nivel=1 con
-- TipoOrigen='OF ' que coincide en clave ERP.
INSERT INTO FS_PL_RawItem_Extra
    (CodigoEmpresa, RawItemId, FieldKey, FieldValue, Source, UpdatedBy, UpdatedAt)
SELECT
    e.CodigoEmpresa,
    ri.RawItemId,
    e.FieldKey,
    e.FieldValue,
    'ERP',
    NULL,
    SYSUTCDATETIME()
FROM FS_PL_Raw_OF_Extra e
INNER JOIN FS_PL_Raw_OF o
        ON o.CodigoEmpresa = e.CodigoEmpresa AND o.RawOFId = e.RawOFId
INNER JOIN FS_PL_Raw_Item ri
        ON ri.CodigoEmpresa = o.CodigoEmpresa
       AND ri.Nivel         = 1
       AND ri.TipoOrigen    = 'OF '
       AND ri.ClaveERP      = o.ClaveERP
WHERE NOT EXISTS (
    SELECT 1 FROM FS_PL_RawItem_Extra t
     WHERE t.CodigoEmpresa = e.CodigoEmpresa
       AND t.RawItemId     = ri.RawItemId
       AND t.FieldKey      = e.FieldKey);
```

Mismo patrón para Comanda y Projecte. Después `DROP TABLE` de las tres
antiguas.

## 9. Checklist para el implementador del conector

- [ ] Leer catálogo `FS_PL_Cfg_GridColumns` (`IsCustomField=1 AND Activo=1`)
      para saber qué `FieldKey` × `AppliesToNivel` × `SourceEntity` debe
      publicar.
- [ ] Resolver `RawItemId` del nivel correcto para cada fila origen.
- [ ] `MERGE` con cláusula `WHEN MATCHED AND T.Source <> 'MANUAL'`.
- [ ] `DELETE WHERE Source='ERP'` para los `(RawItemId, FieldKey)` que ya
      no vienen.
- [ ] `UpdatedBy = '<NombreConector>'`.
- [ ] No tocar nunca filas con `Source='MANUAL'`.
- [ ] No tocar tampoco `FS_PL_NodeData_Extra` desde el conector ERP: esa
      es para overrides del NodeInspector y por defecto su Source es
      `MANUAL`.
