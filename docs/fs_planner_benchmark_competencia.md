# FS Planner v2 — Situació competitiva vs. mercat APS

**Data:** 2026-07-26
**Abast:** anàlisi interna. Prioritza saber on som per sobre de com quedem.
**Versió navegable:** [fs_planner_benchmark_competencia.html](fs_planner_benchmark_competencia.html)

**Mètode:** les capacitats d'FS Planner s'han verificat contra el **codi font**, no contra
la documentació interna (dos documents d'auto-anàlisi del repo estaven desactualitzats:
deien que `IPlanningEngine` no existia i avui sí). Les dades dels competidors provenen de
webs i comunicats oficials consultats el 26/07/2026.

**Dimensió del producte:** 236 units Delphi, ~179.000 línies, 82 migracions SQL.

---

## Conclusió en una frase

Tenim **la capa visual i el model de dades d'un APS de gamma alta, i el motor d'un
planificador de gamma mitjana**. La distància amb Preactor o Asprova no és d'amplitud
funcional — en tenim més que molts — sinó d'**una sola propietat del motor**: les
precedències de ruta.

El competidor real d'avui, però, no és cap dels cinc d'aquest document: és el **full de
càlcul**. El guió de demo comercial ho diu explícitament ("cliente sale de Excel/papel,
sin competencia"), i contra aquest rival guanyem en totes les dimensions.

---

## Veredicte per blocs

| Bloc | Nota | Lectura |
|---|---|---|
| Interfície i visualització | **8,4** | Gantt propi de 15.000 línies, 7 modes de fila, undo de 200 passos. Competitiu amb qualsevol |
| Model de dades | **7,8** | Utillatges, operaris amb polivalència, calendaris, setup per atributs, multi-empresa nadiu |
| Motor de planificació | **5,2** | FCS real amb 7 regles i metaheurística, però sense precedències dures |
| Plataforma i escala | **2,5** | Desktop Windows, monousuari de facto, un sol ERP i només lectura |

Les puntuacions són **judici informat sobre l'evidència, no metodologia formal**. Serveixen
per ordenar prioritats internament; no s'haurien de fer servir com a argument comercial.

---

## Els competidors

Dada rellevant: **tres dels cinc han canviat de propietari**. Els independents que queden
són essencialment Asprova i Frepple.

| Producte | Propietari | Desplegament | Preu públic | Segment |
|---|---|---|---|---|
| Siemens Opcenter APS (ex-Preactor) | Siemens (2013) | On-prem + SaaS (Opcenter X) | No publicat | Enterprise |
| DELMIA Ortems | Dassault Systèmes (2016) | On-prem, híbrid, SaaS | No publicat | Mitjana-gran |
| CAI PlanetTogether (ex-Galaxy APS) | CAI Software (**24/06/2026**) | Principalment on-prem | No publicat | Mid-market a gran |
| Asprova APS | Independent, Tòquio (1994) | **Desktop Windows** | ~300 $/usuari/mes* | Mitjana-gran, feble a Europa |
| Microsoft Project | Microsoft | Web + desktop | 10–55 $/usuari/mes | Projectes, no fabricació |
| **FS Planner v2** | FactoryStart | Desktop Windows | — | PIME industrial |

\* Xifra d'agregador tercer, no verificada. **Només Microsoft publica preus oficials.**

---

## Matriu funcional

Llegenda: ✅ implementat · 🟡 parcial · ❌ no existeix · — no documentat públicament

### Motor de planificació

| Capacitat | FS Planner | Opcenter | Ortems | PlanetTog. | Asprova | MS Project |
|---|---|---|---|---|---|---|
| Capacitat finita | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Precedències de ruta com a restricció dura** | ❌ *(només alerta D01)* | ✅ | ✅ | ✅ | ✅ | ✅ CPM |
| Regles de despatx | ✅ 7 canòniques | ✅ | ✅ | ✅ | ✅ | ❌ |
| Optimització metaheurística | ✅ SA multi-start | ✅ Genètics, MCTS | 🟡 "IA" | — | ✅ Solver S8 v3 | ❌ |
| Selecció de recurs alternatiu | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Granularitat | 🟡 Centre | ✅ Màquina | ✅ Màquina | ✅ Màquina | ✅ Màquina | — |
| Backward scheduling | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| DBR / Kanban-pull / CONWIP | ❌ *(enums declarats)* | — | 🟡 | — | — | ❌ |

### Restriccions i model

| Capacitat | FS Planner | Opcenter | Ortems | PlanetTog. | Asprova | MS Project |
|---|---|---|---|---|---|---|
| Utillatges amb capacitat pròpia | ✅ *dura, cross-centre, vida útil* | ✅ | ✅ | ❌ | 🟡 | ❌ |
| Operaris amb polivalència i absències | ✅ *mòdul dedicat* | ✅ | ✅ | 🟡 crews | 🟡 màquina-cèntric | 🟡 |
| Habilitats com a restricció del motor | ❌ *(alerta O04)* | ✅ | ✅ | 🟡 | — | ❌ |
| Materials com a restricció | ❌ *(alertes M01-M03)* | ✅ | ✅ SRP | ✅ | ✅ | ❌ |
| Setup seqüència-dependent | 🟡 per atributs | ✅ matriu | ✅ | ✅ | ✅ | ❌ |
| Calendaris, torns, festius | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

### Plataforma i integració

| Capacitat | FS Planner | Opcenter | Ortems | PlanetTog. | Asprova | MS Project |
|---|---|---|---|---|---|---|
| Multiusuari concurrent | ❌ *últim que desa guanya* | ✅ | ✅ | ✅ | ✅ | ✅ |
| Web / API REST | ❌ | ✅ | ✅ | 🟡 | ❌ | ✅ |
| Integració ERP | 🟡 Sage 200 | ✅ | ✅ VIC | ✅ SAP, Dynamics… | — | ❌ |
| Write-back a l'ERP | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Escenaris what-if | 🟡 sense A/B | ✅ | ✅ | ✅ | ✅ | 🟡 |
| **Projectes CPM dins el producte** | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ referent |
| Stock projectat / MRP | 🟡 sense BOM multinivell | ✅ | ✅ SRP | ✅ | ✅ | ❌ |
| Multi-idioma | ❌ | ✅ | ✅ | ✅ | ✅ 7 idiomes | ✅ |
| Multi-empresa nadiu | ✅ | — | — | — | — | ❌ |

---

## Puntuació per eix

Contra la mitjana dels quatre APS. MS Project queda fora: no competeix al mateix terreny.

| Eix | Nota |
|---|---|
| Gantt i interacció | 9,2 |
| Recursos secundaris (utillatges, operaris) | 8,5 |
| Gestió de projectes (CPM, línia base) | 8,4 |
| Model de dades i calendaris | 8,2 |
| Alertes i diagnòstic (31 regles) | 8,0 |
| Regles de despatx | 7,8 |
| Optimització | 6,5 |
| Setup i canvis de sèrie | 6,2 |
| Materials i MRP | 5,5 |
| Integració ERP | 5,0 |
| **Restriccions del motor** | **3,5** |
| **Concurrència multiusuari** | **2,0** |
| **Plataforma** | **2,0** |

---

## Les quatre bretxes que compten

### 1. Les precedències de ruta no són una restricció del motor — BLOQUEJANT

`RunAutoScheduling` (`uBacklogScheduler.pas:255`) col·loca cada operació independentment
al seu centre segons calendari i capacitat. Amb una OF d'operacions OP1→OP2→OP3, **res no
garanteix que OP2 comenci després d'acabar OP1**: la coherència depèn de l'ordre de la cua
(heurístic), de l'alerta posterior D01 (`uGanttAlertas.pas:230`) i de l'operador.

`TSchedInput` (`uBacklogScheduler.pas:51-95`) **no té cap camp de predecessor**.

Als quatre APS comparats això és una restricció dura. És l'única diferència *estructural*
del motor, i arrossega una conseqüència: **l'optimitzador SA cerca permutacions d'una cua
sense precedències**, així que no és un solver JSSP/RCPSP sinó una cerca sobre l'ordre de
despatx.

*Surt a la primera demo tècnica amb una OF multi-operació.*

### 2. No hi ha concurrència multiusuari — BLOQUEJANT PER A EMPRESA MITJANA

Cap lock ni versionat sobre nodes o pla: sense `rowversion` a `FS_PL_Node`, sense
`sp_getapplock`, sense comprovació de versió en desar. **Dos planificadors sobre el mateix
projecte: l'últim que desa guanya, en silenci.**

Hi ha login, rols i auditoria — multiusuari en sentit administratiu, no de concurrència
segura.

### 3. Sense selecció de recurs alternatiu ni granularitat de màquina

El motor sempre usa `CentroPreferente`; si no n'hi ha, la fila queda sense planificar. No
hi ha grups de recursos elegibles amb tria per càrrega, eficiència o cost — **tot i que
l'esquema ja té `FS_PL_NodeCenterAllowed`**. I es planifica a centre, no a màquina: el
mestre de màquines existeix però `uBacklogScheduler` no el menciona ni una vegada.

### 4. Un sol ERP, només lectura, i sense web — SOSTRE COMERCIAL

Sage 200 és l'únic connector implementat (`uErpReaderFactory.pas:40-46`; SAP B1 i Dynamics
365 BC són **línies comentades**). El sistema **no escriu mai a l'ERP**. Sumat a l'absència
de web, API i multi-idioma, marca el sostre de creixement més que cap limitació del motor.

