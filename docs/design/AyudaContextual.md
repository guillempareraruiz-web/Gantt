# Ayuda contextual por pantalla

## Objetivo

Cada form principal de la aplicación tiene un botón "?" en la cabecera que abre un visor con la ayuda contextual de esa pantalla.

## Decisiones

- **Formato**: Markdown (texto plano, versionable junto al código, editable con cualquier editor).
- **Almacenamiento**: ficheros `.md` en disco, no en BBDD. La ayuda es **producto** (la diseña FactoryStart, se distribuye con el .exe), no dato del cliente.
- **Render**: parser Markdown -> HTML interno minimal, mostrado en `TWebBrowser` para look pro. Sin dependencias externas.
- **Multilenguaje**: estructura `Help/<lang>/<TopicKey>.md`. Default `es`, ampliable a `ca`, `en`, etc.

## Convención de nombres

- Carpeta junto al .exe: `Help/<lang>/`.
- Por cada form: un fichero `<UnitName>.md` (sin el prefijo `u`, sin extensión `.pas`).
  - Ej.: `uGestionCalendarios.pas` -> `Help/es/uGestionCalendarios.md`.
- El topic key por defecto es el `ClassName` del form sin la `T` inicial, pero por simplicidad usamos el nombre del fichero unit.

## Despliegue

Las carpetas `Help/` deben copiarse a:
- `<root>/Help/es/`
- `<root>/Win32/Debug/Help/es/`
- `<root>/Win32/Release/Help/es/`

(Mismo patrón que `Plantillas/Festivos/`.)

## API

Unidad reutilizable `uHelpViewer.pas`:

```pascal
THelpViewer = class
public
  class procedure Show(const ATopicKey: string; const ALang: string = 'es');
end;
```

Uso desde cualquier form:
```pascal
procedure TfrmGestionCalendarios.btnAyudaClick(Sender: TObject);
begin
  THelpViewer.Show('uGestionCalendarios');
end;
```

Si el `.md` no existe, muestra "Ayuda no disponible para esta pantalla".

## Render Markdown -> HTML

Subset soportado (suficiente para ayuda de UI):

| Sintaxis MD          | HTML       |
|----------------------|------------|
| `# H1`               | `<h1>`     |
| `## H2`              | `<h2>`     |
| `### H3`             | `<h3>`     |
| `**bold**`           | `<b>`      |
| `*italic*`           | `<i>`      |
| `` `code` ``         | `<code>`   |
| `- item`             | `<ul><li>` |
| Linea en blanco      | `<p>`      |

No se soporta: tablas, imagenes, links, code blocks multilinea. Si se necesitan, extender el parser.

## Anadir ayuda a un nuevo form

1. Crear `Help/es/<UnitName>.md` con: Objetivo / Cuando usarlo / Pantalla / Operaciones frecuentes.
2. Anadir boton "?" a la cabecera del form (24x24, esquina sup-derecha).
3. OnClick: `THelpViewer.Show('UnitName');`.
4. Copiar el .md a `Win32/Debug/Help/es/` y `Win32/Release/Help/es/`.
