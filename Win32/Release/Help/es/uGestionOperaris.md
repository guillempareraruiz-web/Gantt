# Gestión de Operarios

## Objetivo

Administrar los **operarios** de la empresa: las personas que ejecutan las operaciones del plan. Desde aquí puedes crear operarios, asignarles un calendario laboral, agruparlos por departamentos, definir sus habilidades (polivalencia) y darlos de alta o de baja.

## La pantalla

Un **listado** con todos los operarios. Cada fila muestra:

- **ID**: identificador interno del operario.
- **Nombre**: nombre del operario.
- **Calendario**: calendario laboral que se le aplica (turnos, festivos, jornada). Se elige desde el propio listado.
- **Activo**: indica si el operario está en activo. Si lo desmarcas, el operario deja de aparecer en las listas de asignación, combos e informes del resto del programa, pero se conserva su ficha y su historial.
- **Departamentos**: departamentos a los que pertenece.
- **Habilidades**: número de habilidades (capacitaciones) que tiene registradas.

Las filas de los operarios **no activos** se muestran con **fondo rojo claro**, para distinguirlos de un vistazo del resto.

### Barra de botones

- **Nuevo**: crea un operario pidiendo solo el nombre. Queda activo por defecto.
- **Eliminar**: borra el operario seleccionado (y sus departamentos y habilidades) tras confirmar. Si solo quieres retirarlo temporalmente, es preferible desmarcar **Activo** en lugar de eliminarlo.
- **Guardar cambios**: guarda las modificaciones hechas directamente en el listado (nombre, calendario, activo y campos personalizados).
- **Asignar Departamentos...**: abre la asignación de departamentos del operario seleccionado.
- **Polivalencia y coste...**: define las habilidades del operario y sus costes por hora.
- **Matriz polivalencia**: muestra en una única tabla qué operarios dominan qué habilidades.

## Cómo trabajar

1. Para cambios rápidos (nombre, calendario, activar/desactivar), edita la celda directamente en el listado y pulsa **Guardar cambios**.
2. Para retirar un operario que ya no trabaja pero cuyo historial quieres conservar, **desmárcalo como Activo** y guarda: desaparecerá de las listas de planificación pero seguirá aquí, en rojo.
3. Usa **Asignar Departamentos** y **Polivalencia y coste** para completar la ficha del operario.

## Por qué es útil

Mantener la lista de operarios al día es la base para que la planificación reparta el trabajo entre las personas adecuadas. Marcar como no activos a los operarios que ya no están disponibles —en lugar de borrarlos— evita que aparezcan en las asignaciones sin perder su historial.

Pulsa **F1** en cualquier momento para volver a esta ayuda.
