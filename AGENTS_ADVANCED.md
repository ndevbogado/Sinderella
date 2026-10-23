# AGENTS_ADVANCED.md: Guía para agentes de IA (usuarios avanzados)

> **Versión:** 2 · **Fecha:** 22/10/2026 · **Mantiene:** quien lidera el proyecto
> Versión **completa** para personas que dominan Git y Godot. Las personas que recién empiezan usan [`AGENTS.md`](AGENTS.md) (versión simple).
> **Si un agente lee ambos archivos, este reemplaza a `AGENTS.md`.**

---

## Para el integrante del equipo: cómo usar este archivo

1. **Configurá tu herramienta de IA para que pida permiso antes de editar archivos** (casi todas tienen esa opción). Es la protección real de la regla de informe previo: las instrucciones por sí solas no son una garantía.
2. Al empezar una sesión, enviale este archivo a tu agente (adjunto o pegado) junto con este mensaje:

   ```text
   Leé AGENTS_ADVANCED.md y seguilo durante toda la sesión (reemplaza a AGENTS.md).
   Antes de empezar, confirmame en 5 líneas las reglas que más vas a respetar.
   No crees ni modifiques ningún archivo sin mostrarme antes un informe previo.
   ```
3. Revisá que el agente confirme, como mínimo: informe previo en español, `snake_case`, código en inglés, formato de commits y no tocar nada sin aprobación.
4. Si el agente se desvía de estas reglas, recordale: *"Seguí AGENTS_ADVANCED.md"*.
5. **Período de prueba (1 a 2 semanas):** anotá cada vez que el agente ignore o malinterprete una regla y avisale a quien lidera el proyecto. Con eso se mejora la versión siguiente.

Si tu agente trabaja dentro del repositorio, es posible que cargue `AGENTS.md` o `CLAUDE.md` por su cuenta. El mensaje de arriba le indica que use este archivo en su lugar.

---

## 0. Regla principal: informe previo (obligatoria)

**Antes de crear, modificar, mover, renombrar o eliminar cualquier archivo, y antes de ejecutar comandos que cambien algo, el agente DEBE presentar un informe en español y esperar la aprobación explícita de la persona.**

- **No necesitan informe:** leer archivos, buscar, explicar, analizar y responder preguntas (todo lo que no escribe ni cambia nada).
- **Sí necesitan informe:** cualquier cambio, aunque sea chico. Esta regla no se omite porque la tarea parezca simple.
- Hasta que la persona apruebe, el agente **no escribe ningún archivo**, ni siquiera temporal.
- El informe es un **resumen corto**: una lista de cambios que la persona pueda leer en un minuto, no un texto largo.
- Si durante la tarea aparece un cambio **no incluido** en el informe aprobado, el agente se detiene y presenta un informe nuevo con ese cambio.
- **Límite de tamaño:** un informe tiene **como máximo ~5 filas de cambios y una sola idea**. Si la tarea es más grande, el agente la **divide** en informes separados y empieza por el primero.

### Verificación previa (antes del primer informe de la sesión)

1. El agente pregunta **en qué rama está la persona** y pide el resultado de `git status` (¿hay cambios sin subir?).
2. Si la rama es `main` o `dev`, **no planifica cambios ahí**: propone crear una rama `feature/<area>-<descripcion>` o `fix/<area>-<descripcion>` primero.
3. Si hay cambios sin commitear que no pertenecen a la tarea, lo señala antes de seguir.

### Plantilla del informe previo

```text
## Informe previo

**Tarea:** (en una línea)
**Rama sugerida:** feature/<area>-<descripcion>   (o fix/...; si ya estoy en una, indicarlo)

| # | Acción | Archivo(s) | Qué cambia | Por qué |
|---|---|---|---|---|
| 1 | Crear / Modificar / Mover / Eliminar | ruta/del/archivo | resumen breve | motivo |

**Commits sugeridos** (uno por idea, en este orden):
1. `tipo(ámbito): descripción en español`   → cambios #1, #2
2. `tipo(ámbito): descripción en español`   → cambio #3

**Título sugerido para el Pull Request:** `tipo(ámbito): descripción`
**Texto sugerido para el Pull Request:** la tabla de cambios de arriba sirve como sección "Qué cambia" de la plantilla de PR; se agrega además "Cómo probarlo".

**Supuestos o dudas:** (lo que asumí o necesito que me confirmen)
**Riesgos o cosas que no puedo verificar:** (por ejemplo, "no puedo ejecutar Godot")
**No voy a tocar:** (archivos o áreas cercanas que quedan fuera)

¿Aprobás? Respondé:
- "aprobado"
- "aprobado 1 y 3; modificar 2: <cambio>"
- "rechazado"
```

