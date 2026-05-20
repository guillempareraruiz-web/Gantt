# FS Planner — Anàlisi de cobertura vs. document `fs_planner_metodes.html`

**Data:** 2026-05-20
**Document analitzat:** [docs/fs_planner_metodes.html](fs_planner_metodes.html)
**Objectiu:** mesurar quant lluny estem de l'FS Planner "universal multi-mètode" que descriu el document.

---

## Resum executiu

Cobertura actual estimada: **~40–50%** del que el document planteja.
La part més difícil (model unificat, Gantt interactiu, FCS amb operaris/habilitats) ja està resolta. Forats clars: **push pur** (forward/backward explícits, bottleneck), **pull** (Kanban real, CONWIP), **DBR**, **optimització matemàtica**, i sobretot **arquitectura plug-in de motors**.

---

## Estat mètode per mètode

| # | Mètode | Estat | Evidència | Què falta |
|---|--------|-------|-----------|-----------|
| 02 | MRP / MRP II | ❌ No (correcte: feina de l'ERP) | — | Res; el doc el descarta com a motor propi |
| 03 | Capacitat Finita (FCS) | 🟡 Parcial avançat | `uFiniteCapacityPlanner.pas`, `uFiniteCapacityOperaris.pas`, `uPlanProdEngine.pas` | Modes **forward/backward explícits**, variant **bottleneck-based** |
| 04 | Regles de prioritat | 🟡 Esquelet | `uPlanningRules.pas`, `uPlanningRulesEditor.pas`, `uPesosScoring.pas`, `uDispatchList.pas` | Auditoria: implementar FIFO, **EDD, SPT, LPT, CR, Slack** com a regles seleccionables (no només scoring per pesos). Selector de regla per recurs / global |
| 05 | Gantt manual / interactiu | ✅ Fet (fortalesa) | `uGanttBuilder.pas`, `uGanttControlGrupo.pas`, `uNodeInspector.pas`, `uLinkEditor.pas`, `uGanttHistory.pas` | — |
| 06 | DBR (TOC) | ❌ No existeix | — | Detector de coll d'ampolla, buffer davant del DRUM, control de release (rope) |
| 07 | Kanban (pull lean) | 🟡 Confusió: tenim **board visual**, no **pull real** | `uKanbanBoard.pas`, `uVistaKanban.pas` (són Trello-style) | Kanban-pull amb targetes virtuals i **WIP limits per estació** |
| 08 | CONWIP | ❌ No existeix | — | Límit global de WIP per línia + llaç de control sortida→entrada |
| 09 | Optimització (CP-SAT/MILP/metaheurístiques) | ❌ No existeix | — | Wrapper OR-Tools CP-SAT (sidecar Python o DLL); modelat JSSP a partir del model SQL |
| 11 | Arquitectura plug-in | 🟡 Implícit, no formalitzat | Un sol motor acoblat (`uPlanProdEngine`) + `uBacklogScheduler` | Definir `IPlanningEngine` i refactoritzar darrere |

---

## Valor extra que tenim i el document **no** demana

- **FCS per operaris amb habilitats / polivalència / absències** — `uFiniteCapacityOperaris` + `uHabilidadRepo` + `uPesosScoring`. ASProva ho fa amb dificultat; nosaltres ho tenim com a motor dedicat.
- **Multi-ERP via connector** (`IErpReader`, model `Raw_Item`, staging) — diferencial fort.
- **Calendaris + torns + excepcions** integrats al motor.
- **Camps custom + grid customization persistit per usuari**.
- **Wizard d'instal·lació, gestió usuaris/rols/àrees/departaments** — capa empresarial.

---

## Roadmap del doc — què ens falta per fase

### Fase 1 — Model + Gantt + regles EDD/CR
Estat: **majoritàriament fet**.
- [ ] Auditar `uPlanningRules`: regles canòniques (FIFO/EDD/SPT/LPT/CR/Slack) com a entitats discretes, no només pesos.
- [ ] UI: selector de regla per recurs o global.

### Fase 2 — Capacitat finita forward/backward
Estat: **mig fet**.
- [ ] Mode **backward** explícit (des de data d'entrega cap enrere).
- [ ] Variant **bottleneck-based**.

### Fase 3 — DBR + Kanban-pull / CONWIP
Estat: **per fer**.
- [ ] DBR: detector coll d'ampolla + control de release.
- [ ] Kanban-pull real (targetes + WIP limits).
- [ ] CONWIP (límit WIP global).

### Fase 4 — Optimització
Estat: **per fer**.
- [ ] Wrapper OR-Tools CP-SAT (sidecar Python o DLL).
- [ ] Generador del problema JSSP a partir del model FS_PL_*.

---

## Forat arquitectònic crític (cal resoldre abans de Fase 3/4)

El document insisteix en **"motors intercanviables sobre un mateix model"**. Avui hi ha un sol motor acoblat. Abans d'afegir DBR/CONWIP/CP-SAT cal:

1. Definir interfície `IPlanningEngine`:
   - Input: pla + paràmetres + dataset Raw_Item/Operacions/Recursos/Calendaris/Dependències.
   - Output: assignacions normalitzades (operació → recurs → interval).
2. Refactoritzar `uPlanProdEngine` i `uBacklogScheduler` darrere d'aquesta interfície.
3. Selector de motor per pla (patró ja usat amb `uErpSelector` per ERP).

Sense això, cada mètode nou tornarà a tocar codi compartit.

---

## Camí més curt al valor de mercat

1. **Consolidar Fase 1+2** (EDD/CR explícits + backward) → ja competim amb el gruix d'ASProva en MTO.
2. **Refactoritzar a motors plug-in** (no visible al client, però desbloqueja la resta).
3. **DBR i CONWIP** — barats un cop tenim (2); obren mercat lean.
4. **CP-SAT** com a mòdul premium opcional — pot esperar.

---

## Punts d'atenció / riscos

- **No confondre Kanban-board (estat) amb Kanban-pull (mètode)**. El document és explícit i el comprador industrial els distingeix.
- El motor actual és greedy/rule-based; un client gran demanarà optimalitat → Fase 4 és comercial, no només tècnica.
- **FCS per operaris és el diferencial real** davant ASProva (que viu en món màquina-cèntric); cal preservar-lo en el refactor a `IPlanningEngine`.
