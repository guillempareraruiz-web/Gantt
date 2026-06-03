# FS Planner — Plan: poblar campos custom desde el ERP (mapeo Sage → FieldKey)

**Fecha:** 2026-06-02
**Estado:** diseño, pendiente de aprobación.
**Relacionado:** [[project_gantt_custom_fields_storage]], V023 (FS_PL_RawItem_Extra), V042 (sync Raw_Item), V049 (vistas backlog OT/OP).

---

## 1. Objetivo

Que un campo personalizado del Backlog se pueda **rellenar automáticamente desde Sage200** durante la sincronización, además de la edición manual que ya existe. El valor manual del usuario (`Source='MANUAL'`) nunca se pisa.

## 2. Decisión de origen (clave) — REVISADA 2026-06-02

**Quién configura:** SIEMPRE el integrador (nosotros, conocedores del ERP), por
cliente/proyecto. El cliente final no toca esto. La puerta debe quedar **lo más
abierta posible** sin recompilar para cada cliente.

**Cómo:** el mapeo guarda, por FieldKey, una **expresión SQL libre** contra Sage
(texto, en BD) y, opcionalmente, **JOINs adicionales** que esa expresión
necesite. El reader las inyecta en el SELECT del backlog. Así, añadir un campo
nuevo para un cliente es solo configurar filas en BD, sin tocar código.

NO hay catálogo fijo en código (se descarta la idea anterior): sería rígido y
obligaría a recompilar. La flexibilidad vive en datos (BD), no en código.

> Riesgo asumido: es SQL que escribe el integrador. La UI de mapeo queda
> restringida a perfil admin/integrador. Se valida (SELECT de prueba) antes de
> guardar.

## 3. Estado actual (verificado 2026-06-02)

- `FS_PL_RawItem_Extra` (V023) tiene el campo `Source` ('ERP'/'MANUAL') pero **solo se escribe desde uBacklog.pas** (manual). La vía ERP nunca se cableó.
- La cadena de sync: `IErpReader.ReadBacklogOF → TArray<TRawItemErp>` (campos FIJOS) → `uErpSyncRepo.ApplyRawItems` → `UpsertRawItemRow` hace INSERT/UPDATE en `FS_PL_Raw_Item`. Aquí enganchamos la escritura de `_Extra`.
- `TRawItemErp` (uErpTypes) tiene campos fijos, sin contenedor de extras.

## 4. Arquitectura propuesta

### 4.1 Storage del mapeo (nueva tabla)

```sql
CREATE TABLE FS_PL_Cfg_ErpFieldMap (
    CodigoEmpresa  SMALLINT      NOT NULL,
    GridId         VARCHAR(50)   NOT NULL,   -- 'BACKLOG' (extensible a otras entidades)
    FieldKey       VARCHAR(64)   NOT NULL,   -- = FieldKey de FS_PL_Cfg_GridColumns
    ErpSource      VARCHAR(30)   NOT NULL,   -- sistema ERP, p.ej. 'SAGE200'
    SqlExpression  NVARCHAR(500) NOT NULL,   -- EXPRESION SQL libre: 'of.CampoLibre1', 'LTRIM(c.Obs)'...
    SqlJoins       NVARCHAR(MAX) NULL,       -- JOINs extra que la expresion necesite (texto)
    AppliesToNivel TINYINT       NULL,       -- nivel al que aplica (1/2/3); coherente con la columna
    Activo         BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Cfg_ErpFieldMap PRIMARY KEY (CodigoEmpresa, GridId, FieldKey)
);
```

Un FieldKey mapea a UNA expresión SQL (+ JOINs opcionales). Sin fila → ese campo
custom solo es manual.

Ejemplos de filas (las pone el integrador):
- `'Color'`   → SqlExpression `of.CampoLibre1`, SqlJoins NULL
- `'Lote'`    → SqlExpression `l.NumeroLote`,  SqlJoins `LEFT JOIN LotesFab l ON l.IdOF = of.IdOF`
- `'Acabado'` → SqlExpression `art.Acabado`,   SqlJoins `LEFT JOIN Articulos art ON art.Codigo = of.CodigoArticulo`

### 4.2 (eliminado) — sin catálogo en código

La idea de un catálogo fijo de campos Sage en código se descarta: rígido y
obliga a recompilar. La fuente de verdad del mapeo vive en BD (4.1).

### 4.3 TRawItemErp += contenedor de extras

