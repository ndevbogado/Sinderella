# AGENTS.md: Guía simple para tu agente de IA

> **Versión:** 2 · **Fecha:** 22/10/2026 · **Mantiene:** quien lidera el proyecto
> Esta es la versión **para quienes recién empiezan** con Git y Godot. Si ya dominás ambos, usá [`AGENTS_ADVANCED.md`](AGENTS_ADVANCED.md).

---

## Para vos (la persona del equipo): cómo usar esta guía

1. En la configuración de tu herramienta de IA, activá la opción que **pide permiso antes de editar archivos**. Es tu mejor protección.
2. Al empezar a trabajar, enviale este archivo a tu agente (adjunto o pegado) y escribí este mensaje:

   ```text
   Leé AGENTS.md y seguilo durante toda la sesión.
   Soy principiante: explicame todo en simple y en español.
   No crees ni cambies ningún archivo sin mostrarme antes un informe y esperar mi "sí".
   ```
3. Si el agente se olvida de las reglas, escribile: *"Seguí AGENTS.md"*.
4. Durante las primeras 1 o 2 semanas, anotá cuando el agente **no haga caso** a una regla y avisale a quien lidera el proyecto. Así mejoramos esta guía.
5. Si algo no se entiende, **preguntá**. No hay preguntas tontas.

---

## 1. Reglas para el agente (lo más importante)

### 1.1 Cómo hablar

- Siempre en **español**, con palabras simples y oraciones cortas.
- **No asumir** que la persona sabe de Git, Godot o programación. Si usás un término técnico (rama, commit, Pull Request, escena, recurso), explicalo en una frase la primera vez.
- Dar los pasos **de a uno** y con ejemplos concretos.
- Si algo no está claro, **preguntar** (máximo 2 preguntas a la vez). **No inventar** ni adivinar.

### 1.2 Antes de cambiar cualquier cosa: hacer un informe y pedir permiso

**El agente NO puede crear, modificar, mover, renombrar ni borrar archivos, ni ejecutar comandos que cambien algo, hasta que la persona responda "sí".**

- Leer archivos, buscar y explicar **no necesita permiso**.
- Cualquier cambio **sí** lo necesita, aunque sea chico.
- Si durante el trabajo aparece un cambio que **no estaba en el informe**, el agente se detiene y hace un informe nuevo.
- **Una cosa por vez:** si la tarea tiene más de 5 cambios o más de un objetivo, el agente la divide en partes y empieza por la primera.

### 1.3 Chequeo antes de empezar

Antes del primer informe, el agente le pregunta a la persona:

1. ¿En qué **rama** estás? (en GitHub Desktop aparece arriba, en "Current Branch"; en terminal: `git branch --show-current`)
2. ¿Tenés **cambios sin guardar** (commit)?

Si la rama es `main` o `dev`, **no se trabaja ahí**: el agente explica cómo crear una rama propia, paso a paso (ver sección 4).

### 1.4 El informe (formato simple)

```text
## Informe: antes de empezar

**Qué voy a hacer:** (2 o 3 oraciones, en palabras simples)

**Cambios que voy a hacer:**
1. Crear el archivo `godot/data/items/item_data.gd` : define qué datos tiene un ítem.
2. Modificar `godot/systems/inventory/inventory.gd` : agrega la función para sumar ítems.

**Lo que NO voy a tocar:** (por ejemplo, "no toco ninguna escena")

**Cosas que no puedo comprobar:** (por ejemplo, "no puedo abrir Godot para probarlo")

**Mensajes de commit sugeridos** (para guardar estos cambios en Git):
1. `feat(inventory): agrega datos básicos de ítems`   → cambio 1
2. `feat(inventory): agrega función para sumar ítems` → cambio 2

**¿Seguimos?** Respondé:
- **Sí** → lo hago tal cual
- **No** → no hago nada
- **Cambiar: ...** → decime qué cambiar y lo ajusto
```

### 1.5 Cuando terminó el trabajo

El agente muestra un **resumen corto**:

1. Qué hizo (y si algo salió distinto al informe).
2. **Qué tenés que probar vos** en Godot, paso a paso (el agente casi nunca puede ejecutar Godot).
3. Que revisó lo básico: nombres de archivos en `snake_case`, sin nombres prohibidos, y que no tocó archivos de más.
4. Los **commits sugeridos**, listos para copiar, y cómo hacerlos (ver sección 4).
5. Un **título y un texto sugeridos para el Pull Request**.

**El agente NO guarda (commit), NO sube (push) ni une ramas (merge) por su cuenta.** Solo lo hace si la persona se lo pide de forma explícita.

---

## 2. El proyecto en pocas líneas

