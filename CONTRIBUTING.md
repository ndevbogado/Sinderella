# Cómo contribuir: ramas, commits y flujo de trabajo

> **Estado:** v1 · **Última revisión:** 22/10/2026
> Reemplaza al documento original `commit_rules_and_hierarchy.md`.

Este documento explica **cómo subir cambios** al repositorio. Si es tu primera vez, leé la sección 1 y la sección 6 (flujo diario) y listo.

**Leyenda:** ✅ regla definida · 🆕 cambio respecto a las reglas originales

---

## 1. Resumen en 30 segundos

1. Antes de empezar: `dev` actualizada.
2. Creá una **rama propia** a partir de `dev`: `feature/<nombre-corto>`.
3. Hacé **commits chicos** con este formato: `tipo(ámbito): descripción en español`.
4. Subí tu rama y abrí un **Pull Request** hacia `dev`.
5. Nunca subas directo a `main` ni a `dev`.

```text
feat(inventory): agrega apilado de ítems con límite por stack
```

---

## 2. Jerarquía de ramas ✅

```text
main                                  producción: versiones estables
 └── dev                              🆕 integración: todo lo nuevo se junta acá
      ├── feature/<nombre>            una funcionalidad nueva
      ├── fix/<nombre>                🆕 corrección de un error
      └── ...
```

| Rama | Para qué sirve | Quién escribe | Cómo entra |
|---|---|---|---|
| `main` | Versiones **estables** del juego. Cada punto de `main` se puede jugar. | Nadie directo | Pull Request desde `dev`, solo al alcanzar un hito |
| `dev` | Rama principal de trabajo. Contiene lo último ya revisado. | Nadie directo | Pull Request desde `feature/*` o `fix/*` |
| `feature/*` | Una funcionalidad o conjunto de cambios de **una persona**. | Quien la creó | Se crea desde `dev` |
| `fix/*` 🆕 | Corrección de un error. | Quien la creó | Se crea desde `dev` |

**Antes de cada sesión de trabajo:** actualizar `dev` (`git pull`) para partir de lo último y evitar conflictos.

### Nombres de ramas 🆕

- Todo en **minúsculas**, con **guiones** (`-`), sin espacios, sin acentos y sin mayúsculas.
- Formato: `feature/<área>-<descripcion-corta>` o `fix/<área>-<descripcion-corta>`.
- Ejemplos: `feature/inventory-stacking`, `fix/save-lost-quantity`.
- Motivo: Windows no distingue mayúsculas y Linux sí, así que `Feature/Inventario` y `feature/inventario` pueden chocar.

### Vida de una rama 🆕

Las ramas `feature/*` y `fix/*` son **cortas**: idealmente se terminan en pocos días. Una rama que vive semanas acumula conflictos. Si una funcionalidad es grande, dividila en partes que se puedan integrar por separado. Al integrarse, la rama se **borra**.

---

## 3. Mensajes de commit ✅ (formato híbrido)

**Prefijo en inglés (fijo) + descripción en español (libre).**

```text
tipo(ámbito): descripción
```

### Tipos

| Tipo | Cuándo se usa | Ejemplo |
|---|---|---|
| `feat` | Funcionalidad nueva | `feat(inventory): agrega apilado de ítems` |
| `fix` | Corrección de un error | `fix(save): corrige pérdida de cantidad al cargar` |
| `data` | Agregar o modificar datos del juego (ítems, enemigos, habilidades...) | `data(items): agrega poción pequeña y espada de hierro` |
| `art` | Arte (sprites, UI, mapas visuales) | `art(characters): agrega sprites de caminata del héroe` |
| `audio` | Música y sonido | `audio: agrega música del pueblo` |
| `docs` | Documentación | `docs: actualiza README con pasos para Windows` |
| `refactor` | Reorganizar código **sin cambiar** lo que hace | `refactor(combat): separa cálculo de daño en su propia función` |
| `test` | Pruebas | `test(inventory): agrega prueba de apilado` |
| `chore` | Mantenimiento: configuración, estructura, plugins | `chore: mueve el proyecto a la carpeta godot/` |
| `release` | Versión estable en `main` (ver sección 8) | `release: v0.1.0 - inventario y combate básico` |