---

## On guanyem de debò

Dues d'aquestes **cap dels quatre APS les porta a dins**.

- **Gantt interactiu propi** — 15.000 línies, 7 modes de fila, undo de 200 passos amb línia
  de temps navegable, compactació i backward per OF/OT. Anys-persona d'actiu real.
- **Utillatges com a recurs de primer nivell** — capacitat pròpia, restricció dura
  cross-centre, exemplars intercanviables, vida útil i manteniment. Només Ortems i Opcenter
  ho documenten; PlanetTogether i Asprova, no.
- **Capacitat finita per operari** — polivalència amb nivells, absències, paral·lelisme
  configurable. Asprova és màquina-cèntric i això li costa.
- **Projectes CPM dins l'APS** — 4 tipus d'enllaç amb lag, 8 restriccions de data, 11 línies
  base, tríada d'esforç, detecció de sobreassignació. Cap APS ho porta; MS Project sí, però
  no sap de fabricació.
- **Setup per atributs personalitzats** — regles additives sobre camps propis del client, no
  una matriu tancada. Més fàcil de configurar, encara que no expressi asimetries.
- **Arquitectura multi-ERP neta** — ~50 lectures amb tipus neutres, mapeig configurable i
  sincronització amb detecció de conflictes per hash. El segon connector serà molt més
  barat que el primer.

