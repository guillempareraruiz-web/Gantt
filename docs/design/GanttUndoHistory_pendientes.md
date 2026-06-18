# Gantt - Historial de cambios (Undo/Redo + Timeline) - PENDIENTES

Estado del modulo de undo en memoria del Gantt y cosas a revisar.

## Que esta hecho

- **Undo/Redo en memoria** (sesion actual, se pierde al cerrar). Stack en `uGanttHistory.pas`
  (`TGanttHistoryManager`, max 200 entradas).
- **Timeline visual** (`uGanttHistoryTimeline.pas/.dfm`): se abre con el boton Deshacer.
  Lista con scroll, marcador de posicion actual, contador "Cambio N de M". Doble clic en
  un paso navega (undo/redo en cadena) hasta ese punto. Ctrl+Z / Ctrl+Y siguen haciendo
  undo/redo directo de un paso.
- **Acciones cubiertas** (mutan FNodes en memoria):
  - Mover / redimensionar nodo (drag) + reset duracion original.
  - Compactar OF, Compactar OT.
  - Planificar hacia atras OF / OT (Backward).
  - Desplazar a la izquierda (x3 variantes).
- **Snapshot ampliado**: `TNodePlanSnapshot` guarda StartTime/EndTime/Duration + CentreId + LoteId,
  para poder deshacer cambios de centro y de lote.
- **Envoltorio generico** `BeginUndoBatch/EndUndoBatch`: snapshot global antes/despues,
  registra el diff como UNA entrada. Bloquea los PushUndo internos durante el batch.

## Fuera del undo A PROPOSITO

- **Lotes (agrupar/desagrupar) y edicion via NodeInspector / Ver lote**: persisten en BD y
  hacen `LoadActivePlan` (recargan todo el plan desde cero -> destruyen el estado en memoria
  y el historico). Cubrirlas requeriria undo persistido en BD (decidido NO hacer). Ademas
  topa con la trampa LoteId 0 vs NULL (FK_FS_PL_Node_Lote).
- **Replan all**: el usuario dijo que no hace falta.
- **Bloquear/desbloquear nodo** (campo Enabled): no es campo del snapshot, no afecta tiempos.

## PENDIENTE DE REVISAR

- [ ] **Doble clic en timeline + perdida de filas (redo)**: BUG detectado y CORREGIDO
      (RedoLastAction usaba PushUndo, que vaciaba el RedoStack -> un redo borraba los pasos
      futuros). Cambiado a `PushUndoKeepRedo`. **Verificar end-to-end** que navegar adelante
      y atras varias veces ya no elimina filas.
- [ ] **Limitacion conocida (cambio de centro con cascada nueva)**: si mueves un nodo
      CAMBIANDOLO de centro y eso arrastra en cascada nodos nuevos del centro destino, alguno
      de esos podria no quedar en el undo (CaptureSnapshotsFromNodePropagation captura segun el
      estado previo). El caso normal (mismo centro) esta 100% cubierto. Revisar si vale la pena
      fusionar before/after para cubrirlo.
- [ ] **Coste del batch O(n)**: BeginUndoBatch/EndUndoBatch hacen snapshot de TODOS los nodos
      antes y despues. OK para acciones de menu (baja frecuencia). Si se aplica a algo de alta
      frecuencia, reconsiderar.
- [ ] **Persistencia del undo de centro/lote**: ApplyNodeSnapshot restaura CentreId/LoteId en
      memoria, pero el undo NO persiste ese cambio en BD. Si en el futuro se quiere que el undo
      de centro/lote sobreviva, hay que escribir en BD (y cuidar LoteId 0 vs NULL).

## Snapshot AUTO diario (FS_PL_Snapshot, V062)

- Se MANTIENE como auditoria / checkpoint (no para el dia a dia). Manual sigue siendo util.
- Decision: el undo (este modulo) es para el "acabo de equivocarme, atras"; los snapshots son
  para restaurar puntos clave antes de un replanificado gordo.
- Pendiente aparte (ya anotado en memoria): los snapshots no serializan lotes.