### Ámbito (entre paréntesis, opcional)

Es la carpeta o sistema afectado: `inventory`, `combat`, `save`, `dialogue`, `ai`, `ui`, `core`, `items`, `enemies`, `maps`, `characters`, `tools`, `tests`. Si el cambio toca varias cosas, se omite.

### Reglas de la descripción

- En **español**, con el verbo en presente: *agrega, corrige, elimina, renombra, mueve, actualiza*.
- **Una línea**, máximo ~72 caracteres, **sin punto final**.
- Tiene que decir **qué** cambió y **dónde**. Si alguien lee solo el título, debe entender.
- Si hace falta explicar **por qué**, se deja una línea en blanco y se escribe un párrafo debajo.

```text
fix(save): corrige pérdida de cantidad al cargar partida

La cantidad se guardaba como texto y se convertía a 0 al cargar.
Ahora se guarda como entero.
```

### Ejemplos

| ✅ Bien | ❌ Mal |
|---|---|
| `feat(combat): agrega registro básico de vida y ataque` | `cambios` |
| `fix(ui): corrige que el inventario no abre con Esc` | `arreglos varios` |
| `data(enemies): agrega slime y murciélago` | `actualización` |
| `chore: agrega .gitignore y .editorconfig` | `subo todo lo que hice` |

### Historial existente

No se reescribe. Las reglas valen **desde ahora**.

---

## 4. Qué entra en un commit 🆕

El problema más común es el commit gigante con mensaje genérico. Reglas para evitarlo:

- **Un commit = una idea.** Si tu mensaje necesita la palabra "y" (`agrega inventario y arregla guardado`), son dos commits.
- **Commiteá seguido**, aunque el cambio sea chico. Es más fácil deshacer y revisar.
- Si ya acumulaste muchos cambios, **dividilos**: en GitHub Desktop destildá los archivos que no corresponden; en terminal usá `git add <archivo>`.
- **Antes de commitear, mirá la lista de archivos cambiados.** Si hay archivos que no tocaste, no los incluyas y preguntá.

### Reglas específicas de Godot

| Regla | Motivo |
|---|---|
| Se suben siempre los archivos `.import` y `.uid`, junto con su archivo. | Guardan la configuración de importación y las referencias entre archivos. |
| **Nunca** se sube la carpeta `.godot/`. | Es caché local. Ya está en `.gitignore`. |
| Mover o renombrar archivos **solo desde el panel FileSystem de Godot**. | Así Godot actualiza las referencias. Hacerlo desde el explorador rompe escenas. |
| No mezclar mover archivos con editar su contenido en el mismo commit. | Git detecta mejor los movimientos y se conserva el historial. |
| Si cambiaron muchas escenas o `project.godot` y **no los tocaste**, no los subas. Avisá. | Suele ser una versión distinta de Godot o un re-guardado automático. |
| **Una persona por escena a la vez.** Avisá por el chat. | Las escenas `.tscn` se fusionan mal. |
| Cerrá Godot (o recargá el proyecto) después de `git pull` o `git switch`. | Godot puede no enterarse de los cambios y sobrescribirlos. |
| Usar **exactamente** la versión de Godot del README. | Otra versión reescribe los archivos. |

---

## 5. Qué no se sube nunca 🆕

- Material con licencia o con derechos reservados (el repo es **público**, ver `docs/project_architecture.md`, sección 9).
- Contraseñas, tokens, claves o `export_credentials.cfg`.
- La carpeta `.godot/`.
- Builds exportados (`.exe`, `.pck`, `.apk`).

---

## 6. Flujo de trabajo diario ✅

Podés hacerlo con la terminal o con **GitHub Desktop** (recomendado para empezar).

### Paso a paso

