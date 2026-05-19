# Gestión de Calendarios

## Objetivo

Definir los **calendarios laborales** que utilizarán los centros de trabajo del planificador. Cada calendario combina:

- **Modelos horarios**: plantillas que definen las franjas laborables por día de la semana (jornada normal, nocturna, intensiva...).
- **Excepciones**: días especiales que rompen el patrón semanal (festivos, pausas puntuales, paros de mantenimiento...).

El motor de planificación respeta estos calendarios al calcular cuándo se puede ejecutar cada operación.

## Cuándo usarlo

- Al **instalar el sistema**: crear el calendario por defecto y asignarlo a los centros.
- **Cada año**: importar los festivos del nuevo ejercicio (botón "Importar festivos...").
- Cuando un **centro cambia de turno**: crear o modificar un modelo horario.
- Cuando hay **eventos puntuales**: pausas de mantenimiento, festivos locales, jornadas especiales (botón "Excepciones..." o "Excepción recurrente...").

## La pantalla

### Lista de calendarios (izquierda)

Cada calendario es una **plantilla independiente**. Los botones de la barra inferior permiten:

- **Añadir**: crear un calendario nuevo (con fines de semana cerrados por defecto).
- **Editar**: cambiar nombre y descripción.
- **Eliminar**: borrar el calendario y sus dependencias (modelos, excepciones, asignación a centros).
- **Clonar**: duplicar el calendario seleccionado con todos sus modelos y excepciones. Útil al preparar el calendario del año siguiente.

### Modelos horarios (centro)

Plantillas que definen las **franjas laborables** por día de semana. Un calendario puede tener varios modelos (ej.: "Jornada partida" + "Nocturna"). Uno de ellos es el **Default**.

- **Añadir / Editar / Eliminar** modelos.
- **Excepciones...**: abre el editor de excepciones del calendario seleccionado (con multiselección y filtros).
- **Importar festivos...**: carga una plantilla predefinida (Catalunya, España nacional...) para un año concreto. Los duplicados se omiten.
- **Excepción recurrente...**: crea de golpe varias excepciones siguiendo un patrón (ej.: "el primer lunes de cada mes, pausa 14-16h").

### Vista anual (derecha)

Muestra el año seleccionado con un código de color:

- **Verde**: día completamente laborable.
- **Naranja claro**: día parcial (con franjas no laborables).
- **Gris**: día no laborable (fin de semana cerrado).
- **Triángulo fucsia** en la esquina del día: indica que ese día tiene una **excepción** asociada.

Doble clic sobre un día abre el editor de excepciones para esa fecha.

### Panel de indicadores (derecha, opcional)

Activable con el checkbox **"Ver indicadores"** de la cabecera. Muestra KPIs anuales del calendario seleccionado:

- Días laborables / no laborables / parciales.
- Horas anuales y media diaria.
- Cuenta de excepciones festivas y parciales.
- Lista de modelos horarios y de centros asignados.

## Operaciones frecuentes

- **Preparar el año nuevo**: clonar el calendario actual y, sobre el clon, ejecutar "Importar festivos..." con el año siguiente.
- **Festivo local de última hora**: doble clic sobre el día en la vista anual y añadir excepción tipo "Festivo".
- **Pausa de mantenimiento semanal**: usar "Excepción recurrente..." indicando ordinal + día + horas.
- **Limpiar excepciones obsoletas**: abrir "Excepciones...", marcar las filas con el checkbox del header y pulsar "Eliminar seleccionadas".

## Atajos

- `ESC`: cierra la ventana.
- `?`: abre esta ayuda.