- Es un **juego de rol** hecho por **4 personas en su tiempo libre**, con distintos niveles técnicos.
- Se hace con **Godot 4.7.1** (versión estándar) y el lenguaje **GDScript**. No se cambia la versión de Godot sin permiso de quien lidera el proyecto. No usar C# ni C++.
- El equipo trabaja en **Windows** y **Linux**.
- El código está en **GitHub** y es **público** por ahora: todo lo que se sube lo puede ver cualquiera.
- La historia y el universo del juego están en **Notion**. El agente **no tiene acceso**: no debe inventar la historia, debe preguntar.

---

## 3. Reglas del proyecto

### 3.1 Idiomas

| Qué | Idioma |
|---|---|
| Lo que le explicás a la persona | Español |
| Documentos (`.md`) | Español |
| Comentarios dentro del código | Español |
| Nombres en el código (variables, funciones, clases, señales) | **Inglés** |
| Nombres de archivos y carpetas | **Inglés** en `snake_case` |
| Mensajes de commit | Prefijo en inglés + descripción en español |

### 3.2 Nombres de archivos y carpetas

- Todo en **minúsculas**, con guiones bajos, **sin espacios y sin acentos**: `health_potion.tres`, `inventory_screen.tscn`.
- **No usar** los nombres `con`, `prn`, `aux`, `nul`, `com1` a `com9`, `lpt1` a `lpt9` (Windows no los permite), ni los caracteres `: * ? " < > |`.
- Nunca dos archivos que se diferencien solo por mayúsculas.

### 3.3 Nombres dentro del código

| Qué | Cómo | Ejemplo |
|---|---|---|
| Clases | `PascalCase` | `ItemData` |
| Variables y funciones | `snake_case` | `add_item()` |
| Señales | `snake_case`, en pasado | `item_added` |
| IDs de datos | `snake_case`, para siempre iguales | `potion_small` |

- Indentación con **tabulaciones**. Variables con **tipo** (`var price: int`).
- El texto que ve el jugador **no se escribe dentro de los scripts**: va en los datos.

### 3.4 Dónde va cada archivo

```text
repo/
├── docs/        documentación técnica y decisiones (docs/decisions/)
├── tools/       herramientas externas a Godot
├── _source/     material de origen (conceptos, PSD, licenciado). NO es parte de Godot
└── godot/       EL PROYECTO DE GODOT
    ├── addons/    plugins
    ├── assets/    arte, audio y fuentes ya listos (art/ audio/ fonts/)
    ├── core/      código que usan todos los sistemas
    ├── data/      datos fijos del juego (items, enemies, skills, quests, dialogue, character_classes)
    ├── game/      mapas, personajes, cinemáticas
    ├── systems/   las reglas del juego (combat, inventory, save, dialogue, ai, ui)
    ├── tools/     scripts que corren dentro del editor
    ├── tests/     pruebas
    └── _external/ carpeta que Godot ignora
```

**¿Dónde pongo este archivo?** Preguntate en este orden:

1. ¿Es un **valor fijo** que se puede cambiar sin programar (daño de una espada)? → `godot/data/`
2. ¿Es **código o pantallas** que hacen funcionar una regla (cómo se suman ítems)? → `godot/systems/<sistema>/`
3. ¿Es **algo del mundo** (un mapa, un personaje)? → `godot/game/`
4. ¿Lo usan **varios sistemas**? → `godot/core/`
5. ¿Es arte, sonido o fuente **ya listo**? → `godot/assets/`
6. ¿Es material de origen? → `_source/`

Los scripts y las escenas de una misma funcionalidad van **juntos en su carpeta**. No hay carpetas `scripts/` ni `scenes/` generales.

**No crear carpetas nuevas de primer nivel** sin informe y permiso.

### 3.5 Datos del juego

- Los datos son **Resources de Godot** (archivos `.tres`). **No se usa CSV.**
- Cada tipo de dato tiene una **plantilla** (`item_data.gd`) y sus **entradas** (`entries/potion_small.tres`).
- Cada dato tiene un **ID único que nunca cambia**, y el archivo se llama igual que el ID.
- Las partidas guardadas guardan **solo IDs y cantidades**, nunca copias de los datos.

### 3.6 Cuidados con Godot

- **No editar a mano** los archivos `.tscn` (escenas), `.tres` ni `project.godot`, salvo que la tarea lo pida. Si hay que cambiar una escena, el agente le explica a la persona cómo hacerlo en el editor de Godot, paso a paso.
- Si se **mueve o renombra** un archivo, hay que mover también sus archivos compañeros `.uid` y `.import`, y avisar en el informe.
- Los archivos `.uid` y `.import` **sí se suben** a Git. La carpeta `.godot/` **nunca** se toca ni se sube.
- Mover archivos y editarlos van en commits **separados**.
- Si el cambio toca una escena que usa otra persona, avisar: **una persona por escena a la vez**.

### 3.7 Lo que nunca se hace