```pascal
TErpExtraValue = record
  FieldCode: string;   // ErpFieldCode catalogado
  Value: Variant;
end;
// en TRawItemErp:
ExtraFields: TArray<TErpExtraValue>;
```

`uSage200Reader.ReadBacklogOF`, al inicio, lee de `FS_PL_Cfg_ErpFieldMap` las
filas activas y construye el SELECT inyectando cada `SqlExpression AS [Ext_<FieldKey>]`
y concatenando los `SqlJoins` (deduplicados). Luego rellena `ExtraFields` leyendo
esas columnas `Ext_*`. Cada FieldKey lleva su `FieldCode` = el propio FieldKey
para el mapeo de vuelta.

### 4.4 Sync: escribir _Extra con Source='ERP'

En `UpsertRawItemRow`, tras obtener el `RawItemId` (en INSERT vía SCOPE_IDENTITY; en UPDATE ya se tiene), por cada `ExtraField` mapeado a un FieldKey:

```sql
MERGE FS_PL_RawItem_Extra AS T
USING (SELECT :Emp, :RawId, :FieldKey, :Val) AS S (...)
ON (T.CodigoEmpresa=S.Emp AND T.RawItemId=S.RawId AND T.FieldKey=S.FieldKey)
WHEN MATCHED AND T.Source <> 'MANUAL' THEN
     UPDATE SET FieldValue=S.Val, Source='ERP', UpdatedAt=SYSUTCDATETIME()
WHEN NOT MATCHED THEN
     INSERT (...) VALUES (..., 'ERP', ...);
```

La clave: `WHEN MATCHED AND T.Source <> 'MANUAL'` → respeta overrides manuales.

### 4.5 UI de mapeo (perfil integrador)

Form nuevo `uErpFieldMapping`:
- Tabla: una fila por columna custom del Backlog (FieldKey + Caption) | Expresión SQL | JOINs | activo.
- Campos de texto para `SqlExpression` y `SqlJoins` (los rellena el integrador).
- Botón **"Probar"**: ejecuta un SELECT TOP 5 con la expresión + joins contra Sage y muestra el resultado o el error, ANTES de guardar.
- Persiste en FS_PL_Cfg_ErpFieldMap.

Acceso: desde el manager de columnas (botón "Mapeo ERP...") o menú. Restringido a perfil admin/integrador.

## 5. Ficheros

**SQL (migraciones nuevas):**
- V050: tabla `FS_PL_Cfg_ErpFieldMap`.

**Delphi crear:**
- `uErpFieldMapRepo.pas` — CRUD de FS_PL_Cfg_ErpFieldMap + tipo TErpFieldMap.
- `uErpFieldMapping.pas` + `.dfm` — UI de mapeo (con "Probar").

**Delphi tocar:**
- `uErpTypes.pas` — `TErpExtraValue` + `ExtraFields` en `TRawItemErp`.
- `uSage200Reader.pas` — ReadBacklogOF: leer mapping, inyectar SqlExpression+SqlJoins, rellenar ExtraFields.
- `uErpSyncRepo.pas` — UpsertRawItemRow: escribir `_Extra` (MERGE Source='ERP') tras resolver RawItemId.
- Acceso a la UI desde el manager de columnas.
- `.dproj`, ayuda MD.

## 6. Fases

| F | Contenido | Verificable |
|---|---|---|
| F1 | V050 tabla mapping + `uErpFieldMapRepo` (CRUD) | alta/lectura por código |
| F2 | UI `uErpFieldMapping` con "Probar" | Mapear "Color"→`of.CampoLibre1` y probar SELECT |
| F3 | `TRawItemErp.ExtraFields` + lectura dinámica en uSage200Reader | El reader trae el valor de Sage |
| F4 | Escritura `_Extra` Source='ERP' en sync (MERGE respeta MANUAL) | Sync rellena la columna; el override manual sobrevive |

## 7. Riesgos / notas

- **Respetar MANUAL**: el MERGE debe llevar `WHEN MATCHED AND T.Source <> 'MANUAL'`. Es el punto crítico.
- **RawItemId en INSERT**: hay que recuperarlo (SCOPE_IDENTITY) para escribir los extras del item nuevo.
- **Catálogo Sage**: hay que listar qué columnas concretas de qué tablas Sage se exponen (requiere saber el esquema Sage real de OF/líneas).
- **Nivel**: igual que las columnas custom, el extra ERP aplica a un Nivel (OF/OT/OP). El reader debe escribir el valor en el RawItem del nivel correcto.
- Es independiente de la migración JSON→BD de campos de nodos (otro tema).
