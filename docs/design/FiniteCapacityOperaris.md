# Planificador de capacidad finita por OPERARIO

Documento de diseño previo a la implementación de la unit `uFiniteCapacityOperaris`
(form independiente, NO sustituye a `uFiniteCapacityPlanner`).

## 1. Objetivo

Form de asignación de OTs / operaciones a operarios con capacidad finita,
basado en el patrón de cards + drag & drop de `uFiniteCapacityPlanner`,
pero con metáfora "una columna = un operario" y soporte multi-operario por OT.

Prioridad: **simplicidad para el usuario de planta**.

## 2. Decisiones de modelo (cerradas)

### 2.1 Modelo de duración con paralelismo (Escenario C - PRO)

Aplicar el modelo que usan Asprova / PlanetTogether / Ortems: la duración
efectiva de una operación depende de cuántos operarios se le asignen, con
rendimientos decrecientes.

Dos campos nuevos por **operación tipo** (no por instancia/nodo). Como el
proyecto NO tiene aún tabla de operación tipo (la operación es un string
en `FS_PL_NodeData.Operacion` y en `FS_PL_OperatorSkill.Operacion`), se
crea tabla nueva `FS_PL_OperationType`:

```sql
CREATE TABLE FS_PL_OperationType (
    CodigoEmpresa         SMALLINT      NOT NULL,
    Operacion             NVARCHAR(100) NOT NULL,
    MaxOperariosParalelos INT           NOT NULL DEFAULT 1,
    FactorParalelismo     DECIMAL(5,4)  NOT NULL DEFAULT 1.0,
    Descripcion           NVARCHAR(500) NULL,
    CONSTRAINT PK_FS_PL_OperationType PRIMARY KEY (CodigoEmpresa, Operacion)
);
```

- `MaxOperariosParalelos`: nº máximo de operarios que pueden trabajar en
  paralelo (1 = no paralelizable; ej. soldadura crítica).
- `FactorParalelismo`: factor de eficacia entre 0 y 1 al añadir operarios
  adicionales (1.0 = escalado perfecto; 0.7 = rendimiento decreciente
  realista; 0 = ningún beneficio).

Si una operación no tiene fila en `FS_PL_OperationType`, se asume
`MaxOperariosParalelos=1, FactorParalelismo=1.0` (comportamiento actual).

Fórmula de duración efectiva:

```
DuracionEfectiva = HorasHombreBase / EficaciaParalelismo(NOperariosAsignados)

EficaciaParalelismo(N) =
    si N <= 1: 1
    si N >= MaxOperariosParalelos: 1 + (MaxOperariosParalelos-1) * Factor
    en otro caso: 1 + (N-1) * Factor
```

**Consecuencia para la UI**: este form NO solo asigna operarios; al cambiar
el nº de operarios asignados, la duración del nodo cambia y el Gantt se
replanifica. Hay que comunicarlo claramente:

- Badge sobre la card del estilo `−40% duración` cuando añadir un operario
  acorta el bloque.
- Avisar al soltar la card si la replanificación arrastra dependencias
  fuera de la fecha de entrega.

### 2.2 Definición de "ocupación %"

```
Ocupación% = HorasAsignadas(rango) / HorasDisponibles(rango) * 100
```

- **HorasAsignadas**: suma de `FS_PL_OperatorAssignment.Horas` para todos los
  nodos del operario que solapan con el rango temporal visible.
- **HorasDisponibles**: capacidad neta del calendario del operario en el
  rango (calculada vía `FS_PL_Calendar` + `FS_PL_CalendarDayRule` +
  `FS_PL_CalendarException`), descontando ausencias (ver 2.4).
- **Rango**: combo en la cabecera con opciones:
  - Hoy
  - Esta semana (default)
  - Próximas 2 semanas
  - Este mes

Puede superar el 100 % (sobrecarga visible).

**Código de colores:**
- 0–70 % verde (subocupado)
- 70–95 % verde-amarillo (óptimo)
- 95–110 % naranja (lleno)
- > 110 % rojo + badge con horas absolutas en exceso (`+18 h`)

### 2.3 Consumo de capacidad por operario asignado (Manera B)

Cada operario asignado a una OT consume la **duración entera del bloque**,
no una fracción. Físicamente está comprometido durante todo el rango horario
del nodo, aunque haya más operarios trabajando en paralelo.

