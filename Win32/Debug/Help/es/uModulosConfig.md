# Módulos contratados

## Objetivo

Decir qué partes del Planner entran en la licencia de esta empresa.

No todos los clientes necesitan todo, y no todos lo compran. Un taller que planifica solo máquinas no quiere ver media aplicación dedicada a operarios; una empresa que no usa utillajes no necesita su catálogo. Aquí se decide qué ve cada cliente.

Es una pantalla de instalación y de ampliación, no de uso diario: se toca al poner en marcha el Planner y cuando el cliente contrata algo más.

## Qué está siempre incluido

La franja superior lo recuerda: **Gantt de producción, centros de trabajo, calendarios y turnos, backlog, planificación manual y automática, panel de control y conexión con el ERP**.

Eso es el núcleo del producto y no se puede desactivar. Sin ello no hay planificador.

## Los módulos

Cada tarjeta es un módulo, con su icono, lo que incluye y una casilla para activarlo o desactivarlo. El **color** dice el estado de un vistazo: verde si está contratado, gris si no.

| Módulo | Qué incluye |
|---|---|
| **Operarios** | Operarios, ausencias, habilidades, departamentos, planificador por operario y su carga |
| **Ingeniería (proyectos)** | Planificación por tareas: WBS, camino crítico, línea base y nivelación de recursos |
| **Stock y aprovisionamiento** | Proyección de stock, roturas anticipadas y recomendación de compra |
| **Utillajes y moldes** | Moldes, utillajes y sus restricciones en el motor de planificación |
| **Optimización avanzada** | Motor de reglas, tiempos de cambio y optimizador de secuencia |
| **Analítica y cuadros de mando** | Análisis del plan, mapas de calor, histogramas e indicadores de centros |
| **Suite de corte (nesting)** | Optimización de corte y anidado de piezas en plancha |

## Qué ve el cliente cuando un módulo está apagado

Depende del módulo, y lo dice cada tarjeta en su línea inferior:

- **No aparece en los menús**: el cliente ni se entera de que existe. Es lo apropiado para lo que no le aplica a su fábrica — un fabricante de bolsas no gana nada viendo el nesting de chapa.
- **Lo ve en gris con una invitación a solicitarlo**: la entrada sigue ahí y, al pulsarla, aparece un aviso de que no está incluido en su licencia y que puede pedirlo. Es lo apropiado para lo que **podría querer comprar**.

El criterio ya viene decidido módulo a módulo. Ocultarlo todo dejaría la aplicación muy limpia, pero el cliente no descubriría nunca lo que se pierde y no lo pediría.

## Caducidad y observaciones

- **Caduca el**: déjalo **vacío** para una licencia sin fecha de fin, que es lo habitual. Si pones una fecha, el módulo deja de estar disponible al llegar ese día, aunque la casilla siga marcada.
- **Observaciones**: notas internas — número de pedido, condiciones, con quién se habló. No las ve el cliente.

## Cómo se usa

1. Marca los módulos que el cliente ha contratado y desmarca el resto.
2. Si alguno es temporal (una prueba, una cesión), pon la fecha de caducidad.
3. Pulsa **Guardar**.

Los cambios se aplican **al momento**: los menús se recalculan sin reiniciar.

## Errores frecuentes

- **He desactivado un módulo y el cliente lo sigue viendo**: será uno de los que se enseñan en gris a propósito. Compruébalo en la línea inferior de su tarjeta.
- **La opción del menú aparece pero avisa de que no está contratado**: es el comportamiento correcto de los módulos de venta cruzada, no un fallo.
- **Todos los módulos aparecen activos y no puedo cambiarlo**: hace falta ser administrador. También ocurre si la base de datos no tiene aplicada la última actualización: en ese caso todo queda activo a propósito, para que nadie pierda funciones por una actualización pendiente.
- **He puesto una fecha de caducidad ya pasada**: el módulo se apaga aunque la casilla esté marcada. Borra la fecha para dejarlo sin caducidad.

## Una advertencia honesta

Esto es **organización comercial de la interfaz**, no una protección contra copia. Un administrador del cliente con acceso a la base de datos podría activar módulos por su cuenta.

Se ha diseñado así a conciencia: sirve para vender por partes y para que cada cliente vea lo que le corresponde, y descansa en el contrato, no en una barrera técnica.

## Por qué es útil

Un planificador que lo enseña todo abruma al cliente pequeño y no deja crecer al grande. Con los módulos, la misma aplicación se presenta a la medida de cada uno: quien compra producción ve una herramienta de producción, y quien amplía más adelante la ve crecer sin reinstalar nada.

Pulsa **F1** en cualquier momento para volver a esta ayuda.
