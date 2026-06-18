# PLAN STOCK / MRP — Análisis Gap y Roadmap realista

Cruce entre el plan propuesto (docs/mrp.docx) y lo que YA existe en FS Planner.
Fecha: 2026-06-17. Decisión estratégica del usuario: **el diferencial es el puente
Stock↔Gantt (APS+MRP)**, no rehacer un MRP clásico.

---

## 1. Tesis (opinión honesta)

El documento mrp.docx es una buena brújula del destino, pero sobredimensiona lo que
falta. Leyéndolo parece que hay que construir un MRP desde cero compitiendo con Asprova.
La realidad del código:

- **La Fase 1 del roadmap del docx (motor de stock proyectado) YA ESTÁ HECHA** y limpia:
  `uStockProjection.pas` (`TStockProjector`).
- **Gran parte de la Fase 2 (alertas/dashboard) YA ESTÁ HECHA**: `uStockCockpit.pas`
  (5 tabs + gráficos), `uArticleDetail.pas` (9 tabs), `uDashboardOperativo.pas`.
- El connector `IErpReader` ya expone casi toda la materia prima del MRP.

**El verdadero diferencial competitivo NO es el motor de stock** — eso lo tienen Sage,
Odoo, NetSuite. Es que FS Planner **ya tiene el APS de capacidad finita al lado** (Gantt,
calendarios, lotes, undo, alertas). Asprova/PlanetTogether son caros y complejos
precisamente porque unen MRP + APS. Tenemos las dos mitades; falta **cerrar el lazo**:

> Una ruptura de componente debe poder proponer/crear una OF en el Gantt de capacidad
> finita; y mover una OF en el Gantt debe recalcular el stock proyectado. Ese lazo
> cerrado MRP↔APS es lo que NO tiene Odoo ni Sage, y lo que justifica el precio de Asprova.

---

## 2. Mapa: qué hay, qué falta

### YA HECHO (no rehacer)

| Pieza | Estado | Fichero |
|---|---|---|
| Motor stock proyectado (entradas/salidas/saldo/bajo mínimo/resumen) | ✅ | uStockProjection.pas |
| Stock Cockpit: Crítico, Rupturas, Obsoleto, Cobertura, ABC + gráficos | ✅ | uStockCockpit.pas |
| **Ficha artículo (DETALLE DE ARTÍCULO) — pieza madura**: tabs ATP (usa TStockProjector), Partidas, Movimientos futuros (filtros compras/ventas/OFs + fechas), Histórico (PaintBox), OFs, Proveedores, Clientes, Dónde se usa, Disponibilidad | ✅ | uArticleDetail.pas |
| Dashboard operativo (KPIs + tops) | ✅ | uDashboardOperativo.pas |
| Lectura stock actual / disponible (AcumuladoStock) | ✅ | IErpReader.ReadStockArticulo/ReadStockDisponible |
| Entradas futuras (compras), Salidas (ventas), Movs OF (prod+consumo) | ✅ | IErpReader.ReadEntradasFuturas / ReadSalidasFuturasVenta / ReadMovimientosOFsPendientes |
| Crítico / Obsoleto / Cobertura / ABC / Rupturas futuras (agregados) | ✅ | IErpReader.ReadStock*/ReadCobertura/ReadAnalisisABC/ReadRupturasFuturas |
| BOM (componentes) + where-used | ✅ | IErpReader.ReadFormulaComponentes / ReadDondeSeUsa |
| Proveedores por artículo, histórico mensual | ✅ | IErpReader.ReadProveedoresArticulo / ReadHistoricoMensual |

### A MEDIAS / a consolidar

- **No hay una "sección PLAN STOCK" coherente**: Stock Cockpit, Article Detail y
  Dashboard cuelgan sueltos del menú. Falta navegación/entrada única de módulo.
- **Time-Phased Stock View visual** (tabla día a día con ruptura/recuperación marcada +
  drill-down a documento): el motor lo permite (`MovimientosOrdenados`/`StockEnFecha`),
  pero falta la pantalla dedicada tal como la dibuja el docx (§3).
- Pendientes ya anotados: heatmap familia×mes, "reservado por quién".

### NO EXISTE (lo que de verdad falta)

| Falta | Prioridad para el diferencial |
|---|---|
| **Puente Stock→Gantt**: desde una ruptura/recomendación, crear/avanzar una OF como nodo en el plan | ⭐ CLAVE |
| **Puente Gantt→Stock**: al mover/replanificar una OF, recalcular stock proyectado del artículo y sus componentes | ⭐ CLAVE |
| **Recomendaciones MRP** (comprar/fabricar X, fecha límite, lead time, lote/múltiplo) | Alta |
| Parámetros MRP propios (stock seg., punto pedido, lead time, lote mín., múltiplo) si el ERP no los da fiables | Alta |
| Pegging (demanda↔suministro) | Media |
| MPS por periodos (rejilla semana/mes editable) | Media |
| Forecast (incluso simple: media 30/90/año anterior) | Media |
| What-if / escenarios guardables | Baja (potente pero posterior) |
| BOM multinivel en la proyección (explosión de necesidades dependientes) | Media-alta |
| Guardar ejecuciones del plan (PlanRun*) para comparar plan vs plan / plan vs realidad | Media |

---

## 3. Roadmap recomendado (reordenado hacia el diferencial)

NO seguir el roadmap del docx fase a fase. Orden propuesto:

**F0 — Empaquetar lo que hay (rápido, venible ya).**
Sección "PLAN STOCK" con navegación propia que agrupe Cockpit + Article Detail +
Dashboard. El **Detalle de Artículo ya es la "ficha de planificación de artículo"** que
pide el docx (tab ATP + Movimientos futuros + OFs + Dónde se usa); NO rehacerla. Lo único
que falta encima de ella es el **Time-Phased Stock View visual** (tabla día a día con
ruptura/recuperación marcada en color), que se añade como tab nuevo o como mejora del tab
ATP reutilizando `TStockProjector.MovimientosOrdenados`.

> El Detalle de Artículo es además el **anclaje natural del diferencial**: el botón
> "Planificar / Fabricar → crear OF en el Gantt" (F2) vive aquí, junto al tab OFs y al
> ATP, donde el planificador ya está mirando la ruptura.

**F1 — Recomendaciones MRP simples.**
De "hay ruptura" a "haz esto": cantidad a comprar/fabricar, fecha límite de lanzamiento
(fecha necesidad − lead time), lote mínimo/múltiplo. Pantalla tipo workbench.
Requiere decidir de dónde salen los parámetros MRP (ERP vs tabla propia FS_PL_*).

**F2 — ⭐ Puente Stock→Gantt (EL DIFERENCIAL).**
Desde una recomendación de "fabricar", crear un nodo/OF en el Gantt de capacidad finita.
**Decisión de arquitectura (2026-06-17): se hace VÍA BACKLOG**, no creando el nodo
directamente. La recomendación inserta una entrada de carga pendiente (familia OF) en
FS_PL_Raw_Item, y el usuario la planifica con el flujo Backlog→Gantt ya validado. Reaprovecha
toda la canalización existente; menos código y menos riesgo que crear FS_PL_Node/NodeData a mano.

Estado F2: el botón "Fabricar → Gantt" YA existe en el tab ATP del Detalle de Artículo
(uArticleDetail) y muestra la propuesta (artículo/cantidad/fechas) con un ShowMessage.
PENDIENTE: que en vez del mensaje inserte un Raw_Item manual de familia OF bien formado
(jerarquía OF→OT→OP, campos que espera el Backlog, centro vía Oper_Formula.CentroTrabajo).
Es el siguiente entregable; requiere su propio turno por la complejidad del Raw_Item manual.

**F3 — ⭐ Puente Gantt→Stock.**
Al mover/replanificar una OF en el Gantt, recalcular el stock proyectado afectado
(producto y componentes). Idealmente incremental. Aquí el lazo queda cerrado.

**F4 — Pegging + BOM multinivel.**
Explicar el porqué del plan y explotar necesidades dependientes.

**F5 — MPS + Forecast simple.**
Rejilla por periodos con forecast media móvil / mismo periodo año anterior.

**F6 — What-if + PlanRun (escenarios y comparativa plan vs realidad).**

---

## 4. Decisiones a cerrar antes de programar F1+

1. **Parámetros MRP**: ¿vienen fiables de Sage (stock seguridad, lead time, lote, punto
   pedido) o creamos tabla propia FS_PL_MrpParam por artículo/familia con override?
2. **Granularidad**: artículo+almacén para empezar (lo que ya usa la proyección);
   ¿añadir variante/lote/partida? El reader ya tiene partidas en Article Detail.
3. **Qué es "stock disponible"**: ya hay ReadStockDisponible; fijar la definición única
   (físico vs disponible vs reservado vs ATP) y usarla en todo el módulo.
4. **Horizonte** de cálculo por defecto (30/90/180 días) y configurable.
5. **El MRP en F1 es informativo**; solo crea nodos en el Gantt en F2; escribir en el ERP
   (OF/pedido reales) sería una fase muy posterior y opcional.

---

## 4.bis. Pendiente técnico detectado (Time-Phased View)

- **Movimientos vencidos (fecha < hoy) con unidades pendientes.** `ReadMovimientosOFsPendientes`
  (y las lecturas de compras/ventas) filtran por `FechaHasta` pero NO por `FechaDesde`=hoy.
  Con datos reales al día, las OFs/pedidos atrasados (fecha pasada, aún pendientes)
  aparecen ANTES de hoy y ensucian la proyección. Tratamiento MRP estándar: acumular todo
  lo vencido-pendiente como stock inicial a fecha de hoy, y proyectar solo de hoy en
  adelante. **Implementar en F1**, junto con los parámetros MRP.
- NOTA entorno de pruebas: la BD Sage de dev tiene fechas de 2024; al proyectar a 2026 todo
  queda "en el pasado". Para validar visualmente, poner la fecha de proyección en 2024. No
  se modifica la BD.

## 5. Riesgos heredados del docx que aplican aquí

- Calidad de fechas del ERP (fechas malas → falsas rupturas). El proyector ya prioriza
  FechaNecesaria→Recepcion→Pedido en compras y FechaServicio→Necesaria→Pedido en ventas.
- Lead times irreales: si se hacen recomendaciones, guardar lead time real medio, no solo
  el teórico.
- Stock reservado mal clasificado.
- Rendimiento: el cálculo masivo (Cockpit) ya va por agregados en el reader; el puente
  Gantt→Stock debe ser incremental, no recalcular todo el plan en cada drag.

---

## 6. Resumen de una línea

No construimos un MRP — ya tenemos su motor. Construimos **el puente entre el stock
proyectado (MRP) y la planificación de capacidad finita (APS/Gantt)**, que es lo que nos
diferencia de Sage/Odoo y nos pone en la liga de Asprova a una fracción del coste.
