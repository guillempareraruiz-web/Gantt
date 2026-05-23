# Sincronizar con ERP

Esta pantalla importa los centros de trabajo y las máquinas del ERP a la base de datos del planificador, sin sobrescribir los cambios que hayas hecho manualmente.

## Para qué sirve

Cuando se conecta el planificador por primera vez al ERP, las pantallas de Centros y Máquinas aparecen vacías porque la información todavía no se ha traído. Esta pantalla hace ese primer volcado y, a partir de ahí, sirve también para refrescar los datos cada vez que el ERP cambia (nuevos centros, máquinas nuevas, costes actualizados...).

## Cómo se usa

1. **Pulsa "Previsualizar"**. La aplicación pide al ERP la lista actual de centros y máquinas y la compara con lo que ya tienes en local. Cada fila aparece marcada con un color y un estado:

   - **Nuevo** (verde): registro que no existe en local. Se creará al sincronizar.
   - **Actualizado** (amarillo): el ERP ha cambiado el registro desde la última sincronización y tú no habías tocado ese registro localmente. Se sobrescribirá.
   - **Sin cambios** (blanco): nada que hacer.
   - **CONFLICTO** (rojo): el ERP ha cambiado el registro **y** tú también lo habías editado a mano. Decides tú qué hacer (ver más abajo).
   - **Eliminado en ERP** (gris): el registro venía del ERP, pero ahora el ERP ya no lo devuelve.

2. **Revisa la columna "Aplicar"**. Por defecto se marcan los nuevos y los actualizados, y se dejan **sin marcar** los conflictos y los sin cambios.

3. **Para los conflictos**, ve a la columna "Si conflicto" y elige:
   - **Aplicar ERP**: sobrescribe el valor local con el del ERP. Pierdes tu edición manual.
   - **Mantener local**: conserva el valor que tú habías puesto. La fila queda marcada como "mixta" (parte ERP, parte manual) y no volverá a salir como conflicto hasta el próximo cambio del ERP.
   - **Ignorar**: no aplica nada esta vez. El conflicto seguirá apareciendo la próxima vez que previsualices.

4. **Pulsa "Sincronizar seleccionados"**. Solo se aplican las filas con "Aplicar" marcado. Al acabar, la pantalla se refresca y verás el resumen en la parte inferior.

## Pestañas

- **Resumen**: vista rápida con el conteo por estado de cada entidad. Es la primera pestaña y se actualiza al pulsar "Previsualizar".
- **Centros de trabajo**: trae código, descripción, política de concurrencia (paralela o secuencial), número de máquinas, coste por hora y grupo horario.
- **Máquinas**: trae código, marca, modelo, descripción, coste por hora y unidades por hora.
- **Operarios**: trae código, nombre, cargo, costes hora (normal y extra), grupo horario y contacto.
- **Centros × Máquinas**: relación de qué máquinas pertenecen a qué centro, con orden, coste/hora específico y porcentajes de corrección. Esta pestaña depende de las dos anteriores: si un centro o una máquina aún no se ha sincronizado, su relación aparece como "Error" con el aviso correspondiente.
- **Modelos horarios**: plantillas de jornada (turnos, franjas de trabajo) que vienen del ERP. Cada modelo se importa al calendario "ERP" del planificador con sus franjas replicadas a los 7 días de la semana, para que las puedas editar después por día desde Calendarios.
- **Almacenes**: catálogo de almacenes del ERP (código, nombre, grupo, responsable, dirección, contacto). Útil para el módulo de Stock.
- **Familias**: clasificación de artículos. Una fila por combinación familia+subfamilia. Útil como filtro en Backlog y vistas de stock.
- **Calendarios**: importa los **grupos horarios** del ERP (en Sage, son los calendarios completos: "Operarios Producción", "Administrativos", etc.) y los convierte en calendarios del planificador con sus reglas semanales (días laborables) y excepciones (festivos puntuales, cambios de turno). Para cada grupo:
  - Se lee el calendario laboral del ERP para los próximos 365 días.
  - Por cada día de la semana, se mira si la mayoría de fechas son laborables o festivas y se genera la regla semanal correspondiente.
  - Cada día que **difiere** del patrón semanal (festivo en un día laborable o viceversa) se guarda como excepción.
  - Los centros que en Sage tienen ese grupo horario quedan vinculados automáticamente vía el campo `GrupoHorarioCodigo`.

  Si re-sincronizas un grupo que ya existía como ERP, las reglas y excepciones se **regeneran completas** (las ediciones manuales que se hayan hecho a las reglas se pierden). Para conservarlas, marca "Mantener local" en la columna "Si conflicto".

Todas las pestañas funcionan igual y comparten el botón "Sincronizar seleccionados", que aplica los cambios marcados en las cuatro de una vez.

## Vinculación automática operarios ↔ centros ↔ calendarios

Al final de cada sincronización, el sistema **vincula automáticamente**:
- Cada **operario** con su calendario (campo `CalendarId`) según su grupo horario importado del ERP.
- Cada **centro** con su calendario en la tabla de relación, según su grupo horario.

Esto significa que si sincronizas Operarios o Centros antes que Calendarios, la vinculación queda pendiente. Al sincronizar Calendarios después, el post-paso completa los enlaces automáticamente. El contador "Vinculados: X operarios + Y centros" del resumen al pie te lo confirma.

Si un operario o centro tiene un `GrupoHorarioCodigo` que no existe como calendario, se queda desvinculado: solo cal sincronizar Calendarios y tornar a sincronitzar (o crear el grup manualment).

## Orden recomendado de sincronización

1. **Centros de trabajo** y **Máquinas** primero (no tienen dependencias entre sí).
2. **Operarios** y **Modelos horarios** (independientes del resto).
3. **Centros × Máquinas** al final: necesita que ambos extremos ya estén importados para enlazarlos correctamente. Si lanzas todo de una vez, el form ya lo aplica en este orden internamente.

## Sobre los modelos horarios

El ERP entrega los modelos como plantillas de franjas de trabajo (por ejemplo "Jornada partida 8-13 y 15-18"). En el planificador, cada modelo se crea dentro de un calendario llamado **"ERP"** (que el sistema crea automáticamente la primera vez). Las franjas se replican a los 7 días de la semana, así puedes editarlas después desde **Datos > Calendarios** para ajustar qué días aplican y cuáles no.

Si al sincronizar un modelo en conflicto eliges "Aplicar ERP", las líneas locales editadas a mano se reemplazan por completo. Si prefieres conservarlas, usa "Mantener local".

## Atajos

- **Marcar todos / Desmarcar todos**: actúa solo sobre la pestaña activa y solo sobre las filas que se pueden aplicar (nuevos, actualizados y conflictos).
- Las columnas se pueden ordenar y filtrar como cualquier otro grid del planificador.

## Buenas prácticas

- La primera vez, sincroniza **todo** sin tocar conflictos (no debería haber).
- En sincronizaciones posteriores, revisa siempre los conflictos antes de pulsar el botón: la opción por defecto es no aplicarlos, así que si los dejas como están no pasa nada.
- Si has personalizado mucho un centro o una máquina y no quieres que se sobrescriba nunca, usa "Mantener local" cuando aparezca un conflicto.

## Si la pantalla no muestra nada

- Comprueba en **Archivo > Selector de ERP** que hay un ERP configurado.
- La cabecera de esta misma pantalla muestra el ERP activo (por ejemplo "ERP: Sage 200"). Si pone "no configurado", configúralo primero.
