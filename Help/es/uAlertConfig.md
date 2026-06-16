# Configuración de alertas

## Objetivo

Decide **qué alertas de planificación quieres vigilar** y con **qué importancia**.
Cada planta tiene prioridades distintas: aquí las ajustas a tu medida. La
configuración se guarda en la base de datos y es **por empresa**.

## La pantalla

Una fila por cada tipo de alerta del catálogo (disponibles y próximas):

- **Cód.**: código estable de la alerta (A01, R02…).
- **Alerta**: descripción.
- **Activa**: marca/desmarca para vigilar o ignorar ese tipo. Una alerta
  desactivada no se evalúa ni aparece en el panel ni en el listado.
- **Peso**: importancia de 1 a 100. Ordena las alertas por impacto y, sobre todo,
  determina cuánto penaliza cada incidencia en la **puntuación de salud del plan**
  (0-100) que ves en el panel del Gantt y en el listado de alertas. Una alerta de
  peso alto (p. ej. "fuera de plazo", 95) baja mucho más la salud que una de peso
  bajo (p. ej. "sin fecha de entrega", 15). Ajusta los pesos a las prioridades de
  tu planta.
- **Estado**: _Disponible_ (ya se detecta) o _Próximamente_ (en preparación).

## Operaciones frecuentes

- **Activar / desactivar**: clic en la casilla **Activa** de la fila.
- **Cambiar la importancia**: edita el **Peso** (1-100).
- **Guardar**: botón **Guardar**. Los cambios se aplican de inmediato al volver
  al listado de alertas.
- **Descartar**: botón **Cancelar** o `Esc`.

> Las alertas marcadas como _Próximamente_ se pueden configurar de antemano
> (peso y activa), pero no se evaluarán hasta que estén disponibles.

## Cómo influye el peso en la salud del plan

La **salud del plan** es una puntuación de 0 a 100 (100 = plan limpio) que resume
todas las incidencias activas. Se calcula ponderando cada incidencia por su peso:

- Más incidencias → menos salud.
- Incidencias de **mayor peso** restan más salud que las de menor peso.
- Desactivar una alerta hace que deje de contar para la salud.

Así, ajustando pesos y activando/desactivando tipos, decides qué define un "buen
plan" para tu planta. La salud aparece en el panel del Gantt (con color de
semáforo) y en la cabecera del listado de alertas.

| Salud | Etiqueta |
|-------|----------|
| 90-100 | Excelente |
| 75-89 | Bueno |
| 50-74 | Regular |
| 25-49 | Malo |
| 0-24 | Crítico |