Ejemplo:
- OT-42: 15 h-hombre base, 3 operarios asignados, Factor=0.8
- Eficacia = 1 + (3-1)·0,8 = 2,6
- Duración efectiva = 15 / 2,6 ≈ 5,77 h
- **Cada uno de los 3 operarios consume 5,77 h de su capacidad** (no 5,77/3).

Motivo: contar fracciones daría la falsa lectura de capacidad libre cuando
en realidad el operario está bloqueado físicamente todo el bloque.

### 2.4 Ausencias del operario (decisión confirmada: SE CREA AHORA)

Tabla nueva:

```sql
CREATE TABLE FS_PL_OperatorAbsence (
    CodigoEmpresa   SMALLINT      NOT NULL,
    AbsenceId       INT IDENTITY(1,1) NOT NULL,
    OperatorId      INT           NOT NULL,
    FechaInicio     DATETIME2     NOT NULL,
    FechaFin        DATETIME2     NOT NULL,
    Tipo            TINYINT       NOT NULL DEFAULT 0,
        -- 0=Vacaciones, 1=Baja, 2=Formación, 3=Permiso, 4=Otros
    Descripcion     NVARCHAR(200) NULL,
    CONSTRAINT PK_FS_PL_OperatorAbsence PRIMARY KEY (CodigoEmpresa, AbsenceId),
    CONSTRAINT FK_FS_PL_OpAbs_Op FOREIGN KEY (CodigoEmpresa, OperatorId)
        REFERENCES FS_PL_Operator(CodigoEmpresa, OperatorId) ON DELETE CASCADE
);
```

UX en el form:

- En la columna del operario, las ausencias se pintan como **bloques grises
  diagonales** sobre el rango temporal afectado, con icono según `Tipo`.
- Las horas de ausencia se RESTAN de `HorasDisponibles` en el cálculo de
  ocupación %.
- Al intentar arrastrar una card sobre un bloque de ausencia → drop bloqueado
  con tooltip "Operario ausente: vacaciones del 12/05 al 19/05".

### 2.5 Detección de solapamientos (decisión confirmada: SÍ)

Si un operario tiene dos asignaciones cuyos intervalos `[FechaInicio,
FechaFin]` del nodo se solapan en el tiempo, el form lo detecta y avisa:

- **Vora roja** sobre las cards solapadas en la columna del operario.
- **Icono ⚠** sobre la cabecera del operario con tooltip "2 solapamientos".
- Click sobre el icono → popup que lista las parejas de OTs en conflicto.

El check es barato: ordenar asignaciones del operario por `FechaInicio` y
comparar `FechaFin[i]` con `FechaInicio[i+1]`.

**Importante**: el solapamiento puede ser legítimo (operario que supervisa
varias máquinas a la vez). Por eso se avisa pero NO se bloquea — el
usuario decide si lo acepta.

### 2.6 Nivel de capacitación (decisión confirmada: SE AÑADE)

Modificar `FS_PL_OperatorSkill` añadiendo `Nivel`:

```sql
ALTER TABLE FS_PL_OperatorSkill
    ADD Nivel TINYINT NOT NULL DEFAULT 2;
        -- 0=Aprendiz, 1=Junior, 2=Senior (default), 3=Experto
ALTER TABLE FS_PL_OperatorSkill
    ADD FactorEficiencia DECIMAL(5,4) NOT NULL DEFAULT 1.0;
        -- 1.3 = aprendiz tarda más; 0.85 = experto va más rápido
```

UX en el form (v1: visual, sin afectar duración aún):

- Pequeño badge de nivel sobre la cabecera del operario (A/J/S/E con color).
- En el filtro de capacitación, se puede acotar por nivel mínimo.

UX en el form (v2 / posterior):

- Cuando se asigne operario, multiplicar la duración efectiva por
  `FactorEficiencia` (un junior tarda 1.3× lo standard).
- Esto requiere acuerdo de modelo: ¿cómo se combina con el factor de
  paralelismo? Propuesta: efficacia total = sum(1/FactorEficiencia_i)
  para los N asignados, en lugar de N en la fórmula del 2.1. Pendiente
  de validar.

**Para v1 solo se persiste el campo y se muestra visualmente**, no se
aplica al cálculo de duración hasta que se valide la fórmula combinada.

