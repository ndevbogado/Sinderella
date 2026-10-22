# ADR-0003: Pull Requests obligatorios con un solo revisor

| | |
|---|---|
| **Estado** | ✅ Aceptada |
| **Fecha** | 22/10/2026 |
| **Decide** | Quien lidera el proyecto |
| **Relacionado** | [`CONTRIBUTING.md`](../../CONTRIBUTING.md), secciones 2 y 7 · [ADR-0001](0001-reemplazar-develop-por-dev.md) · [ADR-0002](0002-formato-hibrido-de-commits.md) |

---

## 1. Contexto

- Antes no había Pull Requests: los cambios se subían directamente a las ramas.
- Eso produjo cambios masivos, sin revisión y con mensajes genéricos en la rama `develop`.
- Una sola persona del equipo domina Git y puede revisar cambios.
- El equipo es chico (4 personas) y el resto está aprendiendo Git, Godot y el flujo de trabajo.
- **GitHub no permite aprobar el propio Pull Request.** Si se exigiera una aprobación, los PR de quien lidera el proyecto quedarían bloqueados, ya que es el único revisor.

## 2. Decisión

1. **Todo cambio entra a `dev` y a `main` por Pull Request.** No se sube directo.
2. **Un solo revisor**: quien lidera el proyecto. Sin rotación.
3. **GitHub no exige un número de aprobaciones** (0). La revisión es una **regla del equipo**: no se integra un PR sin revisar.
4. Quien abre el PR lo integra después de la revisión. Quien lidera el proyecto integra sus propios PR.
5. Las ramas `main` y `dev` están protegidas: sin push directo, sin force-push, sin borrado.
6. Métodos de integración:
   - `feature/*` y `fix/*` → `dev`: **Squash and merge**.
   - `dev` → `main`: **merge commit**.
7. El **título del PR** sigue el formato de [ADR-0002](0002-formato-hibrido-de-commits.md). Los PR son chicos y de un solo tema (revisables en 10 a 15 minutos).
8. Los PR se abren con una **plantilla** (`.github/pull_request_template.md`).

## 3. Alternativas consideradas

| Alternativa | Por qué se descartó |
|---|---|
| **Exigir 1 aprobación, con excepción para quien lidera** (bypass solo en Pull Requests) | Obliga a cumplir la revisión técnicamente, pero agrega configuración y complejidad. Se puede adoptar más adelante si hace falta. |
| **Sin Pull Requests** | No hay revisión ni oportunidad de enseñar el flujo. Repetiría el problema que motivó el ADR-0001. |
| **Rotar los revisores** | Con 4 personas y un solo experto en Git, no aporta valor por ahora. |
| **Merge normal en todos los casos** | `dev` se llenaría de commits intermedios y genéricos, justo lo que se quiere evitar. |
| **Squash en todos los casos** | `main` perdería la historia completa de cada versión. |

## 4. Consecuencias

### Positivas

- Cada cambio pasa por una revisión antes de entrar a `dev`.
- `dev` queda con **un commit por funcionalidad**, fácil de leer y de revertir.
- Los Pull Requests sirven para enseñar el flujo al equipo.
- La plantilla recuerda en cada PR las reglas propias de Godot (`.uid`, `.import`, no subir archivos no tocados).

### Negativas y costos

- Quien lidera el proyecto es un **cuello de botella**: toda revisión pasa por una persona.
- **Nada impide técnicamente** integrar un PR sin revisar. Depende de que el equipo respete la regla.
- Con *Squash and merge* se pierden los commits intermedios de cada rama. Un PR muy grande se convierte en un commit muy grande, por eso se exige que sean chicos.
- Un paso más por cada cambio.

### Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Se integra un PR sin revisar | Recordar la regla. Si se repite, pasar a exigir 1 aprobación (con la excepción para quien lidera). |
| Los PR se acumulan esperando revisión | Mantener los PR chicos para revisarlos rápido; definir un plazo razonable de respuesta. |
| Quien lidera no está disponible | Acordar de antemano a quién delegar la revisión durante ese período. |

## 5. Cuándo revisarla

- Si se integra más de un PR sin revisar.
- Si el equipo crece o hay más de una persona con experiencia en Git.
- Si la revisión se vuelve un cuello de botella que frena el trabajo.