- Subir **material con licencia** (arte, música, fuentes de otros). El repositorio es público.
- Subir **contraseñas, claves o tokens**, ni pedirlos.
- Subir builds exportados (`.exe`, `.pck`, `.apk`) ni la carpeta `_source/licensed/`.
- Cambiar la versión de Godot, instalar plugins o agregar dependencias sin informe y permiso.
- Usar comandos peligrosos: `git push --force`, `git reset --hard`, `git rebase`.
- **Decidir por su cuenta** los temas de la sección 5.

---

## 4. Git paso a paso (para explicarle a la persona)

**Glosario simple**

| Palabra | Qué es |
|---|---|
| **Rama** | Una copia de trabajo propia, para no romper lo que usa el resto |
| **Commit** | Un "punto de guardado" con un mensaje que explica el cambio |
| **Push** | Subir tus commits a GitHub |
| **Pull Request (PR)** | Un pedido para que tu rama se una a `dev` después de que quien lidera el proyecto la revise |

### Ramas

```text
main  ←  dev  ←  feature/<area>-<descripcion>   o   fix/<area>-<descripcion>
```

- Nombres en **minúsculas con guiones**: `feature/inventory-stacking`, `fix/save-lost-quantity`.
- **Nadie sube directo a `main` ni a `dev`.** Todo se une por Pull Request hacia `dev`.
- La rama `develop` está **obsoleta**: no usarla.

### Flujo de trabajo (los 7 pasos)

| # | Paso | GitHub Desktop | Terminal |
|---|---|---|---|
| 1 | Actualizar `dev` | Current Branch → `dev` → Fetch / Pull | `git switch dev` y `git pull` |
| 2 | Crear tu rama | Branch → New Branch | `git switch -c feature/inventory-stacking` |
| 3 | Trabajar y guardar seguido (commit) | Tildar archivos → escribir el título → Commit | `git add <archivos>` y `git commit -m "..."` |
| 4 | Subir tu rama (la primera vez) | Publish branch | `git push -u origin feature/inventory-stacking` |
| 5 | Traer lo nuevo de `dev` a tu rama | Branch → Update from dev | `git switch dev`, `git pull`, `git switch feature/...`, `git merge dev` |
| 6 | Abrir el Pull Request hacia `dev` | Create Pull Request | En GitHub |
| 7 | Después de unirse, borrar la rama | — | Botón "Delete branch" en GitHub |

### Mensajes de commit

Formato: **`tipo(ámbito): descripción en español`**

| Tipo | Se usa para |
|---|---|
| `feat` | Una funcionalidad nueva |
| `fix` | Arreglar un error |
| `data` | Datos del juego (ítems, enemigos...) |
| `art` | Arte |
| `audio` | Música y sonido |
| `docs` | Documentos |
| `refactor` | Ordenar código sin cambiar lo que hace |
| `test` | Pruebas |
| `chore` | Mantenimiento (configuración, estructura) |

- **Ámbito** (opcional): la carpeta o sistema, como `inventory`, `combat`, `save`, `ui`, `items`, `maps`.
- **Descripción:** un verbo en presente (*agrega, corrige, elimina, mueve*), una sola línea, **sin punto final**, que diga **qué** cambió y **dónde**.
- **Un commit = una idea.** Si el mensaje necesita la palabra "y", son dos commits.
- Ejemplo: `feat(inventory): agrega apilado de ítems con límite por stack`
- El **título del Pull Request** usa el mismo formato.

### Si hay un conflicto al unir ramas

Un conflicto aparece cuando dos personas cambiaron lo mismo. **No se pierde nada.**

- El agente le dice a la persona que **cierre Godot** y que **no siga a ciegas**.
- Se puede cancelar todo con `git merge --abort`.
- Archivos de escenas o recursos (`.tscn`, `.tres`): **no se arreglan a mano**. Se pide ayuda a quien lidera el proyecto, con una captura.

---

## 5. Temas que todavía no se decidieron

El agente **no debe elegir** por su cuenta. Si la tarea depende de alguno, lo avisa en el informe y ofrece opciones.

| Tema | Estado |
|---|---|
| Cómo se escriben los diálogos | Pendiente |
| Sistema de traducción (idea: inglés y, si se puede, español) | Pendiente |
| Herramienta de pruebas (GUT o gdUnit4) | Pendiente |
| Git LFS (archivos pesados) | Pendiente |
| Licencia del código | Pendiente |

---

## 6. Si hay dudas entre reglas

1. La seguridad y la sección 3.7 van **primero**.
2. Después, la regla del **informe antes de cambiar** (sección 1.2).
3. Después, lo que pida la persona.
4. Después, esta guía y los documentos del repo (`docs/project_architecture.md`, `CONTRIBUTING.md`).

Si esta guía y un documento del repo se contradicen, el agente **lo avisa y pregunta**.
