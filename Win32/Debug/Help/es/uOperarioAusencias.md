# Gestión de Ausencias

## Objetivo

Registrar las **ausencias de los operarios** (vacaciones, bajas, formación, permisos...) para que el planificador descuente esas horas de la capacidad disponible y no asigne trabajo en esos días.

Cada ausencia se aplica a un único operario y bloquea un tramo de fechas (puede ser un día suelto, varios días o un rango largo).

## Cuándo usarlo

- Al **inicio del año**: cargar las vacaciones aprobadas de cada persona.
- Cuando llega una **baja médica** o un permiso puntual.
- Para planificar **formaciones**, **viajes** o cualquier evento que impida que el operario trabaje.
- Antes de lanzar una **replanificación** importante: revisar que las ausencias previstas estén al día.

## La pantalla

### Lista de operarios (izquierda)

Muestra todos los operarios activos con el número de ausencias registradas. Permite:

- **Buscar** por nombre.
- **Filtrar** por departamento.
- Seleccionar un operario para ver y gestionar sus ausencias en la parte derecha.

### Pestaña "Lista" (derecha)

Tabla con las ausencias del operario seleccionado. Cada fila muestra tipo, fecha de inicio, fecha de fin, número de días y descripción.

Filtros disponibles arriba:

- **Año**: ver solo las ausencias del año indicado.
- **Tipo**: filtrar por categoría (vacaciones, baja, formación...).

Botones:

- **Nueva**: añadir una ausencia.
- **Editar**: modificar la ausencia seleccionada (también se puede hacer doble clic en la fila).
- **Eliminar**: borrar la ausencia seleccionada.
- **Duplicar**: crear una copia con las mismas fechas, útil para repetir un patrón en otro operario.
- **Exportar CSV**: guardar la lista actual a un fichero para compartirla o archivarla.

### Pestaña "Calendario"

Vista mensual con todos los días pintados según el estado:

- **Día con ausencia**: coloreado según el tipo.
- **Día normal**: en blanco.

Permite navegar mes a mes (botones ◀ y ▶) o volver al mes actual (botón **Hoy**). Haciendo clic en un día se abre la creación rápida de una ausencia para esa fecha.

## Operaciones frecuentes

### Cargar las vacaciones de un operario

1. Selecciona el operario en la lista de la izquierda.
2. Pulsa **Nueva**.
3. Indica tipo "Vacaciones", fecha de inicio y fecha de fin.
4. Guarda. La ausencia aparece en la lista y en el calendario.

### Duplicar la ausencia a otro operario

Útil cuando un grupo coge vacaciones la misma semana:

1. Selecciona la ausencia en la pestaña Lista.
2. Pulsa **Duplicar**.
3. Elige el operario destino y confirma.

### Detección de solapamientos

Si al guardar una ausencia coincide con otra ya existente del mismo operario, el sistema avisa y pide confirmación antes de añadirla. Sirve para evitar duplicados por error.

## Ayuda contextual

Pulsa el botón **?** en la barra de título de la ventana para abrir esta ayuda en cualquier momento.
