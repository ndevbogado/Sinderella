# Arquitectura del proyecto

> **Estado:** v3 (decisiones del equipo incorporadas)
> **Motor:** Godot **4.7.1 stable** (estándar, GDScript) · las actualizaciones las decide quien lidera el proyecto
> **Última revisión:** 22/10/2026

Este documento explica **dónde va cada cosa** en el repositorio y **por qué**. Si dudás dónde poner un archivo, andá directo a la sección 4.

**Leyenda:** ✅ definido · 🆕 propuesta nueva a confirmar · ⏸️ reservado (decisión pendiente, no crear todavía)

---

## 1. Vista general

```text
repo/                              (raíz del repositorio)
├── README.md                      ✅ cómo abrir y correr el proyecto
├── CONTRIBUTING.md                ✅ ramas, commits y flujo de trabajo
├── LICENSES.md                    🆕 créditos de terceros (crear al incorporar material ajeno)
├── .gitignore                     ✅
├── .gitattributes                 ✅
├── .editorconfig                  ✅
│
├── .github/                       ✅ plantilla de Pull Request
├── docs/                          ✅ documentación técnica ("cómo trabajar con el proyecto")
│   └── decisions/                 ✅ registro de decisiones (ADR), una página por decisión
├── tools/                         ✅ herramientas EXTERNAS a Godot (scripts de Python, etc.)
├── _source/                       ✅ material de origen, FUERA del proyecto Godot
│   ├── concepts/                  (concept art, PSD, masters)
│   └── licensed/                  (material licenciado sin procesar; ignorado por Git, ver sección 9)
│
└── godot/                         ✅ PROYECTO DE GODOT (esta carpeta es res://)
    ├── project.godot
    ├── addons/                    ✅ plugins de terceros
    ├── assets/                    ✅ material FINAL que usa el juego
    │   ├── art/
    │   ├── audio/                 (música y sonido)
    │   └── fonts/
    ├── core/                      🆕 código compartido por todos los sistemas
    ├── data/                      ✅ datos fijos del juego (Resources .tres)
    │   ├── items/
    │   ├── enemies/
    │   ├── skills/
    │   ├── quests/
    │   ├── dialogue/              ⏸️ formato por definir
    │   └── character_classes/     🆕 (antes "classes")
    ├── game/                      ✅ contenido concreto del mundo
    │   ├── maps/
    │   ├── characters/
    │   └── cinematics/
    ├── systems/                   ✅ reglas del juego y datos mutables
    │   ├── combat/
    │   ├── inventory/
    │   ├── save/
    │   ├── dialogue/              ⏸️
    │   ├── ai/
    │   └── ui/
    ├── tools/                     🆕 scripts de editor (validadores de datos, etc.)
    ├── tests/                     ✅ pruebas (framework por definir)
    └── _external/                 🆕 contiene un .gdignore: Godot no escanea esta carpeta
```

**Por qué `godot/` es una subcarpeta:** todo lo que está dentro de `godot/` es visible para el motor. Lo que queda afuera (`_source/`, `docs/`, `tools/`) **nunca** se importa ni se exporta, así que los archivos pesados de arte no ralentizan el editor.

**Carpetas que todavía no se crean:** `localization/` (se agrega cuando se defina el sistema de traducción) y las de diálogo (⏸️), hasta decidir el formato.

---

## 2. Qué hace cada carpeta

| Carpeta | Propósito | La usa más | Entra al juego exportado |
|---|---|---|---|
| `docs/` | Documentación técnica que cambia junto con el código | Todos | No |
| `tools/` (raíz) | Scripts externos a Godot | Programación | No |
| `_source/` | Conceptos, masters y material sin procesar | Arte | No |
| `godot/addons/` | Plugins de terceros (convención de Godot) | Programación | Según plugin |
| `godot/assets/` | Arte, audio y fuentes **finales** | Arte, audio | Sí |
| `godot/core/` | Enums, constantes, bus de eventos, clases base, utilidades | Programación | Sí |
| `godot/data/` | Datos fijos: ítems, enemigos, habilidades, misiones, clases | Diseño, programación | Sí |
| `godot/game/` | Mapas, personajes, cinemáticas | Diseño, arte | Sí |
| `godot/systems/` | Funcionalidad y datos que cambian durante la partida | Programación | Sí |
| `godot/tools/` | Scripts que corren dentro del editor (validadores) | Programación | No conviene exportarlos |
| `godot/tests/` | Pruebas automáticas | Programación | No |
| `godot/_external/` | Material que Godot no debe escanear (tiene `.gdignore`) | Quien lo necesite | No |

> **`tools/` vs `godot/tools/`:** si el script corre *dentro* del editor de Godot (por ejemplo un validador de datos), va en `godot/tools/`. Si corre *fuera* (Python, shell), va en `tools/`.