### 2.7 Bloqueo de asignación (decisión confirmada: SE AÑADE)

Modificar `FS_PL_OperatorAssignment`:

```sql
ALTER TABLE FS_PL_OperatorAssignment
    ADD IsLocked BIT NOT NULL DEFAULT 0;
ALTER TABLE FS_PL_OperatorAssignment
    ADD LockedBy NVARCHAR(100) NULL;
ALTER TABLE FS_PL_OperatorAssignment
    ADD LockedAt DATETIME2 NULL;
```

UX:

- Click derecho sobre card asignada → "Bloquear / Desbloquear asignación".
- Cards bloqueadas se pintan con **icono cadenado 🔒** y borde más grueso.
- Acciones que las ignoran: `Equilibrar con...`, autoload, drag accidental.
  Para mover una card bloqueada, primero hay que desbloquearla.
- `Ctrl+Z` no deshace asignaciones bloqueadas.

## 3. Aprovechamiento de entidades existentes

El proyecto ya tiene un modelo rico que NO se debe duplicar:

### 3.1 ÁREAS (`FS_PL_Area`)

Las Areas agrupan Centros de trabajo (`FS_PL_Center.AreaId`). En este form
los operarios NO están directamente vinculados a Áreas, pero sí
**indirectamente** vía sus Skills + Centros donde se ejecutan operaciones
de esa Área.

**Uso en el form:**
- Filtro adicional en panel pendientes: "Mostrar solo OTs de Área = X".
- En la cabecera del operario, mostrar sus Áreas implícitas (las que cubre
  con sus skills) como mini-tags.

### 3.2 DEPARTAMENTOS (`FS_PL_Department` + `FS_PL_OperatorDepartment`)

Un operario puede pertenecer a varios departamentos (M-N). Útil para
agrupación organizativa, no para capacidad.

**Uso en el form:**
- Combo "Ordenar operarios por: Nombre / Ocupación % / **Departamento**".
- Filtro: "Mostrar solo operarios del Departamento X".
- Si se ordena por Departamento, agrupar visualmente columnas con
  separador y cabecera de grupo.

### 3.3 CALENDARIOS (`FS_PL_Calendar` + `CalendarDayRule` + `CalendarException`)

Cada operario tiene `CalendarId` propio (`FS_PL_Operator.CalendarId`).
**Es la fuente de verdad de HorasDisponibles.**

**Uso en el form:**
- Pintar de fondo en la columna del operario las franjas no laborables
  según su calendario (gris claro con patrón).
- Las excepciones de calendario (festivos, días especiales) también se
  pintan, con tooltip mostrando la descripción.
- El cálculo de capacidad debe llamar a la lógica existente de
  `uCentreCalendar` / `uCalendarsRepo` para obtener minutos efectivos en
  un rango.

### 3.4 TURNOS (`FS_PL_Shift` + `ShiftProfile` + `ShiftProfileSlot`)

Turnos definen franjas horarias de trabajo (mañana/tarde/noche). Hoy
están vinculados a centros, no directamente a operarios. **Hay decisión
arquitectónica pendiente** (ver 5.1): ¿el operario tiene también un
`ShiftProfileId` propio?

**Uso provisional en el form (sin modificar modelo):**
- Heredar el turno del centro de la operación que tiene asignada el
  operario en cada momento.
- Pintar las franjas de turno como fondos de color suave en la columna
  del operario (cabecera del día indica turno activo).

**Uso futuro (si se decide vincular operario a turno):**
- Validar al asignar: la operación cae dentro del turno del operario o
  fuera (con aviso).

### 3.5 CAPACITACIONES (`FS_PL_OperatorSkill`)

Ya cubierto en 2.6 (con la adición de `Nivel`).

## 4. Plantejamiento de UI

### 4.1 Estructura de tres zonas

```
┌──────────────┬───────────────────────────────────────────────┐
│  PENDIENTES  │  Joan G.[S]  María L.[E]  Pere F.[J]  Anna P. │
│              │  ┌────────┐  ┌────────┐   ┌────────┐  ┌──────┐│
│  [card OT1]  │  │ OT-42  │  │ OT-42  │   │ OT-42🔒│  │░░░░░░││
│  [card OT2]  │  │ 1/3 ⚓ │  │ 2/3 ⚓ │   │ 3/3 ⚓ │  │ AUSEN││
│  [card OT3]  │  └────────┘  └────────┘   └────────┘  │░░░░░░││
│  ⚠ filtro    │  cap. 75%    cap. 60%     cap. 90%    └──────┘│
│  por Área    │              ⚠ solap.                 cap. 0% │
└──────────────┴───────────────────────────────────────────────┘
```

