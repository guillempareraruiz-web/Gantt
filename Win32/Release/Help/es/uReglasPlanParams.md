# Planificación por reglas de prioridad

## ¿Qué hace esta pantalla?

Decide automáticamente **en qué orden** se hace el trabajo del plan, según un criterio que usted elige, y le enseña **cómo quedaría** antes de aplicar nada.

La idea es sencilla: en vez de ordenar usted a mano qué operación va primero, le dice al planificador *cómo* quiere priorizar —por ejemplo, "primero lo que vence antes"— y el sistema reordena toda la cola y la coloca en el tiempo respetando la capacidad de cada centro.

Sirve para responder, con números, preguntas como:

- Si priorizo por fecha de entrega, ¿cuántos pedidos llegarían tarde?
- ¿Y si en el centro más cargado hago primero las tareas cortas?
- ¿Qué criterio deja menos retrasos en total?

## Cómo se usa, paso a paso

1. Abra el menú **Vistas → Planificación por reglas...**
2. Elija la **dirección**:
   - **Forward**: empieza en la *fecha base* y va colocando el trabajo hacia delante.
   - **Backward**: parte de la fecha de entrega de cada trabajo y va hacia atrás.
3. Indique la **fecha base** (desde cuándo se empieza a planificar).
4. Elija el **tipo de regla**:
   - **Reglas canónicas**: los criterios estándar (EDD, SPT, etc.) que se explican abajo.
   - **Reglas personalizadas**: sus propios perfiles guardados en *Configuración → Reglas de Planificación*.
5. Elija la **regla** concreta dentro del tipo.
6. Si el tipo es **canónica**, puede afinar con **desempates** (ver más abajo). Con reglas personalizadas los desempates no aparecen, porque el perfil ya lleva sus criterios encadenados.
7. Pulse **Previsualizar** y revise el resultado y los indicadores.

> La previsualización **nunca modifica el plan**. Solo enseña cómo quedaría con las reglas elegidas, para que pueda comparar opciones con tranquilidad.

---

## Las reglas explicadas con ejemplos

Para entender cada regla, imagine que en un centro tenemos **estos 4 trabajos pendientes** y hoy es **lunes 1**:

| Trabajo | Duración | Fecha de entrega |
|---------|----------|------------------|
| **A** | 8 h  | viernes 5  |
| **B** | 2 h  | martes 2   |
| **C** | 10 h | lunes 8    |
| **D** | 1 h  | martes 2   |

Según la regla elegida, el sistema los pondría en este orden:

### EDD — "primero lo que vence antes"
Ordena por fecha de entrega, de la más próxima a la más lejana.

> Orden: **B y D** (martes 2) → **A** (viernes 5) → **C** (lunes 8)

**Cuándo usarla:** es la opción más habitual cuando lo importante es **cumplir plazos de entrega**.

### SPT — "primero las tareas cortas"
Ordena por duración, de la más corta a la más larga.

> Orden: **D** (1 h) → **B** (2 h) → **A** (8 h) → **C** (10 h)

**Cuándo usarla:** cuando quiere **vaciar rápido la cola** y reducir el número de trabajos que están esperando. Saca muchos trabajos pequeños del medio enseguida.

### LPT — "primero las tareas largas"
Lo contrario de SPT: las más largas primero.

> Orden: **C** (10 h) → **A** (8 h) → **B** (2 h) → **D** (1 h)

**Cuándo usarla:** cuando interesa **arrancar pronto los trabajos grandes** porque son los que marcan el ritmo, dejando los pequeños para rellenar huecos.

### FIFO — "por orden de llegada"
Respeta el orden en que entraron los trabajos, sin mirar fechas ni duración.

> Orden: el mismo en que llegaron (A, B, C, D si ese fue el orden de entrada).

**Cuándo usarla:** cuando quiere ser **justo y previsible** ("el que llega primero, se hace primero"), sin priorizar por urgencia.

### Critical Ratio — "el que va más justo de tiempo"
Compara el **tiempo que queda hasta la entrega** con el **trabajo que falta por hacer**. Cuanto menos margen relativo, antes va. Si un trabajo ya no llega a tiempo, sube arriba del todo.

> Ejemplo: **B** tiene 1 día para 2 h de trabajo (va sobrado), pero **C** que dura 10 h y entrega el lunes 8 puede ir más justo de lo que parece. La regla calcula esa proporción y prioriza lo más apurado.

**Cuándo usarla:** cuando hay trabajos **largos con poco margen** mezclados con cortos holgados, y quiere equilibrar urgencia y carga, no solo la fecha.

### Slack — "el de menos holgura"
La *holgura* es el margen que sobra: tiempo hasta la entrega **menos** el trabajo que falta. Primero va el que tiene **menos holgura** (o ninguna).

