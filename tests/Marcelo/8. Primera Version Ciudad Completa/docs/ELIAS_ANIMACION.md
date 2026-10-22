# Elías — poses completas, B.1.5

Esta revisión corrige la silueta y las articulaciones de la versión B.1.4. Los ciclos se exportan desde dibujos de cuerpo entero: cada pose ya incluye cabeza, torso, brazos, piernas, ropa y equipo conectados. El exportador aplica escala proporcional y traslación a la figura completa.

## Entrega

| Elemento | Especificación |
|---|---|
| `assets/elias_64.png` | PNG transparente de 1088 × 256 px |
| Grilla | 17 columnas × 4 filas, celdas de 64 × 64 px |
| Filas | Sur, oeste, este, norte |
| Columnas 0–7 | Ocho poses de caminata |
| Columnas 8–15 | Ocho poses propias de carrera |
| Columna 16 | Reposo |
| `assets/elias/frames/` | 68 PNG individuales: 32 caminar, 32 correr y cuatro reposos |
| Altura visible | 49–58 px, según la postura |
| Transparencia | Alpha binario; paleta compartida de 64 colores |
| Ancla | Pie central del rectángulo: `[32,64]` |

Se conserva el diseño de Elías: pelo rubio, ojos verdes, chaleco verde oscuro, camisa marfil, tahalí, cinturones, faja bordó, pantalones oscuros, botas y espada envainada a la izquierda. Los ciclos incluyen cambios de apoyo, flexión de rodillas y balanceo de brazos. La carrera tiene inclinación y poses propias.

## Exportación y anatomía

El arte se produjo con la **herramienta integrada de generación de imágenes**, usando la referencia y el modelo de Elías. Las nueve hojas seleccionadas están en `sources/elias/fullbody_v3/`; `generation.json` conserva los prompts completos y las correcciones dirigidas.

`tools/prepare_elias.cjs` extrae los personajes de cada celda, aplica una única escala proporcional por ciclo y registra las figuras completas. Usa el cabello como referencia horizontal y la base de los pies en las poses de apoyo; mantiene la elevación de las poses de carrera. El muestreo de área se realiza directamente a la resolución nativa, con alpha binario. El atlas terminado se amplía con vecino más cercano.

El exportador no gira ni estira piezas del cuerpo. No hay un esqueleto de recortes en el personaje entregado. Los archivos antiguos de `rig_v2/` y los exportadores archivados son historial y no intervienen en la versión actual.

## Uso en el juego

`catalogo.json → player.animations` contiene los índices: caminar a 12 fps y correr a 16 fps. Cada ciclo tiene ocho dibujos distintos. La fase se conserva al cambiar de orientación o al mantener Shift. Si el desplazamiento queda bloqueado o se sueltan las teclas, Elías vuelve al reposo.

Se mantienen el desplazamiento en ocho direcciones, sus cuatro orientaciones visuales, las colisiones, las velocidades de exploración y la cámara. Navegador y Godot usan el mismo atlas y catálogo.

## Revisar las poses

- `previews/Elias_Animaciones.html`: reposo, caminata y carrera juntos, selector de dirección, pausa, avance cuadro a cuadro, cámara lenta, ampliación ×4 y vista nativa.
- `previews/Elias_Caminata.gif`: comparación lateral de caminar y correr. Conserva el nombre del archivo de entregas anteriores.
- `previews/Elias_Anatomia_Comparacion.png`: comparación estática de estados en las cuatro orientaciones.
- `previews/elias_walk_keyposes.png` y `elias_run_keyposes.png`: fases principales de los ciclos.
- `previews/mercado_960x540.png`: escala real dentro de la ciudad.

## Reconstrucción

```sh
node tools/prepare_elias.cjs
node tools/preview_elias.cjs
ffmpeg -v error -y -framerate 48 -i previews/elias_frames/%02d.png -filter_complex '[0:v]split[a][b];[a]palettegen=stats_mode=full[p];[b][p]paletteuse=dither=none' -loop 0 previews/Elias_Caminata.gif
node tools/build_web.cjs
```

El GIF usa 96 cuadros de presentación para mostrar dos segundos de ambos ciclos; los cuadros originales del personaje son los ocho de cada ciclo. El reposo es una pose fija por orientación.

## Verificación

El informe de assets comprueba tamaño, ausencia de cortes, transparencia binaria, ocho PNG distintos por ciclo y separación entre caminar y correr. La revisión visual compara siluetas y articulaciones entre estados. Los controles y la reproducción de los índices se verifican por separado en navegador y Godot.

Informes: `docs/elias_asset_validation.json`, `docs/browser_validation.json`, `docs/godot_validation.json` y `docs/elias_preview_validation.json`.
