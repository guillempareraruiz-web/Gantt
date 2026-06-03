# FS Planner — Plan de implementación: Motor de Reglas de Prioridad (PRO)

**Fecha:** 2026-06-02
**Autor:** diseño asistido (pendiente de revisión por Guillem)
**Relacionado:** [fs_planner_metodes_analisi.md](fs_planner_metodes_analisi.md) — cierra la **Fase 1** del roadmap (reglas EDD/SPT/CR/Slack como entidades discretas) y prepara terreno para Fase 2 (bottleneck).

---

## 1. Objetivo

Añadir un **tercer motor de planificación** bajo el menú **Vistas**, hermano de Forward/Backward, que **ordena la cola de operaciones aplicando reglas de prioridad industriales** y luego apila con el FCS existente. No es un algoritmo nuevo de apilado: es el `RunAutoScheduling` actual con un **ordenador de cola enchufable y potente** delante.

**Versión PRO** (decisión del usuario, 2026-06-02): catálogo completo de reglas, desempate multinivel, **overrides por centro**, dirección forward/backward, y **preview con KPIs** para comparar reglas antes de aplicar.

---

## 2. Qué hay hoy (punto de partida)

| Pieza | Estado | Fichero |
|---|---|---|
| `IPlanningEngine` + factory | ✅ Forward/Backward implementados; 5 kinds declarados sin impl | [uPlanningEngine.pas](../uPlanningEngine.pas), [uPlanningEngineTypes.pas](../uPlanningEngineTypes.pas) |
| Motores FCS | ✅ Envuelven `RunAutoScheduling` | [uPlanningEngineFCS.pas](../uPlanningEngineFCS.pas) |
| Ordenación de cola | 🟡 Existe `SortInputs`, pero solo 2 criterios: `soFechaCompromiso`, `soPrioridad` | [uBacklogScheduler.pas:169](../uBacklogScheduler.pas#L169) |
| Tipo de orden | 🟡 `TSchedOrder = (soFechaCompromiso, soPrioridad)` | [uBacklogScheduler.pas:44](../uBacklogScheduler.pas#L44) |
| Pipeline params→preview→commit | ✅ Probado en backlog | [uBacklog.pas:630](../uBacklog.pas#L630) |
| Datos disponibles en `TSchedInput` | ✅ `FechaCompromiso`, `HorasEstimadas`, `Prioridad`, `FechaEntrega`, `FechaNecesaria`, `CentroPreferente`… | [uBacklogScheduler.pas:46](../uBacklogScheduler.pas#L46) |

**Conclusión:** el 80% de la tubería ya existe. El trabajo es (a) enriquecer el catálogo de reglas, (b) un motor que las orqueste, (c) la UI de selección, (d) el preview de KPIs.

---

## 3. Catálogo de reglas (versión PRO)

Cada regla es un comparador determinista sobre datos ya presentes en `TSchedInput`. Todas se calculan respecto a `FechaBase` del plan.

| Regla | Frase para el cliente | Cálculo / clave de orden |
|---|---|---|
| **EDD** (Earliest Due Date) | "Primero lo que vence antes" | `FechaCompromiso` ↑ |
| **SPT** (Shortest Processing Time) | "Primero las tareas cortas" | `HorasEstimadas` ↑ |
| **LPT** (Longest Processing Time) | "Primero las largas" | `HorasEstimadas` ↓ |
| **FIFO** | "Por orden de llegada" | proxy: `NumeroOF`/`RawId` ↑ |
| **Critical Ratio** | "El más apurado de margen" | `(FechaCompromiso − FechaBase) / HorasRestantes` ↑ |
| **Slack** (holgura) | "Menos margen primero" | `(FechaCompromiso − FechaBase) − HorasRestantes` ↑ |
| **Prioridad ERP** | "Respeta la prioridad del ERP" | `Prioridad` ↓ (la actual `soPrioridad`) |

> **Critical Ratio < 1** = ya va con retraso garantizado → siempre arriba. **Slack negativo** = sin holgura. Ambas usan `HorasEstimadas` como proxy de trabajo restante (no hay aún campo "horas ya hechas" en el input; si se quiere afinar, es una mejora posterior — anotado en §9).

### Desempate multinivel

El usuario define hasta **3 niveles** de regla: principal → desempate 1 → desempate 2. Cuando el nivel N produce empate (dentro de tolerancia, p.ej. mismo día para fechas), se aplica el nivel N+1. Último recurso: `RawId` (estable, determinista).

---

## 4. Arquitectura propuesta

### 4.1 Nuevos tipos (en `uPlanningEngineTypes.pas`)

```pascal
TPriorityRule = (
  prEDD, prSPT, prLPT, prFIFO, prCriticalRatio, prSlack, prPrioridadErp
);

TPriorityRuleSet = record
  Principal: TPriorityRule;
  Desempate1: TPriorityRule;   // prFIFO por defecto
  Desempate2: TPriorityRule;   // prFIFO por defecto
end;

// Override por centro (PRO)
TCenterRuleOverride = record
  CentroCode: string;          // coincide con CentroPreferente del input
  Rules: TPriorityRuleSet;
end;

// Parámetros del motor de reglas (extiende, no rompe, TSchedParams)
TRuleEngineParams = record
  Base: TSchedParams;          // Mode (fwd/bwd) + FechaBase reutilizados
  Global: TPriorityRuleSet;
  Overrides: TArray<TCenterRuleOverride>;
end;
```

Se añade `pekRules` al enum `TPlanningEngineKind` (el slot `pekBottleneck` se reserva para Fase 2; **no** se reutiliza, para no confundir semántica).

### 4.2 Nueva unit `uPlanningEngineRules.pas`

```pascal
TPriorityRuleEngine = class(TInterfacedObject, IPlanningEngine)
  // GetKind -> pekRules; GetName/GetDescription
  // Schedule(AInputs, AParams): TSchedResult
end;
```

**Lógica de `Schedule`:**
1. Particiona `AInputs` por `CentroPreferente`.
2. Para cada centro: resuelve el `TPriorityRuleSet` efectivo (override del centro si existe, si no el global).
3. Ordena con un **comparador genérico** `CompareByRuleSet` (usa `IComparer<TSchedInput>` + `TArray.Sort`, sustituyendo el bubble sort de `SortInputs`).
4. Reensambla la cola global respetando el orden por centro.
5. Delega el apilado en `RunAutoScheduling(OrderedInputs, Base)` — **cero cambios en la lógica de capacidad/calendario**.

> Los `TRuleEngineParams` no caben en la firma `Schedule(AInputs, AParams: TSchedParams)`. Dos opciones (decisión §8): (A) el engine guarda los params de reglas como campo antes de llamar `Schedule`; (B) ampliar `TSchedParams` con un puntero/record opcional de reglas. **Recomendado: A** (el form construye el engine, le inyecta `RuleParams` por property, y luego llama `Schedule`) — no toca la interface ni los motores existentes.

### 4.3 Comparador (sustituye/extiende `SortInputs`)

`SortInputs` se generaliza a `SortInputsByRuleSet(var AInputs; const ARules; AFechaBase)`. El bubble sort actual se reemplaza por `TArray.Sort` con `IComparer` que encadena los 3 niveles. La versión vieja de 2 criterios queda cubierta como caso particular (compatibilidad con los consumidores actuales del backlog).

### 4.4 Factory

`CreatePlanningEngine` añade `pekRules: Result := TPriorityRuleEngine.Create;` en [uPlanningEngine.pas:59](../uPlanningEngine.pas#L59).

---

## 5. UI

### 5.1 Entrada de menú (Vistas)

Nuevo `TMenuItem` **`Planificacion por reglas`** en `Main.pas`, junto a Forward/Backward. Handler `PlanificacionReglas1Click` que:
1. Recolecta los nodos del plan activo (mismo patrón que `LaunchAutoPlanificacion`, [Main.pas:1797](../Main.pas#L1797)).
2. Los convierte a `TArray<TSchedInput>` (reusa el colector que ya alimenta `RunAutoScheduling`).
3. Abre el diálogo de reglas (§5.2).
4. Llama al engine, muestra preview de KPIs (§5.3), y al aceptar hace commit (reusa `CommitScheduling`/equivalente del backlog).

### 5.2 Diálogo de configuración `uReglasPlanParams.pas` (+ .dfm)

```
┌─ Planificación por reglas ──────────────────────────┐
│ Dirección:  (•) Forward   ( ) Backward              │
│ Fecha base: [02/06/2026 ▾]                          │
│                                                     │
│ Regla principal: [Critical Ratio ▼]                 │
│ Desempate 1:     [EDD ▼]                            │
│ Desempate 2:     [FIFO ▼]                           │
│                                                     │
│ ☑ Overrides por centro                              │
│   ┌─────────────────────────────────────────────┐  │
│   │ Centro        Regla principal     Desempate  │  │
│   │ TORNO 1       [SPT ▼]             [EDD ▼]     │  │
│   │ FRESA 2       [— global —]        [—]         │  │
│   └─────────────────────────────────────────────┘  │
│                                                     │
│            [ Previsualizar ]   [ Cancelar ]         │
└─────────────────────────────────────────────────────┘
```

- Combos de regla = `TPriorityRule` con captions en **castellano** (UI siempre castellano).
- Grid de overrides = `cxGrid` (norma del proyecto para grids CRUD), una fila por centro visible, columna combo. Vacío = usa global.
- Persistencia de la última config en `FS_PL_UserPreference` (JSON, save-on-change, nunca INI) — `ScreenKey='MotorReglas'`.

### 5.3 Preview con KPIs `uReglasPlanPreview.pas` (+ .dfm)

Tras `Schedule`, antes de commit, mostrar:

| KPI | Origen |
|---|---|
| Operaciones planificadas / no planificadas | `TSchedResult.TotalPlanificados / TotalNoPlanificados` |
| Saturadas / fuera de plazo | `TotalSaturados / TotalFueraPlazo` |
| **Nº de retrasos previstos** | contar outputs con `FechaFin > FechaCompromiso` |
| **Makespan** | `max(FechaFin) − min(FechaInicio)` |
| **Retraso total / medio (h)** | suma y media de retrasos |
| Tabla por centro | ocupación y nº ops |

Botones: **Aplicar** (`mrOk` → commit), **Cambiar reglas** (`mrRetry` → vuelve a §5.2), **Cancelar**.

> Diferencial PRO: como `Schedule` es barato, se puede ofrecer un botón **"Comparar reglas"** que ejecuta las N reglas principales y muestra una tabla comparativa de KPIs (retrasos, makespan) para que el cliente elija con datos. **Opcional en v1.1** (anotado §9).

---

## 6. Ficheros a crear / tocar

**Crear:**
- `uPlanningEngineRules.pas` — el motor.
- `uReglasPlanParams.pas` + `.dfm` — diálogo de config.
- `uReglasPlanPreview.pas` + `.dfm` — preview KPIs.
- `Help/es/MotorReglas.md` (+ copia a `Win32/Debug/Help/es` y `Win32/Release/Help/es`).

**Tocar:**
- `uPlanningEngineTypes.pas` — tipos nuevos + `pekRules` en el enum + `PlanningEngineKindToStr`.
- `uPlanningEngine.pas` — caso `pekRules` en la factory.
- `uBacklogScheduler.pas` — generalizar `SortInputs` → `SortInputsByRuleSet` (compatible hacia atrás).
- `Main.pas` + `Main.dfm` — `TMenuItem` nuevo + handler + ayuda contextual.
- `FSPlanner2026.dproj` — `DCCReference` de cada `.pas`/`.dfm` nuevo.

---

## 7. Plan por fases (entregable incremental)

| Fase | Contenido | Compila y prueba |
|---|---|---|
| **F1** | Tipos (`TPriorityRule`, `TPriorityRuleSet`, `pekRules`) + `SortInputsByRuleSet` con las 7 reglas + desempate. Sin UI. | Test interno: ordenar una cola conocida y verificar orden. |
| **F2** | `TPriorityRuleEngine` + factory. Invocable por código. | Llamar `Schedule` sobre el plan activo, sin overrides. |
| **F3** | Diálogo `uReglasPlanParams` (sin overrides aún) + entrada de menú + commit. | Flujo end-to-end con regla global. |
| **F4** | Preview de KPIs. | Comparar números antes/después. |
| **F5** | Overrides por centro (grid) + persistencia en `UserPreference`. | Regla distinta por cuello de botella. |
| **F6** | Ayuda contextual MD + (opcional) "Comparar reglas". | Cliente final. |

Cada fase compila sola (build lo hace el usuario en el IDE) y aporta valor visible.

---

## 8. Decisiones tomadas / asunciones

1. **Paso de la config de reglas:** property en el engine (`Global` + `SetOverrides`), sin tocar `IPlanningEngine.Schedule`. ✅ Implementado.
2. `pekRules` es un kind **nuevo**, no se recicla `pekBottleneck`. ✅
3. "Trabajo restante" para CR/Slack = `HorasEstimadas` (no hay horas-hechas en el input todavía). ✅
4. Todo el texto UI/captions en **castellano**; chat en catalán. ✅
5. **Solo previsualización en v1.0** (decisión del usuario, 2026-06-02): el motor se ejecuta sobre el plan activo y muestra orden propuesto + KPIs, pero **NO modifica el plan**. El commit (reescribir fechas de nodos) queda para una fase posterior una vez validado el orden.
6. Para evitar dependencia frágil de `TcxEditRepository`, la columna combo de overrides se configura por código (`colRegla.PropertiesClass := TcxComboBoxProperties`).
7. Preferencias del diálogo en `uUserPrefs` (mismo patrón que el backlog).

## 8.bis Estado de implementación (2026-06-02)

| Fase | Estado | Ficheros |
|---|---|---|
| F1 Tipos + `SortInputsByRuleSet` (7 reglas + desempate) | ✅ | `uBacklogScheduler.pas` |
| F2 `TPriorityRuleEngine` + factory + `pekRules` | ✅ | `uPlanningEngineRules.pas`, `uPlanningEngine.pas`, `uPlanningEngineTypes.pas` |
| F3 Diálogo config + menú Vistas + recolección de nodos | ✅ | `uReglasPlanParams.pas/.dfm`, `Main.pas/.dfm` |
| F4 Preview KPIs (retrasos, makespan) | ✅ | `uReglasPlanPreview.pas/.dfm` |
| F5 Overrides por centro (grid combo) | ✅ | `uReglasPlanParams.pas/.dfm` |
| F6 Ayuda contextual MD | ✅ | `Help/es/uReglasPlanParams.md` (+ Debug/Release) |

Pendiente (fuera de v1.0): **commit real** (reescribir fechas de nodos), botón "Comparar reglas", trabajo-restante real para CR/Slack.

---

## 9. Mejoras futuras (fuera de v1.0)

- **"Comparar reglas"**: ejecutar todas las reglas y tabla comparativa de KPIs.
- **Trabajo restante real** (horas hechas) para CR/Slack más finos → requiere campo en `TSchedInput` desde el repo de nodos.
- **Bottleneck-based** (`pekBottleneck`, Fase 2 del roadmap) reutilizando este motor + detección de cuello.
- Regla compuesta ponderada (puente con `uPesosScoring` existente).

---

## 10. Riesgos

- **Confusión con la Dispatch List:** este motor *calcula y apila* (Vistas); la Lista de Prioridades sigue siendo *visor + ajuste manual*. Documentar la diferencia en la ayuda.
- **`SortInputs` tiene consumidores actuales** (backlog): la generalización debe mantener el comportamiento de los 2 criterios viejos. Cubrir con el caso particular.
- **Datos faltantes** (`FechaCompromiso = 0`): tratar como "sin fecha" → al final de la cola (ya lo hace el SortInputs actual; replicar).
