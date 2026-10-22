# Registro de decisiones de arquitectura (ADR)

Cada decisión importante del proyecto se registra en **una página corta** que explica el contexto, qué se decidió, qué alternativas se descartaron y qué consecuencias tiene. Sirve para responder, meses después, la pregunta *"¿por qué lo hicimos así?"*.

---

## 1. Índice

| N.º | Decisión | Estado | Fecha |
|---|---|---|---|
| [0001](0001-reemplazar-develop-por-dev.md) | Reemplazar la rama `develop` por una rama nueva `dev` | ✅ Aceptada | 22/10/2026 |
| [0002](0002-formato-hibrido-de-commits.md) | Formato híbrido para los mensajes de commit | ✅ Aceptada | 22/10/2026 |
| [0003](0003-pull-requests-con-un-solo-revisor.md) | Pull Requests obligatorios con un solo revisor | ✅ Aceptada | 22/10/2026 |

**Estados posibles:** 🟡 Propuesta · ✅ Aceptada · ⛔ Rechazada · 🔁 Reemplazada por ADR-XXXX

---

## 2. Cuándo escribir un ADR

Escribí uno cuando la decisión:

- es **difícil o costosa de revertir** (formato de datos, estructura de carpetas, plugins, motor);
- **afecta a todo el equipo** (flujo de trabajo, reglas, herramientas);
- tuvo **alternativas reales** y alguien podría preguntar por qué se eligió una.

No hace falta para cambios chicos o fáciles de deshacer.

## 3. Reglas

1. **Un archivo por decisión**, numerado en orden: `NNNN-titulo-corto-en-minusculas.md`.
2. **No se reescribe** un ADR aceptado. Si la decisión cambia, se crea un ADR nuevo, y el viejo pasa a estado 🔁 *Reemplazada por ADR-XXXX* (solo se edita ese campo).
3. Se agrega a la tabla del índice (sección 1) en el **mismo Pull Request**.
4. Mantenerlo **corto**: una o dos pantallas.
5. Escrito en **español**, igual que el resto de la documentación.

---

## 4. Plantilla

Copiá el bloque siguiente en un archivo nuevo.

````markdown
# ADR-NNNN: Título de la decisión

| | |
|---|---|
| **Estado** | 🟡 Propuesta |
| **Fecha** | DD/MM/AAAA |
| **Decide** | Quién decide |
| **Relacionado** | Enlaces a otros documentos o ADR |

---

## 1. Contexto

Qué problema hay y qué condiciones lo rodean (2 a 6 puntos).

## 2. Decisión

Qué se decidió, en forma concreta y verificable.

## 3. Alternativas consideradas

| Alternativa | Por qué se descartó |
|---|---|
| | |

## 4. Consecuencias

### Positivas
-

### Negativas y costos
-

### Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| | |

## 5. Cuándo revisarla (opcional)

Qué tendría que pasar para volver a pensar esta decisión.
````
