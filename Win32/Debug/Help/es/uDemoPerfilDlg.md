# Demostración a medida

## Objetivo

Preparar una demostración que hable el idioma del cliente que vas a visitar.

La demostración de siempre (botón **Demo**) crea un taller genérico: operaciones CORTAR y PULIR, artículos "Pieza A grande", clientes CLI-001. Sirve para enseñar la herramienta, pero delante de un fabricante de bolsas de papel o de una inyectora de plástico dice justo lo contrario de lo que interesa: que el planificador no va con ellos.

Con un **perfil**, la misma demostración aparece con las líneas, los artículos y los tiempos de cambio del sector del cliente.

## Cómo se usa

1. Pulsa **Demo 2.0** en la barra superior.
2. Elige a la izquierda el **tipo de planta** que más se parezca al cliente.
3. Comprueba a la derecha lo que se va a crear: líneas, artículos y tiempos de cambio.
4. Ajusta cuántas órdenes quieres y pulsa **Generar demo**.

El botón **Demo** de siempre sigue funcionando igual. Si algo no sale como esperabas, siempre puedes volver a él.

## Qué ves antes de generar

- **Ficha de cabecera**: cuántas líneas hay y cuántas van en serie, los pasos de la ruta, **qué dispara el tiempo de cambio**, cuánto dura ese cambio de media y en qué unidad se mide la producción.
- **Cómo se verá el plan**: un esquema en miniatura del Gantt que va a salir. Cada carril es una línea, los bloques de color son trabajos agrupados y el rayado granate entre ellos es el tiempo de preparación. Las líneas con varios puestos en paralelo llevan una banda fina debajo.
- **Ruta de fabricación**: los pasos en el orden real en que se fabricará.
- **Artículos de ejemplo**: los nombres que verá el cliente en el plan, con el valor que provoca el cambio. Es lo que más delata si la demostración va con él o no — léelos antes de generar.
- **Cuántas órdenes**: y a su lado, cuántas tareas saldrán realmente en el plan (cada orden se descompone en 3 lotes con sus pasos).

## Por qué "tipo de planta" y no "sector"

Puede sorprender que la lista no diga "packaging", "alimentación" o "metal". La razón es práctica.

Dos empresas del **mismo sector** pueden necesitar demostraciones opuestas: una convertidora de film con dos líneas de impresión y una fábrica de bolsas con siete líneas de formato comparten sector y no se parecen en nada operativamente.

Y al revés: una fábrica de bolsas y una inyectora de plástico, que no comparten sector, sí comparten lo que de verdad define un plan — líneas en paralelo, cambio de formato o molde, series largas.

Lo que hace útil una demostración no es la etiqueta del sector, sino la **forma de la planta**. Por eso con pocos perfiles se cubren muchas visitas.

## Las reglas de tiempo de cambio

Si el perfil las trae, la casilla inferior las crea junto con la demostración.

Son las que hacen aparecer en el plan las **franjas de preparación** entre trabajos: cuando dos trabajos seguidos en la misma línea son de formato distinto, el plan deja el hueco del cambio y lo marca. Es el argumento que más pesa en una planta con series largas, así que conviene dejarla marcada.

Si la casilla aparece desactivada, es que ese perfil no define tiempos de cambio.

## Crear tu propio perfil

Pulsa **Abrir carpeta de perfiles**. Cada perfil es un fichero de texto que puedes copiar y editar con cualquier editor:

- Copia el perfil más parecido y renómbralo.
- Cambia los nombres de líneas, artículos y clientes por los del cliente que vas a visitar.
- Ajusta los minutos de cambio de cada línea.
- Guarda y vuelve a abrir la ventana: el perfil nuevo ya aparece en la lista.

No hace falta instalar nada ni pedir una versión nueva del programa. Un perfil bien hecho se puede pasar por correo a otro compañero.

## Errores frecuentes

- **No aparece ningún perfil**: la ventana te dice en qué carpeta deberían estar. Si está vacía, se crean solos la próxima vez que abras la ventana.
- **Un perfil que has editado no sale en la lista**: probablemente el fichero tiene un error de formato. Compáralo con otro que sí funcione, fijándote en las comas y las comillas.
- **No se ven las franjas de cambio en el plan**: la casilla de reglas tiene que estar marcada al generar, y las líneas del perfil deben tener minutos de cambio.
- **Las líneas del cliente real siguen ahí**: es correcto. Los perfiles añaden sus líneas, no borran las que ya existen. La demostración vive en un proyecto aparte y no toca los datos reales.

## Por qué es útil

Preparar una visita comercial dejaba de ser una tarea artesanal: alguien tenía que inventarse a mano artículos y centros creíbles para cada cliente, y normalmente no daba tiempo.

Con los perfiles, esa preparación es elegir de una lista. Y lo que se enseña deja de ser una herramienta genérica para parecer lo que el cliente reconoce como su propia planta.

Pulsa **F1** en cualquier momento para volver a esta ayuda.