> Ejemplo: **A** dura 8 h y entrega el viernes 5 → tiene cierta holgura. Si hubiera un trabajo que dura casi lo mismo que el tiempo que le queda, ese iría antes porque casi no tiene margen.

**Cuándo usarla:** parecida a Critical Ratio, pero en **tiempo absoluto** en vez de proporción. Útil para detectar lo que está "al límite".

### Prioridad ERP — "respeta la prioridad marcada"
Usa la prioridad que cada trabajo ya trae marcada desde el ERP, de mayor a menor.

**Cuándo usarla:** cuando la **planificación de prioridades ya se hace en el ERP** y aquí solo quiere respetarla.

### Reglas personalizadas (sus propias reglas)

Si en **Tipo de regla** elige **"Reglas personalizadas"**, en el desplegable de regla aparecen los perfiles que usted haya creado en **Configuración → Reglas de Planificación**.

A diferencia de las canónicas (que miran un solo criterio), un perfil personalizado puede combinar **varios criterios a la vez y con peso** (por ejemplo: primero por fecha de entrega, y a igualdad por color de artículo), e incluso usar **campos propios** que usted haya añadido.

**Cuándo usarlo:** cuando ninguna regla estándar refleja del todo *su* forma de priorizar y prefiere usar una combinación a medida que ya tiene guardada.

> Con un perfil personalizado no aparecen los desempates: el propio perfil ya lleva sus criterios encadenados. Si no tiene ningún perfil guardado, el tipo "personalizadas" no estará disponible.

---

## Los desempates

¿Qué pasa cuando dos trabajos empatan? En el ejemplo, **B** y **D** vencen los dos el martes 2. Con solo EDD, no sabríamos cuál va primero.

Para eso están los desempates:

- **Desempate 1**: se aplica cuando la regla principal empata.
- **Desempate 2**: se aplica si todavía siguen empatados.

> Ejemplo: regla principal **EDD**, desempate 1 **SPT**.
> B y D empatan en fecha (martes 2) → al desempatar por SPT, va antes **D** (1 h) que **B** (2 h).

Si tras los dos desempates aún hay empate, se respeta un orden estable y predecible (no cambia de una previsualización a otra).

---

## Reglas distintas por centro (avanzado)

Marque **"Usar reglas distintas por centro"** para que un centro concreto use un criterio diferente al general.

> Caso típico: el **cuello de botella** de la fábrica conviene tratarlo con **SPT** (tareas cortas) para descongestionarlo cuanto antes, mientras el resto de centros siguen con **EDD** (cumplir entregas).

Cada centro que deje en `(global)` usará la regla de arriba. Solo cambie los centros que quiera tratar distinto.

> Los overrides por centro solo permiten **reglas canónicas** (EDD, SPT, etc.). Los perfiles personalizados se aplican siempre a todo el plan, no por centro.

---

## La previsualización: qué mirar

Al pulsar Previsualizar verá:

- **El orden propuesto** de todas las operaciones, numerado, con su centro, inicio, fin y fecha de compromiso.
- La columna **Retraso**: marca en qué trabajos se terminaría *después* de la fecha de entrega, y cuántas horas.
- Un resumen con los **indicadores clave**:
  - cuántas operaciones se planifican y cuántas quedarían sin sitio,
  - **número de retrasos previstos**,
  - **retraso total y medio** (en horas),
  - **makespan**: el tiempo total desde que empieza el primer trabajo hasta que acaba el último.

## Comparar reglas de un vistazo

En lugar de probar las reglas una a una, pulse **"Comparar reglas..."**. Se abre una ventana que ejecuta **las 7 reglas canónicas** sobre el mismo plan y las pone una al lado de otra:

- **Pestaña "Comparativa"**: una tabla con los indicadores de cada regla (planificadas, retrasos, retraso total, makespan, fuera de plazo) y un **resumen con conclusiones y una recomendación** (qué regla deja menos retrasos y por qué).
- **Una pestaña por regla**: con el orden propuesto completo de esa regla, por si quiere ver el detalle.

Es la forma más rápida de decidir: mire la pestaña Comparativa, vea qué regla gana, y si quiere el detalle haga clic en su pestaña.

> Igual que la previsualización, comparar **no modifica el plan**.

## Consejo práctico

Una buena forma de elegir regla:

1. Pulse **Comparar reglas...** y mire la pestaña Comparativa.
2. Fíjese en la columna **Retrasos** y en la **recomendación** del resumen.
3. Quédese con la regla que deje **menos retrasos** para su situación.

Como nada de esto toca el plan, puede probar todas las veces que quiera sin riesgo.