- Panel izquierdo: lista de OTs / operaciones pendientes (cards arrastrables).
- Panel derecho: una columna por operario, con scroll horizontal.
- Cabecera de cada columna: nombre + badge nivel global (S/E/J/A) + barra
  de ocupación % sobre el rango seleccionado + icono ⚠ si hay
  solapamientos.
- Bloques de ausencia pintados como diagonales grises.
- Cards bloqueadas con cadenado 🔒.

### 4.2 Multi-operario: una card lógica replicada visualmente

Cuando una OT requiere `OperariosNecesarios > 1`:

- Al arrastrar la card sobre un operario, se asigna y aparece badge `1/3`
  rojo (faltan 2).
- El resto de columnas se ilumina con un halo suave (drop targets
  sugeridos).
- El usuario sigue arrastrando **la misma card** desde pendientes (mientras
  esté incompleta) o con Ctrl+drag desde una columna asignada para añadir
  operarios.
- Cuando llega a `3/3` el badge pasa a verde y el halo desaparece.
- **Una card lógica = una unidad de undo**.
- **Si el modelo C provoca que añadir el N-ésimo operario reduzca la
  duración del nodo**, se muestra badge `−40% duración` momentáneo y se
  replanifica el Gantt al confirmar.

A nivel de datos: una fila por (`OperatorId`, `NodeId`) en
`FS_PL_OperatorAssignment`, pero el renderer pinta tantas representaciones
de la card como filas existan para ese `NodeId`.

### 4.3 Capacitación como feedback visual durante el drag

Mientras se arrastra una card:
- Operarios **no capacitados** para esa operación → opacidad 50 % (dim).
- Operarios **capacitados** → resaltados, con badge de nivel visible.
- Drop sobre operario dim → diálogo de confirmación
  "¿Asignar igualmente? (no capacitado)".

### 4.4 Preview de impacto al arrastrar

Mientras se arrastra sobre un operario:
- Su barra de ocupación % muestra en color más claro el tramo que se
  añadiría si se soltase aquí.
- Si superara el 100 %, la barra se tinta de rojo en preview.

Aprovechar `uPlanningPreview`.

### 4.5 Filtros del panel pendientes

Combos / checks en cabecera del panel pendientes:
- **Operación** (combo): mostrar solo OTs que requieren operación X.
- **Área** (combo): solo OTs cuya operación tiene centros del Área X
  (vía `FS_PL_Center.AreaId`).
- **Departamento** (combo, opcional): solo OTs cuya operación es cubierta
  por algún operario del Dept X.
- **Solo capacitados** (check global): solo mostrar OTs que algún operario
  visible puede hacer.

### 4.6 Cabecera de columnas (operarios) — controles

- **Ordenar por**: combo Nombre / Ocupación % / Departamento / Nivel.
- **Mostrar**: combo Todos / Solo activos / Solo en Departamento X.
- **Rango temporal**: combo Hoy / Esta semana / Próximas 2 semanas / Mes.

### 4.7 Acciones contextuales sobre operario (click derecho)

- Bloquear / desbloquear todas las asignaciones de hoy / esta semana.
- "Equilibrar con...": mueve cards al operario menos cargado del mismo
  Departamento hasta igualar Ocupación %, respetando capacitación,
  ausencias y locks.
- "Ver agenda detallada": abre vista timeline horaria del operario
  (fase 2).

### 4.8 Simplificaciones deliberadas respecto a `uFiniteCapacityPlanner`

Para mantener el form simple, se RENUNCIA a:

- Separadores por día dentro de la columna (no aportan valor en RRHH).
- Reordenación de columnas por drag (sustituido por combo de orden).
- Multi-selección Ctrl+click de cards pendientes.
- Múltiples modos de sort, range planning extenso, autoload heurístico
  complejo.

Solo se mantiene: cards + drag con feedback + capacitación + contador X/N
+ barra de ocupación + filtros mínimos + ausencias + locks + nivel.