### Después de la aprobación

1. El agente hace **solo** lo aprobado, tal como fue aprobado.
2. Al terminar, entrega un **informe final** corto con:
   - qué hizo y si algo difirió del informe aprobado;
   - qué **no pudo probar**;
   - una **autoverificación**: nombres en `snake_case`, sin nombres reservados de Windows, tabulaciones en GDScript, variables con tipo, sin texto del jugador dentro de scripts, `.uid` y `.import` movidos junto con su archivo (es una declaración del agente: no reemplaza la revisión);
   - la **lista final de commits sugeridos** con los archivos de cada uno (por ejemplo, `git add <archivos>`);
   - el **título y el texto sugeridos para el Pull Request**.
3. **El agente no ejecuta `git commit`, `git push`, `git merge` ni borra ramas**, salvo que la persona se lo pida expresamente. Por defecto solo **sugiere** los mensajes de commit.

### Commits sugeridos: reglas

- **Un commit = una idea.** Si el mensaje necesita "y", son dos commits.
- Cada cambio del informe debe quedar asignado a **un** commit sugerido, para poder seguir cada modificación en el historial.
- Formato en la sección 6.

---

## 1. Idioma

| Qué | Idioma |
|---|---|
| Informes, explicaciones y respuestas al equipo | **Español** |
| Documentación (`.md`, `docs/`) | **Español** |
| Comentarios en el código | **Español** |
| Código: variables, funciones, clases, señales, IDs de datos | **Inglés** |
| Nombres de archivos y carpetas | **Inglés**, en `snake_case` |
| Commits: prefijo | Inglés (fijo) |
| Commits: descripción | Español |
| Texto que ve el jugador | Inglés (el español se agrega después, ver sección 8) |

---

## 2. El proyecto en pocas líneas

- Juego de rol hecho por un **equipo de 4 personas en su tiempo libre**, con distinto nivel técnico. Hay que dar explicaciones claras y evitar suponer que la persona domina Git o Godot.
- **Motor:** Godot **4.7.1 stable** (versión estándar, no .NET). Solo quien lidera el proyecto decide actualizaciones.
- **Lenguaje:** **GDScript**. C# o C++ solo si hay un problema de rendimiento **medido**; no proponerlos por preferencia.
- **Sistemas operativos del equipo:** Linux (SteamOS, Ubuntu) y Windows.
- **Repositorio:** GitHub, **público por ahora**. Pasará a privado al incorporar material licenciado.
- **Notion:** contiene el lore y el universo del juego. El agente **no tiene acceso**: no inventar lore ni asumir detalles de la historia; preguntar.

---

## 3. Estructura y dónde va cada cosa

```text
repo/
├── README.md · CONTRIBUTING.md · LICENSES.md (pendiente)
├── AGENTS.md · AGENTS_ADVANCED.md · CLAUDE.md   reglas para agentes de IA
├── .gitignore · .gitattributes · .editorconfig · .github/
├── docs/              documentación técnica (docs/project_architecture.md) y docs/decisions/ (ADR)
├── tools/             herramientas EXTERNAS a Godot
├── _source/           material de origen (conceptos, masters, licenciado). FUERA de Godot
└── godot/             PROYECTO DE GODOT (esto es res://)
    ├── project.godot
    ├── addons/        plugins de terceros
    ├── assets/        art/ audio/ fonts/ : material FINAL
    ├── core/          código compartido (enums, constantes, bus de eventos, utilidades)
    ├── data/          datos fijos: items/ enemies/ skills/ quests/ dialogue/ character_classes/
    ├── game/          maps/ characters/ cinematics/
    ├── systems/       combat/ inventory/ save/ dialogue/ ai/ ui/
    ├── tools/         scripts de editor (validadores de datos)
    ├── tests/         pruebas
    └── _external/     contiene .gdignore: Godot no escanea esta carpeta
```

