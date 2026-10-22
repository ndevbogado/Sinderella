# [Nombre del juego]

> Juego de rol desarrollado en equipo (4 personas, en tiempo libre) con **Godot 4.7.1** y **GDScript**.

**Estado del proyecto:** en desarrollo temprano · **Repositorio:** público (ver [reglas para repo público](docs/project_architecture.md#9-reglas-mientras-el-repositorio-sea-público))

---

## 1. Requisitos

| Herramienta | Versión | Notas |
|---|---|---|
| [Godot Engine](https://godotengine.org/download) | **4.7.1 stable** (versión estándar, *no* .NET) | Usar **exactamente** esta versión. Solo quien lidera el proyecto decide las actualizaciones. |
| [Git](https://git-scm.com/downloads) | Última estable | En Windows se instala junto con *Git Bash*. |
| Cliente de Git (opcional) | [GitHub Desktop](https://desktop.github.com/) | Recomendado si no te sentís cómodo con la terminal. |
| Editor de código (opcional) | Godot integrado o VS Code | VS Code: instalar la extensión *EditorConfig*. |

> ⚠️ **No abras el proyecto con otra versión de Godot.** Una versión distinta puede modificar los archivos de escenas y recursos y provocar conflictos para todo el equipo.

## 2. Primeros pasos

1. Clonar el repositorio:
   ```bash
   git clone <URL-del-repositorio>
   cd <nombre-del-repositorio>
   ```
2. Configurar Git (una sola vez, dentro del repositorio):
   ```bash
   git config core.autocrlf false
   git config core.longpaths true      # importante en Windows
   ```
3. Abrir Godot 4.7.1 → **Importar** → seleccionar `godot/project.godot`.
4. La primera vez, Godot tarda un poco en importar los recursos (genera la carpeta `.godot/`, que no se sube a Git).
5. Ejecutar el juego con **F5**.

## 3. Estructura del repositorio

```text
├── docs/          Documentación técnica (arquitectura, cómo trabajar)
├── tools/         Herramientas externas de desarrollo
├── _source/       Material de origen (conceptos, masters). Fuera de Godot
└── godot/         ← EL PROYECTO DE GODOT (res://)
    ├── addons/    Plugins
    ├── assets/    Arte, audio y fuentes finales
    ├── core/      Código compartido
    ├── data/      Datos fijos del juego (Resources .tres)
    ├── game/      Mapas, personajes, cinemáticas
    ├── systems/   Combate, inventario, guardado, IA, UI...
    ├── tools/     Scripts de editor
    └── tests/     Pruebas
```

Detalle completo y reglas de ubicación: [`docs/project_architecture.md`](docs/project_architecture.md).

## 4. Reglas básicas

- Nombres de archivos y carpetas en `snake_case`, sin espacios, sin acentos y sin mayúsculas (`health_potion.tres`).
- **Un solo editor por escena a la vez:** avisá por el chat antes de abrir una escena compartida.
- Siempre se suben los archivos `.import` y `.uid`. **Nunca** se sube la carpeta `.godot/`.
- Cada dato del juego (ítem, enemigo, habilidad...) tiene un **ID único y estable**. Nunca se renombra.
- El código usa **GDScript**. Solo se evaluará C# o C++ si hay un problema de rendimiento comprobado.
- **No subir material con licencia** (arte, música, fuentes de terceros) mientras el repositorio sea público.
- Cambios chicos y ramas cortas. Reglas de ramas y commits: [`CONTRIBUTING.md`](CONTRIBUTING.md).

## 5. Idioma

- **Documentación y comentarios:** español.
- **Código e identificadores** (variables, funciones, clases, IDs): inglés.

## 6. Documentación

| Tema | Dónde |
|---|---|
| Cómo está organizado el proyecto | [`docs/project_architecture.md`](docs/project_architecture.md) |
| Historia, universo y lore del juego | Notion (enlace interno del equipo) |
| Reglas de commits y ramas | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| Créditos y licencias de terceros | `LICENSES.md` *(pendiente)* |

## 7. Licencia

*Pendiente de definir.*