## 5. Componentes técnicos previstos

Reutilizar nomenclatura del patrón existente:

- `TfrmFiniteCapacityOperaris` (form principal).
- `TPendingOpsListControl` (panel izquierdo).
- `TOperariColumnsControl` (panel derecho, columnas de operarios).
- Acciones undo/redo: `TFCOActionKind` con
  `akAssign / akUnassign / akMove / akAutoLoad / akClearAll / akLock /
  akUnlock`.
- Datos: reutilizar `TOperariosRepo`, `TNodeDataRepo`, `TCardLayout`,
  `TCalendarsRepo` (ya existente).
- Repos nuevos: `TOperatorAbsencesRepo`, `TOperationTypesRepo`.

## 6. Cuestiones arquitectónicas pendientes

### 6.1 Operario y Turnos

Hoy `FS_PL_Operator` solo tiene `CalendarId`, no `ShiftProfileId`. Decidir:
- (A) Operario hereda turno del centro donde trabaja en cada momento
  (sin cambios en modelo). **Simple, suficiente para v1**.
- (B) Operario tiene `ShiftProfileId` propio (cambio de modelo).
  **Más rígido pero más correcto para fábricas con asignación fija de
  turnos a personas**.

**Decisión recomendada para v1: opción A.** Si un cliente lo pide, se
añade `ShiftProfileId` en v1.1 sin romper nada.

### 6.2 Replanificación del Gantt al cambiar nº de operarios

Cuando el modelo C dispara cambio de duración del nodo:

- ¿Se replanifica inmediatamente al soltar la card? Sí, recomendable.
- ¿Se permite undo de la replanificación? Sí, vía snapshot de `FechaFin`
  previa por nodo afectado.
- ¿Cómo se notifica al Gantt principal abierto en otra pestaña? Vía
  evento global del `TNodeDataRepo` (ya existe pattern observador).

### 6.3 Almacenamiento de `OperationType` precargada

Al implementar la primera versión, `FS_PL_OperationType` puede empezar
**vacía** y los valores por defecto (`MaxOperariosParalelos=1, Factor=1`)
aplican implícitamente. Form de gestión de tipos de operación = fase
posterior.

## 7. Plan de migraciones SQL

Nueva migración `V0xx__finite_capacity_operaris.sql`:

```sql
-- 1. Operation types con paralelismo
CREATE TABLE FS_PL_OperationType (...);

-- 2. Ausencias
CREATE TABLE FS_PL_OperatorAbsence (...);

-- 3. Nivel y eficiencia en skills
ALTER TABLE FS_PL_OperatorSkill ADD Nivel TINYINT NOT NULL DEFAULT 2;
ALTER TABLE FS_PL_OperatorSkill ADD FactorEficiencia DECIMAL(5,4) NOT NULL DEFAULT 1.0;

-- 4. Lock en asignaciones
ALTER TABLE FS_PL_OperatorAssignment ADD IsLocked BIT NOT NULL DEFAULT 0;
ALTER TABLE FS_PL_OperatorAssignment ADD LockedBy NVARCHAR(100) NULL;
ALTER TABLE FS_PL_OperatorAssignment ADD LockedAt DATETIME2 NULL;
```

## 8. Resumen de decisiones cerradas

| # | Tema | Decisión |
|---|------|----------|
| 1 | Modelo paralelismo | Escenario C (PRO): `MaxOperariosParalelos` + `FactorParalelismo` por operación |
| 2 | Capacidad % | ocupada/disponible sobre rango configurable |
| 3 | Consumo por operario | Manera B: cada operario consume duración entera del bloque |
| 4 | Ausencias | Tabla `FS_PL_OperatorAbsence` creada en v1 |
| 5 | Solapamientos | Detectados y avisados (no bloqueados) |
| 6 | Nivel skill | `Nivel` + `FactorEficiencia` añadidos en v1 (visual; cálculo en v1.1) |
| 7 | Lock | `IsLocked` añadido en v1 |
| 8 | Áreas | Filtro auxiliar en panel pendientes |
| 9 | Departamentos | Ordenación + filtro de operarios |
| 10 | Calendarios | Fuente de HorasDisponibles, pintados de fondo |
| 11 | Turnos | v1: heredados del centro (sin modelo nuevo) |
