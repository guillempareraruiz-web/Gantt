# FS Planner v2 — Situació competitiva vs. mercat APS

**Data:** 2026-07-26 · **Revisat:** 2026-07-28
**Abast:** anàlisi interna. Prioritza saber on som per sobre de com quedem.
**Versió navegable:** [fs_planner_benchmark_competencia.html](fs_planner_benchmark_competencia.html)

**Mètode:** les capacitats d'FS Planner s'han verificat contra el **codi font**, no contra
la documentació interna (dos documents d'auto-anàlisi del repo estaven desactualitzats:
deien que `IPlanningEngine` no existia i avui sí). Les dades dels competidors provenen de
webs i comunicats oficials consultats el 26/07/2026.

**Dimensió del producte:** 230 units Delphi, ~180.000 línies, 84 migracions SQL.

> **Revisió del 28/07/2026.** En dos dies s'han tancat tres de les bretxes que aquest
> informe donava per obertes: precedències de ruta, granularitat de màquina i el bug del
> SA amb utillatges. A més, el temps de canvi ja entra a la funció objectiu de
> l'optimitzador. Les notes del motor s'han revisat en conseqüència; **la plataforma no
> s'ha mogut**. Els canvis es marquen amb ✳ i el detall és a "Què ha canviat".

---

## Conclusió en una frase

Tenim **la capa visual i el model de dades d'un APS de gamma alta, i un motor que ja no
és el punt feble del producte**. Tancades les precedències dures i la granularitat de
màquina, la distància amb Preactor o Asprova ja no és de motor: és de **plataforma**
—concurrència, web i escriptura a l'ERP.