| # | Paso | Terminal | GitHub Desktop |
|---|---|---|---|
| 1 | Ir a `dev` y actualizarla | `git switch dev` → `git pull` | Current Branch → `dev` → Fetch/Pull origin |
| 2 | Crear tu rama | `git switch -c feature/inventory-stacking` | Branch → New Branch |
| 3 | Trabajar y commitear seguido | `git add <archivos>` → `git commit -m "feat(inventory): ..."` | Tildar archivos → escribir el título → Commit |
| 4 | Subir la rama (la primera vez) | `git push -u origin feature/inventory-stacking` | Publish branch |
| 5 | Traer lo nuevo de `dev` a tu rama | `git switch dev` → `git pull` → `git switch feature/...` → `git merge dev` | Branch → Update from dev |
| 6 | Abrir el Pull Request hacia `dev` | En GitHub | Create Pull Request |
| 7 | Tras integrar, borrar la rama | Botón *Delete branch* en GitHub | — |

**Hacé el paso 5 seguido**, sobre todo antes de abrir el Pull Request.

### Si algo sale mal

Frená y preguntá antes de probar comandos que no conocés. En Git casi todo tiene arreglo, pero algunos comandos (como `git reset --hard` o `git push --force`) pueden borrar trabajo de forma definitiva.

---

## 7. Pull Requests 🆕

### Reglas

- **Todo cambio entra a `dev` por Pull Request.** Sin excepciones.
- El **título** del PR sigue el formato de commit (`feat(inventory): agrega apilado de ítems`).
- **Una sola persona revisa** cada PR: quien lidera el proyecto. No hay rotación de revisores.
- Quien abre el PR es quien lo integra, **una vez que el líder lo revisó** (con aprobación en GitHub o un aviso en el chat). Los PR del propio líder los integra él mismo.
- GitHub **no exige** un número de aprobaciones: la revisión es una **regla del equipo**. No se integra un PR sin revisar.
- Un PR es **chico y de un solo tema**. Si no se puede revisar en 10-15 minutos, es demasiado grande.

### Cómo se integra

| Destino | Método en GitHub | Resultado |
|---|---|---|
| `feature/*` o `fix/*` → `dev` | **Squash and merge** | Todos los commits de la rama quedan en uno solo, con el título del PR |
| `dev` → `main` | **Create a merge commit** | Se conserva la historia completa de la versión |

Con *Squash and merge*, `dev` queda con **un commit por funcionalidad**, lo que hace fácil leer y revertir. Por eso es tan importante que el título del PR siga el formato.

### Descripción del PR (plantilla)

La plantilla se completa sola al abrir un PR (archivo `.github/pull_request_template.md`). Contenido:

```text
## Qué cambia
(1-3 líneas)

## Cómo probarlo
(pasos para ver que funciona en Godot)

## Checklist
- [ ] Probé el juego y no hay errores nuevos
- [ ] Subí los .uid y .import necesarios
- [ ] No subí archivos que no toqué
- [ ] Actualicé la documentación si cambié cómo se trabaja
```

### Protección de ramas (configuración en GitHub)

| Rama | Configuración |
|---|---|
| `main` | Pull Request obligatorio · 0 aprobaciones exigidas por GitHub · sin force-push · sin borrado |
| `dev` | Pull Request obligatorio · 0 aprobaciones exigidas por GitHub · sin force-push · sin borrado |

---

## 8. Versiones estables en `main` 🆕

- Se pasa de `dev` a `main` **solo al alcanzar un hito** y con el juego funcionando.
- Cada versión estable lleva un **número** y una **etiqueta (tag)**:

| Formato | Ejemplo |
|---|---|
| Mensaje del commit en `main` | `release: v0.1.0 - inventario y combate básico` |
| Tag de Git | `v0.1.0` |

- Numeración `v0.MINOR.PATCH` mientras el juego no sea la versión 1.0:
  - `MINOR` sube con cada hito (`v0.1.0` → `v0.2.0`).
  - `PATCH` sube con correcciones (`v0.1.0` → `v0.1.1`).
- En GitHub, cada tag se acompaña de una **Release** con una breve descripción del estado de la versión respecto de la anterior.

> **Cambio respecto a las reglas originales:** el formato `Stable Build [V_1.00]` se reemplaza por `release: v0.1.0` + tag. Mantiene la misma idea, y los tags permiten volver a cualquier versión estable con un comando.

---

## 9. Conflictos de fusión: guía rápida 🆕