### Reglas de ubicación (en orden)

1. ¿Valor fijo que diseño puede editar? → `godot/data/`
2. ¿Código o escenas que aplican una regla? → `godot/systems/<sistema>/`
3. ¿Algo concreto del mundo (mapa, personaje)? → `godot/game/`
4. ¿Lo usan varios sistemas? → `godot/core/`
5. ¿Arte, sonido o fuente final? → `godot/assets/`
6. ¿Material de origen? → `_source/`

### Dependencias y organización

- Dirección: `data` ← `systems` ← `ui`; `core` lo pueden usar todos. `data/` no depende de ningún sistema.
- `systems/` **no conoce contenido específico** (el inventario no menciona "poción de vida").
- Los sistemas se comunican por **señales / bus de eventos** (en `core/`), no llamándose entre sí. Mantener los autoloads al mínimo.
- Scripts, escenas y recursos de una funcionalidad van **juntos** en su carpeta. No existen carpetas globales `scripts/` ni `scenes/`.

---

## 4. Convenciones

### Nombres

| Elemento | Convención | Ejemplo |
|---|---|---|
| Archivos y carpetas | `snake_case`, minúsculas, sin espacios ni acentos | `health_potion.tres` |
| Clases | `PascalCase` | `ItemData` |
| Variables y funciones | `snake_case` | `add_item()` |
| Señales | `snake_case`, en pasado | `item_added` |
| IDs de datos | `snake_case`, **estables** | `potion_small` |

- **No usar** nombres reservados de Windows (`con`, `prn`, `aux`, `nul`, `com1`–`com9`, `lpt1`–`lpt9`), ni los caracteres `: * ? " < > |`.
- Nunca dos archivos que difieran solo por mayúsculas.
- Seguir la [guía de estilo de GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html). Indentación con **tabulaciones**, fin de línea **LF**, codificación UTF-8.
- Usar **tipos explícitos** en GDScript (`var price: int`, `@export var ...`).

### Datos del juego: solo Resources

- Todos los datos fijos son **Resources personalizados** (`.tres`). **No se usa CSV.**
- Estructura: `godot/data/<tipo>/<tipo>_data.gd` (plantilla) y `godot/data/<tipo>/entries/<id>.tres` (instancias).
- Cada dato tiene un **ID único y estable**; el nombre del `.tres` coincide con el ID. **Un ID no se renombra.**
- Las **partidas guardadas almacenan solo IDs y cantidades**, nunca copias de los datos. El formato de guardado lleva **número de versión**.
- No escribir texto para el jugador dentro de scripts; va en los Resources.
- Al listar archivos en un juego exportado, pueden aparecer con sufijo `.remap`; el cargador de datos debe contemplarlo.

---

## 5. Godot: precauciones para agentes

- **No editar a mano** archivos `.tscn`, `.tres` ni `project.godot` salvo que la tarea lo pida. Si hace falta cambiar una escena, proponer los pasos para hacerlo desde el editor de Godot o hacerlo con código GDScript, e indicar el riesgo en el informe.
- Si se **mueve o renombra** un archivo: mover también su `.uid` y su `.import`, y actualizar las rutas `res://` que lo referencian. Indicarlo en el informe.
- **Nunca** tocar ni generar la carpeta `.godot/`.
- No mezclar **mover archivos** con **editar su contenido** en el mismo commit.
- El agente normalmente **no puede ejecutar Godot**: debe decir qué no pudo probar y qué debe verificar la persona abriendo el proyecto.
- Usar **solo funciones de Godot 4.7.1**. Si hay dudas sobre la API, decirlo y no inventar.
- Una persona por escena a la vez: avisar si el cambio toca escenas compartidas.

---

## 6. Git: ramas, commits y Pull Requests

### Ramas

```text
main  ← dev  ← feature/<area>-<descripcion>   |   fix/<area>-<descripcion>
```

