# ADR-0002: Formato híbrido para los mensajes de commit

| | |
|---|---|
| **Estado** | ✅ Aceptada |
| **Fecha** | 22/10/2026 |
| **Decide** | Quien lidera el proyecto |
| **Relacionado** | [`CONTRIBUTING.md`](../../CONTRIBUTING.md), secciones 3 y 4 |

---

## 1. Contexto

- Los primeros commits del proyecto se escribieron en inglés, con un formato propio, por la única persona del equipo que domina Git e inglés.
- El resto del equipo subió después una gran cantidad de cambios en pocos commits, con **mensajes genéricos en español**.
- El equipo tiene 4 personas, en tiempo libre y con distinto nivel técnico. La documentación del proyecto está en español por decisión del equipo.
- El repositorio es **público**. Git, GitHub y Godot usan vocabulario en inglés (`merge`, `fix`, `refactor`).
- Escribir en un idioma que no se domina tiende a producir mensajes cortos y vagos, lo contrario de lo que se necesita.

## 2. Decisión

Los mensajes de commit usan un **prefijo en inglés (fijo) y una descripción en español (libre)**:

```text
tipo(ámbito): descripción en español
```

- **Tipos permitidos:** `feat`, `fix`, `data`, `art`, `audio`, `docs`, `refactor`, `test`, `chore`, `release`.
- **Ámbito:** carpeta o sistema afectado (`inventory`, `combat`, `save`...). Es opcional.
- **Descripción:** verbo en presente (*agrega, corrige, elimina*), una línea, hasta ~72 caracteres, sin punto final.
- El formato es **obligatorio en el título del Pull Request** y **recomendado en cada commit** (ver [ADR-0003](0003-pull-requests-con-un-solo-revisor.md)).
- El historial anterior **no se reescribe**: las reglas valen desde ahora.

Ejemplo: `feat(inventory): agrega apilado de ítems con límite por stack`

## 3. Alternativas consideradas

| Alternativa | Por qué se descartó |
|---|---|
| **Todo en inglés** | Barrera alta: solo una persona domina el idioma. Los demás escribirían mensajes más vagos o evitarían commitear. Mayor fricción en un proyecto de tiempo libre. |
| **Todo en español** | Mezcla inevitable con términos como `merge` o `refactor`; menos compatible con herramientas que esperan prefijos en inglés; más difícil de leer para colaboradores externos. |
| **Sin convención** | Es lo que produjo los commits genéricos y gigantes que motivaron esta decisión. |

## 4. Consecuencias

### Positivas

- Todos pueden describir con precisión lo que hicieron, sin depender del inglés.
- Los prefijos son una lista corta (10 palabras) que se memoriza una vez.
- El historial es legible a simple vista y es compatible con herramientas que usan este tipo de prefijos.

### Negativas y costos

- Quien no hable español tendrá más difícil seguir el historial.
- Hay que aprender y recordar la lista de tipos.
- El formato **no evita por sí solo** los commits gigantes: para eso están las reglas de tamaño de [`CONTRIBUTING.md`](../../CONTRIBUTING.md) (sección 4).

### Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Se usan mal los tipos | Revisión del título en cada Pull Request. |
| Descripciones vagas aunque el formato sea correcto | La regla "tiene que decir qué cambió y dónde" y los ejemplos buenos y malos de `CONTRIBUTING.md`. |

## 5. Cuándo revisarla

- Si el proyecto se abre a colaboradores que no hablan español.
- Si, cuando el equipo esté cómodo con Git, se decide pasar a inglés completo (se crearía un ADR nuevo).
