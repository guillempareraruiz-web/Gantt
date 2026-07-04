# Heatmap de carga por operario

## Objetivo

Ver **cuánto está cargado cada operario** a lo largo del tiempo, comparando las horas que tiene asignadas con la capacidad real de su calendario.

Responde a preguntas como:

- ¿Quién está saturado y quién tiene margen?
- ¿Hay operarios sobre-asignados en alguna semana?
- ¿Se reparte el trabajo de forma equilibrada dentro del equipo?

## La pantalla

Una **matriz** con los operarios en las filas y los periodos en las columnas. Cada celda muestra el % de ocupación del operario en ese periodo, con un código de color que va del verde claro (poca carga) al rojo intenso (sobrecarga grave).

### Filtros (barra superior)

- **Granularidad**: Días, Semanas (por defecto) o Meses.
- **Periodos**: cuántos periodos mostrar.
- **Desde**: fecha del primer periodo.
- **Operarios**: selección múltiple. La opción "(Todos)" marca o desmarca el resto.
- **Departamento**: muestra sólo los operarios del departamento elegido. Con "(Todos los departamentos)" se ven todos. Un operario puede pertenecer a varios departamentos.
- **Recalcular**: fuerza el recálculo manual.

### Botones del encabezado

- **Exportar CSV**: guarda la tabla de porcentajes (con la columna Promedio y la fila TOTAL) en un archivo que se abre directamente en Excel.
- **Exportar PNG**: guarda la imagen completa del heatmap, útil para informes y presentaciones.

### Lectura de la matriz

- **Filas**: operarios (filtrados por departamento y por la selección de operarios).
- **Columnas**: periodos consecutivos.
- **Celda**: % de ocupación del operario en ese periodo.
- **"---"**: el operario no tiene calendario asignado o el calendario no tiene horas laborables en ese periodo.

Al pasar el ratón por encima de una celda aparece el **detalle**: horas asignadas frente a horas de capacidad, número de tareas y aviso de sobrecarga si procede.

### Columnas de resumen (a la derecha)

- **Tendencia**: un mini-gráfico por operario que dibuja la evolución de su carga a lo largo de los periodos, con el mismo código de color. La línea de puntos marca el 100 %. Permite ver de un vistazo si un operario va de más a menos, si tiene picos, etc.
- **Promedio**: la carga media del operario en todos los periodos mostrados. Sirve para ordenar el equipo por carga.

### Fila TOTAL

Bajo la matriz, la fila **TOTAL taller** resume la saturación global del equipo en cada periodo (horas asignadas de todos los operarios frente a su capacidad conjunta). Es la foto de si el taller, en su conjunto, está sobrecargado o tiene margen. También tiene detalle al pasar el ratón.

### Ordenar el equipo

Haga clic en la cabecera **Operario** para ordenar alfabéticamente, o en la cabecera **Promedio** para ordenar por carga (los más cargados arriba). Un nuevo clic invierte el orden; la flecha indica el criterio activo.

### Ver detalle

El botón **Ver detalle** agranda las filas y muestra dentro de cada celda, además del %, las **horas asignadas / capacidad** y el **número de tareas**. Vuelva a pulsarlo para volver a la vista compacta.

### Leyenda de colores

Misma escala que los otros heatmaps:

- **0%**: vacío.
- **1-50%**: verde (margen amplio).
- **51-90%**: amarillo (carga creciente).
- **91-100%**: naranja (al límite).
- **101-120%**: rojo claro (sobrecarga moderada).
- **>120%**: rojo intenso (sobrecarga grave).

## Qué datos se usan

- **La carga** se calcula a partir de las asignaciones del operario a operaciones planificadas en el plan activo. Las horas de cada asignación se reparten proporcionalmente al tiempo que la operación ocupa en cada periodo.
- **La capacidad** sale del calendario asignado al operario (horario laboral, festivos y excepciones definidos en **Gestión de Calendarios**).

> **Nota:** la versión actual no descuenta automáticamente las ausencias registradas (vacaciones, bajas...). La capacidad mostrada es la del calendario nominal del operario.

## Por qué es útil

Convierte la lista de asignaciones (operario → operación → horas) en una **vista de equipo** inmediata. Detecta desequilibrios de carga antes de que se conviertan en retrasos o en horas extra:

- Si un operario aparece rojo varias semanas seguidas, hay que redistribuir trabajo o reforzar el equipo.
- Si hay muchas filas verdes claras, sobra capacidad o falta trabajo entrado en el plan.
- Si la fila TOTAL está en naranja o rojo, el taller entero está al límite: no basta con mover trabajo entre operarios.
- Si se ve un patrón "pico-valle" semana a semana en la columna Tendencia, conviene suavizar la planificación.

Complementa al **Heatmap de carga por centro** (vista agregada por puesto de trabajo) y al **Heatmap de entregas vs capacidad** (compromiso comercial).