- Nombres en **minúsculas con guiones**: `feature/inventory-stacking`, `fix/save-lost-quantity`.
- Nadie sube directo a `main` ni a `dev`. Todo entra por **Pull Request** hacia `dev`.
- La rama `develop` está **obsoleta** (archivada): no usarla ni proponerla.
- Antes de empezar, el agente debe **recordar** a la persona que actualice `dev` (`git pull`) y trabaje en una rama propia.

### Commits: `tipo(ámbito): descripción en español`

| Tipo | Uso |
|---|---|
| `feat` | Funcionalidad nueva |
| `fix` | Corrección de un error |
| `data` | Datos del juego (ítems, enemigos, habilidades...) |
| `art` | Arte |
| `audio` | Música y sonido |
| `docs` | Documentación |
| `refactor` | Reorganizar código sin cambiar lo que hace |
| `test` | Pruebas |
| `chore` | Mantenimiento: configuración, estructura, plugins |
| `release` | Versión estable en `main` |

- **Ámbito** (opcional): carpeta o sistema (`inventory`, `combat`, `save`, `dialogue`, `ai`, `ui`, `core`, `items`, `enemies`, `maps`, `characters`, `tools`, `tests`).
- **Descripción:** verbo en presente (*agrega, corrige, elimina, mueve*), una línea, hasta ~72 caracteres, **sin punto final**. Debe decir **qué** cambió y **dónde**.
- Ejemplo: `feat(inventory): agrega apilado de ítems con límite por stack`
- Si hace falta explicar el *por qué*, se agrega un cuerpo después de una línea en blanco.
- El título del **Pull Request** sigue el mismo formato (es obligatorio).

### Pull Requests

- Chicos y de un solo tema (revisables en 10 a 15 minutos).
- `feature/*` y `fix/*` → `dev` con **Squash and merge**. Revisa quien lidera el proyecto.
- Versiones estables: commit `release: v0.1.0 - descripción` + etiqueta `v0.1.0` (numeración `v0.MINOR.PATCH`).

### Comandos prohibidos sin consultar

`git push --force`, `git reset --hard`, `git rebase`. Para actualizar una rama se usa `git merge dev`.

---

## 7. Lo que nunca se hace

- Subir **material con licencia** o con derechos reservados (el repo es público).
- Subir **contraseñas, tokens, claves** o `export_credentials.cfg`, ni pedirlos.
- Subir `.godot/`, builds exportados (`.exe`, `.pck`, `.apk`) o la carpeta `_source/licensed/`.
- Crear carpetas nuevas de primer nivel o cambiar la estructura sin informe y aprobación.
- Cambiar la versión de Godot, agregar plugins o dependencias sin informe y aprobación explícita.
- Tomar decisiones de la sección 8: **se pregunta**, no se decide.

---

## 8. Decisiones pendientes (el agente no debe decidirlas)

| Tema | Estado |
|---|---|
| Formato de diálogos (Resources propios o plugin) | Pendiente |
| Sistema de traducción (idea: inglés y, de ser posible, español) | Pendiente |
| Framework de tests (GUT o gdUnit4) | Pendiente |
| Git LFS | Pendiente (desactivado) |
| Licencia del código | Pendiente |

Si una tarea depende de alguno de estos temas, el agente lo **señala en el informe** y propone opciones, sin elegir por su cuenta.

---

## 9. Prioridad de las instrucciones y mantenimiento

**Orden de prioridad si hay conflicto:**

1. Seguridad y las reglas de la sección 7.
2. La **regla de informe previo** (sección 0).
3. Las instrucciones de la persona en la sesión.
4. Este archivo.
5. Los documentos del repo: `docs/project_architecture.md`, `CONTRIBUTING.md` y los ADR de `docs/decisions/`.

Si este archivo y un documento del repo se contradicen, el agente **lo avisa** y pregunta antes de seguir.

**Mantenimiento:** este archivo y `AGENTS.md` resumen decisiones que viven en `docs/`. Cuando cambie la arquitectura, `CONTRIBUTING.md` o un ADR, se actualizan **los dos** y se sube la versión (la plantilla de Pull Request lo recuerda). Las decisiones sobre este flujo están en [`docs/decisions/0004-flujo-de-trabajo-con-agentes-de-ia.md`](docs/decisions/0004-flujo-de-trabajo-con-agentes-de-ia.md).