El competidor real d'avui, però, no és cap dels cinc d'aquest document: és el **full de
càlcul**. El guió de demo comercial ho diu explícitament ("cliente sale de Excel/papel,
sin competencia"), i contra aquest rival guanyem en totes les dimensions.

---

## Veredicte per blocs

| Bloc | Nota (26/07) | Nota (28/07) | Lectura |
|---|---|---|---|
| Interfície i visualització | 8,4 | **8,4** | Gantt propi de 15.000 línies, 7 modes de fila, undo de 200 passos. Competitiu amb qualsevol |
| Model de dades | 7,8 | **7,8** | Utillatges, operaris amb polivalència, calendaris, setup per atributs, multi-empresa nadiu |
| Motor de planificació | 5,2 | **7,0** ✳ | Precedències dures, planificació a màquina i setup dins l'objectiu del SA. Queda el recurs alternatiu |
| Plataforma i escala | 2,5 | **2,5** | Desktop Windows, monousuari de facto, un sol ERP i només lectura. **Sense canvis** |

Les puntuacions són **judici informat sobre l'evidència, no metodologia formal**. Serveixen
per ordenar prioritats internament; no s'haurien de fer servir com a argument comercial.

---

## Què ha canviat des del 26/07 (verificat contra el codi)

| Bretxa | Estat | Evidència |
|---|---|---|
| Precedències de ruta com a restricció dura | ✅ **tancada** | `TSchedInput.PredecesorasRawIds` + `MinInicioPorPrecedencia` a `uBacklogScheduler` |
| Granularitat de màquina | ✅ **tancada** | V083: el motor planifica a màquina; `BuildMaquinasCache` i `MaquinaId` al resultat |
| El SA violava utillatges | ✅ **tancada** | `TOptContext.UtillajeBase` + `Clone` per avaluació a `uPlanOptimizer` |
| Setup dins de la funció objectiu | ✅ **nova capacitat** | `PesoSetup` (0,25) i `SetupTotalMin` als KPI: el SA **minimitza** els canvis i en dona l'estalvi |
| Selecció de recurs alternatiu | ⏳ pendent | `FS_PL_NodeCenterAllowed` es llegeix als repos, **però el motor no la consulta** |
| Concurrència multiusuari | ⏳ pendent | Cap `rowversion` ni `sp_getapplock` a les 84 migracions |
| Write-back a l'ERP | ⏳ pendent | No existeix cap `IErpWriter` |

**Fora del benchmark original però rellevant comercialment:** venda per mòduls de
llicència (V084, nucli + 7 mòduls). No puja cap nota tècnica, però permet entrar a un
client petit sense regalar-li tot el producte.

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
| **Precedències de ruta com a restricció dura** | ✅ ✳ | ✅ | ✅ | ✅ | ✅ | ✅ CPM |
| Regles de despatx | ✅ 7 canòniques | ✅ | ✅ | ✅ | ✅ | ❌ |
| Optimització metaheurística | ✅ SA multi-start | ✅ Genètics, MCTS | 🟡 "IA" | — | ✅ Solver S8 v3 | ❌ |
| Selecció de recurs alternatiu | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Granularitat | ✅ Màquina ✳ | ✅ Màquina | ✅ Màquina | ✅ Màquina | ✅ Màquina | — |
| Backward scheduling | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| DBR / Kanban-pull / CONWIP | ❌ *(enums declarats)* | — | 🟡 | — | — | ❌ |

### Restriccions i model

| Capacitat | FS Planner | Opcenter | Ortems | PlanetTog. | Asprova | MS Project |
|---|---|---|---|---|---|---|
| Utillatges amb capacitat pròpia | ✅ *dura, cross-centre, vida útil* | ✅ | ✅ | ❌ | 🟡 | ❌ |
| Operaris amb polivalència i absències | ✅ *mòdul dedicat* | ✅ | ✅ | 🟡 crews | 🟡 màquina-cèntric | 🟡 |
| Habilitats com a restricció del motor | ❌ *(alerta O04)* | ✅ | ✅ | 🟡 | — | ❌ |
| Materials com a restricció | ❌ *(alertes M01-M03)* | ✅ | ✅ SRP | ✅ | ✅ | ❌ |
| Setup seqüència-dependent | ✅ per atributs, **dins l'objectiu del SA** ✳ | ✅ matriu | ✅ | ✅ | ✅ | ❌ |
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

| Eix | 26/07 | 28/07 |
|---|---|---|
| Gantt i interacció | 9,2 | **9,2** |
| Gestió de projectes (CPM, línia base) | 8,4 | **8,8** ✳ *(nivelació de recursos)* |
| Recursos secundaris (utillatges, operaris) | 8,5 | **8,5** |
| Model de dades i calendaris | 8,2 | **8,2** |
| Alertes i diagnòstic (31 regles) | 8,0 | **8,0** |
| Setup i canvis de sèrie | 6,2 | **8,0** ✳ *(entra a l'objectiu del SA)* |
| Regles de despatx | 7,8 | **7,8** |
| Optimització | 6,5 | **7,5** ✳ *(respecta utillatges i minimitza setup)* |
| **Restriccions del motor** | **3,5** | **7,0** ✳ *(precedències dures + màquina)* |
| Materials i MRP | 5,5 | **5,5** |
| Integració ERP | 5,0 | **5,0** |
| **Concurrència multiusuari** | **2,0** | **2,0** |
| **Plataforma** | **2,0** | **2,0** |

---

## Les bretxes que compten

### ~~1. Les precedències de ruta no són una restricció del motor~~ — ✅ TANCADA (27/07)

*Era la bretxa bloquejant d'aquest informe.* `TSchedInput` ja porta
`PredecesorasRawIds` i el motor calcula `MinInicioPorPrecedencia`: amb una OF
OP1→OP2→OP3, OP2 **no pot** començar abans d'acabar OP1. Deixa de dependre de
l'ordre de la cua i de l'alerta posterior D01.

Conseqüència important: l'optimitzador SA ja **no** permuta una cua sense
precedències. Amb aquesta restricció i el cost de canvi a la funció objectiu, s'acosta
molt més a un solver de veritat que a una cerca sobre l'ordre de despatx.

**Trampa documentada:** encadenar per camp `Orden`, mai per posició d'array.

### 2. No hi ha concurrència multiusuari — BLOQUEJANT PER A EMPRESA MITJANA

Cap lock ni versionat sobre nodes o pla: sense `rowversion` a `FS_PL_Node`, sense
`sp_getapplock`, sense comprovació de versió en desar. **Dos planificadors sobre el mateix
projecte: l'últim que desa guanya, en silenci.**

Hi ha login, rols i auditoria — multiusuari en sentit administratiu, no de concurrència
segura.

### 3. Sense selecció de recurs alternatiu — PENDENT

*La meitat d'aquesta bretxa s'ha tancat:* amb **V083 el motor ja planifica a MÀQUINA**
(`BuildMaquinasCache`, `MaquinaId` al resultat, RowMode MAQUINAS), no només a centre.

El que queda és la **tria entre recursos elegibles**: el motor segueix usant sempre
`CentroPreferente` i, si no n'hi ha, la fila queda sense planificar. No hi ha grups de
recursos amb selecció per càrrega, eficiència o cost.

`FS_PL_NodeCenterAllowed` **existeix a l'esquema i es llegeix als repos**
(`uNodesRepo`, `uSQLServerConnector`), però **el motor no la consulta mai**. És la
bretxa de motor amb millor relació impacte/cost que queda oberta: la dada ja hi és.

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
- **Projectes CPM dins l'APS** — 4 tipus d'enllaç amb lag, 8 restriccions de data, línia
  base, tríada d'esforç, detecció de sobreassignació i **nivelació automàtica de recursos**
  ✳. Cap APS ho porta; MS Project sí, però no sap de fabricació.
- **Setup per atributs personalitzats, i optimitzat** ✳ — regles additives sobre camps
  propis del client en lloc d'una matriu tancada, i **el temps de canvi entra a la funció
  objectiu de l'optimitzador**: el motor no només agrupa, cerca l'ordre que el minimitza i
  informa de l'estalvi. Segueix sense expressar asimetries (negre→blanc ≠ blanc→negre).
- **Venda per mòduls** ✳ — nucli més 7 mòduls activables per llicència. Permet entrar a un
  client petit sense regalar-li el producte sencer i ampliar sense reinstal·lar.
- **Arquitectura multi-ERP neta** — ~50 lectures amb tipus neutres, mapeig configurable i
  sincronització amb detecció de conflictes per hash. El segon connector serà molt més
  barat que el primer.

---

## Ordre recomanat *(revisat 28/07)*

~~1. Precedències dures al motor~~ ✅ **fet 26/07**

**El centre de gravetat s'ha desplaçat del motor a la plataforma.** Els tres punts
següents ja no milloren el càlcul: decideixen si el producte pot vendre's a una
empresa de cert tamany.

1. **Concurrència** — `rowversion` a `FS_PL_Node` i comprovació en desar, o check-out de
   pla. Avui dos planificadors alhora perden feina en silenci.
   *Impacte alt · condició per a empresa mitjana. **La bretxa més cara que queda.***

2. **Write-back a l'ERP** — un `IErpWriter` mínim: confirmar dates planificades sobre l'OF
   de Sage. Converteix el planificador en part del procés, no en una eina de consulta.
   *Impacte mitjà-alt · risc controlat si és mínim.*

3. **Selecció de recurs alternatiu** — fer servir `FS_PL_NodeCenterAllowed`, que ja
   existeix i ja es llegeix, per triar entre centres i màquines elegibles.
   *Impacte mitjà-alt · **la dada ja hi és**, és la que menys costa de les tres.*

4. **Deute tècnic** — zero tests automatitzats en 180.000 línies. El bug del SA amb
   utillatges **ja està resolt** (còpia per avaluació); queden els moviments vençuts que
   embruten la projecció MRP.
   *Impacte intern · creix amb cada funcionalitat nova.*

> **Nota de risc.** En dos dies s'han tocat el motor de planificació, l'optimitzador i
> el Main, i **el projecte segueix sense cap test automatitzat**. Tot s'ha validat a mà.
> Com més ràpid avança el producte, més cara surt aquesta absència.

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