---

## 3. Notion y repositorio: qué va dónde ✅

| Lugar | Contenido |
|---|---|
| **Notion** | Lore y universo del juego |
| **`docs/` del repo** | Cómo trabajar con el proyecto: arquitectura, convenciones, formatos de datos, guías por sistema |

Regla práctica: si el texto tiene que actualizarse **junto con un cambio de código o de estructura**, va en el repo.

---

## 4. Reglas de ubicación 🆕

Respondé en orden:

1. ¿Es un **valor fijo que diseño puede editar** (daño de una espada, precio de una poción)? → `godot/data/`
2. ¿Es **código o escenas que aplican una regla** (cómo se apila un ítem, cómo se calcula el daño)? → `godot/systems/<sistema>/`
3. ¿Es **algo concreto que existe en el mundo** (el mapa del pueblo, el héroe)? → `godot/game/`
4. ¿Lo usan **varios sistemas** (enums, constantes, utilidades)? → `godot/core/`
5. ¿Es **arte, sonido o fuente lista para usar**? → `godot/assets/`
6. ¿Es **material de origen** (PSD, concept art, original licenciado)? → `_source/`

### Dirección de dependencias

```text
data  ←  systems  ←  ui
  ↑         ↑
  └─ core ──┘
```

- `data/` no depende de ningún sistema.
- `systems/` lee `data/`, pero **no conoce contenido específico** (el inventario no menciona "poción de vida").
- `ui` muestra lo que dicen los sistemas, usando **señales**, sin cambiar su lógica.
- Los sistemas se comunican por **señales / bus de eventos** (en `core/`), no llamándose directamente.

### Scripts y escenas juntos

Cada funcionalidad guarda sus scripts, escenas y recursos en la **misma carpeta**:

```text
godot/systems/inventory/
├── inventory.gd
├── inventory_screen.tscn
└── inventory_slot.tscn
```

No se usan carpetas globales `scripts/` ni `scenes/`.

---

## 5. Datos del juego: solo Resources ✅

Todos los datos fijos son **Resources personalizados de Godot** (`.tres`), editables desde el inspector.

### Estructura propuesta 🆕

```text
godot/data/items/
├── item_data.gd            ← define los campos (la "plantilla")
└── entries/
    ├── potion_small.tres   ← un ítem concreto
    └── iron_sword.tres
```

Mismo patrón para `enemies/`, `skills/`, `quests/` y `character_classes/`.

### Reglas

- Cada dato tiene un **ID string único y estable** (`potion_small`). El nombre del archivo `.tres` **coincide** con su ID.
- **Un ID no se renombra.** Si hay que cambiarlo, se crea uno nuevo y el viejo se marca como obsoleto.
- Las **partidas guardadas almacenan solo IDs y cantidades** (`"potion_small": 3`), nunca una copia del ítem.
- El formato de guardado lleva un **número de versión** y una función de migración.
- Los campos de los Resources usan **tipos explícitos** (`@export var price: int`) para que el editor los valide.
- Evitar escribir texto para el jugador dentro de scripts: va en los Resources (facilita traducir después).
- Un **validador** (en `godot/tools/`) revisará IDs duplicados y referencias rotas. Se escribe junto con el primer Resource del inventario.

### Para tener en cuenta al construir el cargador de datos

En un juego exportado, al listar carpetas con `DirAccess` los archivos pueden aparecer con sufijo `.remap`. El cargador de datos (que arma el diccionario `id → Resource`) debe contemplarlo. Se resuelve al implementar el inventario.

---

## 6. Convenciones de nombres 🆕

| Elemento | Convención | Ejemplo |
|---|---|---|
| Carpetas y archivos | `snake_case`, sin espacios, acentos ni mayúsculas | `health_potion.tres` |
| Clases (GDScript) | `PascalCase` | `ItemData` |
| Variables y funciones | `snake_case` | `add_item()` |
| IDs de datos | `snake_case`, estables | `potion_small` |
| Señales | `snake_case`, en pasado | `item_added` |

Guía oficial de estilo: [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).

**Idioma** 🆕: documentación y comentarios en **español**; código e identificadores en **inglés**.

---

## 7. Equipo en Linux y Windows 🆕

Parte del equipo trabaja en Linux (SteamOS / Ubuntu) y parte en Windows. Estas diferencias causan errores difíciles de ver:

| Problema | Regla |
|---|---|
| Linux distingue mayúsculas, Windows no (`Player.png` ≠ `player.png` solo en Linux) | Todo en minúsculas. Nunca dos archivos que difieran solo por mayúsculas. |
| Windows prohíbe ciertos nombres de archivo | No usar `con`, `prn`, `aux`, `nul`, `com1`–`com9`, `lpt1`–`lpt9` (ni con extensión, como `aux.gd`). |
| Windows prohíbe ciertos caracteres | No usar `: * ? " < > \|` en nombres. |
| Rutas largas en Windows | Evitar anidar carpetas en exceso. Cada persona de Windows ejecuta `git config core.longpaths true`. |
| Saltos de línea (LF vs CRLF) | El repo usa **LF** siempre (lo fuerza `.gitattributes`). Cada persona ejecuta `git config core.autocrlf false`. |
| Permisos de ejecución (scripts `.sh`) | Quien los crea en Linux los sube ya marcados como ejecutables. |

---

## 8. Lenguaje de programación ✅

- **GDScript** para todo el juego.
- **C#** o **C++ (GDExtension)** solo si hay un problema de rendimiento **medido** en un sistema concreto. En ese caso se registra la decisión en `docs/decisions/`.
- Nota: usar C# implica cambiar a la versión **.NET** de Godot para todo el equipo. Es una decisión de impacto grande, no un cambio local.

---

## 9. Reglas mientras el repositorio sea público ✅

El repositorio es **público por ahora**. Cuando se incorpore material con licencia, pasará a **privado**.

- **No subir** material licenciado ni con derechos reservados, ni siquiera "para probar". Lo que se sube a un repo público **queda en el historial** aunque después se borre o el repo pase a privado, y quien lo clonó o hizo un fork conserva una copia.
- Material licenciado sin procesar: `_source/licensed/` (ignorado por Git mientras sea público).
- **Nunca** subir claves, tokens ni credenciales de exportación.
- Antes de pasar a privado: revisar el historial en busca de material que no debía estar y, si lo hay, limpiarlo **antes** del cambio.
- Al pasar a privado: borrar el bloque "Material licenciado" del `.gitignore` y evaluar activar Git LFS (hay cuotas de almacenamiento en repos privados).
- Material gratuito con licencia que exige crédito (CC-BY u otras): registrarlo en `LICENSES.md`.

---

## 10. Trabajo en equipo ✅

- **Un solo editor por escena** a la vez: avisar por el chat antes de abrir una escena compartida.
- Preferir **muchas escenas chicas** combinadas, en lugar de una escena gigante.
- Ramas cortas y cambios chicos. La rama `main` queda protegida.
- Siempre se suben los archivos `.import` y `.uid`; **nunca** la carpeta `.godot/`.
- Las decisiones importantes se registran en `docs/decisions/` (contexto, decisión, consecuencias).
- Las reglas de ramas y commits están en `CONTRIBUTING.md`.

---

## 11. Decisiones

### Cerradas

| # | Decisión | Resolución |
|---|---|---|
| 1 | Raíz del proyecto Godot | Subcarpeta `godot/` |
| 2 | Formato de datos | Solo Resources (`.tres`) |
| 3 | Versión de Godot | 4.7.1 stable; las actualizaciones las decide quien lidera el proyecto |
| 4 | Idiomas | Inglés y, de ser posible, español (sistema de traducción pendiente) |
| 5 | Notion vs repo | Notion: lore. Repo: cómo trabajar con el proyecto |
| 6 | Visibilidad del repo | Público por ahora; pasa a privado al incorporar material licenciado |
| 7 | Material de origen | `_source/` en la raíz, fuera de Godot |
| 8 | Idioma de documentación | Español |
| 9 | Lenguaje principal | GDScript |

### Pendientes (no bloquean el inventario)

| # | Pregunta | Cuándo |
|---|---|---|
| A | Formato de diálogos (Resources propios o plugin) | Al llegar a esa etapa |
| B | Sistema de traducción (hoy solo la idea de EN + ES) | Antes de escribir textos masivos |
| C | Framework de tests (GUT o gdUnit4) | Al escribir los primeros tests |
| D | Git LFS | Al pasar a privado o al crecer el peso del repo |
| E | Licencia del código | Cuando se decida el futuro del proyecto |
| F | Idioma de comentarios en código (propuesto: español) | Confirmar |

---

## 12. Cambios respecto a la v2

- Todo el proyecto Godot pasa a `godot/`; `_source/`, `docs/` y `tools/` quedan afuera.
- Se elimina CSV: los datos son Resources. Cada tipo de dato tiene su plantilla `.gd` y sus `entries/`.
- `localization/` y el formato de diálogos quedan reservados.
- Nuevas secciones: equipo Linux/Windows, lenguaje, reglas para repo público.
- `godot/tools/` para scripts de editor; `tools/` queda para herramientas externas.
- `godot/_external/` con `.gdignore` como carpeta oculta para el motor.