Un conflicto aparece cuando dos personas cambiaron **la misma parte del mismo archivo**. No es un error ni se pierde nada: Git te pide que elijas.

**Primero:** cerrá Godot y respirá. Podés **cancelar todo** en cualquier momento con `git merge --abort`.

| Tipo de archivo | Qué hacer |
|---|---|
| **Texto y código** (`.gd`, `.md`, `.json`) | Abrilo y buscá las marcas `<<<<<<<`, `=======`, `>>>>>>>`. Dejá la versión correcta (o combiná), borrá las marcas, guardá y commiteá. |
| **Escenas y recursos** (`.tscn`, `.tres`, `project.godot`) | **No los edites a mano** si no sabés cómo. Elegí una versión completa o pedí ayuda. |
| **Binarios** (`.png`, `.wav`, ...) | Elegí una de las dos versiones. |

**Elegir una versión completa de un archivo** (cuando hacés `git merge dev` estando en tu rama):

```bash
git checkout --ours   <archivo>    # tu versión (tu rama)
git checkout --theirs <archivo>    # la versión de dev
git add <archivo>
```

En GitHub Desktop: *Use my version* / *Use their version*.

**Si dudás:** mandá una captura al chat y no sigas. Resolver mal un conflicto de escenas puede romper el juego sin avisar.

---

## 10. Reglas de oro

1. **Nunca** `git push --force` ni `git reset --hard` sin consultar.
2. **Nunca** subir directo a `main` ni a `dev`.
3. **Nunca** `git rebase` por ahora (usá `git merge dev` en tu rama).
4. Commits chicos, con el formato `tipo(ámbito): descripción`.
5. `git pull` de `dev` antes de empezar a trabajar.
6. Una persona por escena a la vez.
7. Ante la duda, **preguntar antes de actuar**.

---

## 11. Estado de transición: `develop` → `dev` 🆕

> Sección temporal. Se elimina cuando se borre la rama archivada.

- La rama **`develop` queda obsoleta** y se renombra a `archive/develop-v1`. **No se sube nada ahí.**
- La rama de trabajo nueva es **`dev`**.
- El contenido útil del archivo se **rescata de a partes** (por archivo, no con merge) a través de ramas `feature/*` y Pull Requests hacia `dev`.
- Antes de borrar la rama archivada se deja una etiqueta (`archive/develop-final`) para no perder nada.
- La rama archivada se borra **a más tardar a las 12 semanas** de la migración.
- Más detalle en [`docs/decisions/0001-reemplazar-develop-por-dev.md`](docs/decisions/0001-reemplazar-develop-por-dev.md).
- Si tenés trabajo sin subir basado en `develop`, avisá **antes** de actualizar tu copia local.

---

## 12. Cambios respecto a las reglas originales

| Regla original | Ahora | Motivo |
|---|---|---|
| Rama `develop` | `dev` (y `develop` pasa a archivo) | Empezar limpio |
| `feature/NAME_OF_FEATURE` | `feature/<área>-<descripcion>` en minúsculas | Compatibilidad Windows/Linux |
| Sin tipo `fix/` | Se agrega `fix/` | Separar correcciones |
| Sin convención en ramas `feature` | Convención en todos los commits (recomendada) y **obligatoria en el título del PR** | Historial legible aunque se use squash |
| Commits en inglés | Prefijo en inglés + descripción en español | Que todo el equipo pueda describir bien |
| `Stable Build [V_1.00]` | `release: v0.1.0` + tag | Compatible con Git y con herramientas |
| Sin Pull Requests | PR obligatorio hacia `dev` y `main` | Revisión y menos errores |
| Sin guía de conflictos | Guía rápida (sección 9) | Equipo con distinto nivel técnico |

### Decisiones registradas

El porqué de estas reglas está en `docs/decisions/`: [ADR-0001](docs/decisions/0001-reemplazar-develop-por-dev.md) (rama `dev`), [ADR-0002](docs/decisions/0002-formato-hibrido-de-commits.md) (formato de commits) y [ADR-0003](docs/decisions/0003-pull-requests-con-un-solo-revisor.md) (Pull Requests).