---

## Ordre recomanat

Cada pas fa el següent més barat; els dos primers canvien la resposta a un plec de condicions.

1. **Precedències dures al motor** — afegir predecessors a `TSchedInput` i respectar-los a
   la col·locació. Converteix D01 en restricció i el SA en un optimitzador de debò.
   *Impacte molt alt · toca el nucli del motor.*

2. **Selecció de recurs alternatiu** — fer servir `FS_PL_NodeCenterAllowed`, que ja existeix,
   per triar entre centres elegibles. Desbloqueja la planificació a nivell de màquina.
   *Impacte alt · l'esquema ja hi és.*

3. **Concurrència** — `rowversion` a `FS_PL_Node` i comprovació en desar, o check-out de pla.
   *Impacte alt · condició per a empresa mitjana.*

4. **Write-back a l'ERP** — un `IErpWriter` mínim: confirmar dates planificades sobre l'OF de
   Sage. Converteix el planificador en part del procés, no en una eina de consulta.
   *Impacte mitjà-alt · risc controlat si és mínim.*

5. **Deute tècnic** — zero tests automatitzats en 179.000 línies. Dos bugs coneguts anotats
   al codi: l'optimitzador SA viola utillatges (`uPlanOptimizer.pas:296-298`, no thread-safe)
   i els moviments vençuts embruten la projecció MRP.
   *Impacte intern · creix amb cada funcionalitat nova.*

---

## Notes de mètode

- Quan una capacitat del competidor no està documentada públicament es marca com a **no
  disponible**, no com a absent: pot existir sense estar publicada.
- Cap dels quatre APS publica preus oficials ni quota de mercat. L'única referència
  d'analista independent trobada és l'**IDC MarketScape APS 2025**, on Siemens i Dassault
  figuren tots dos com a Leaders.
- **Consolidació del mercat**: Preactor→Siemens (2013), Ortems→Dassault (2016),
  PlanetTogether→CAI Software (24/06/2026). És un argument comercial: el mercat d'APS
  independent s'està buidant.
- **L'stack no és un anacronisme**: Asprova, amb desenvolupament actiu (v18.1, maig 2026) i
  quota històrica dominant al Japó, segueix sent client Windows d'escriptori.

### Fonts

- Siemens Opcenter APS — <https://www.siemens.com/en-us/technology/preactor-aps/>
- IDC MarketScape via Siemens (24/11/2025) — <https://blogs.sw.siemens.com/opcenter/siemens-recognized-as-a-leader-in-aps-idc-marketscape-spotlight-on-opcenter-advanced-planning-scheduling/>
- DELMIA Ortems — <https://www.3ds.com/products/delmia/supply-chain-planning-optimization/advanced-planning-scheduling>
- Mòduls Ortems (partner Andea) — <https://www.andea.com/delmia-software/delmia-ortems-advanced-planning-and-scheduling-software/>
- Adquisició PlanetTogether (24/06/2026) — <https://www.prnewswire.com/news-releases/cai-software-acquires-planettogether-strengthening-advanced-planning-and-scheduling-capabilities-across-manufacturing-302809997.html>
- Asprova — <https://www.asprova.com/en/asprova.html>
- Microsoft Project preus — <https://www.microsoft.com/en-us/microsoft-365/project/microsoft-project-enterprise-plans-and-pricing>
- MS Project resource leveling — <https://support.microsoft.com/en-us/project/distribute-project-work-evenly-level-resource-assignments>

---

**Relacionat:** [fs_planner_metodes_analisi.md](fs_planner_metodes_analisi.md) (cobertura vs.
mètodes de planificació, maig 2026) · [PlanStock_MRP_AnalisisGap.md](PlanStock_MRP_AnalisisGap.md)
