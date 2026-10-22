# Briar B.1.2 — Murallas y accesos del mismo conjunto

La referencia visual es el arte original del proyecto: `muralla_repetible_h.png`, `muralla_repetible_v.png`, `torre_muralla.png` y `porton_abierto.png`. La lámina de referencia se incluye en `references/B12_estilo_original.png`.

Se generaron cinco fuentes con la herramienta integrada de imágenes, con transparencia real. Se conservaron la piedra gris cálida, almenas claras, sombras pardas, tejados verdes, remates dorados, lámparas ámbar, estandartes de rosas y raíces discretas. Los PNG finales son exports con alpha binario, paleta de hasta 192 colores y muestreo nearest-neighbor.

| Archivo en assets/ | Tamaño nativo | Eje / función |
|---|---:|---|
| b1_muralla_ne.png | 256 × 416 | Diagonal ascendente / |
| b1_muralla_se.png | 256 × 416 | Diagonal descendente \\ |
| b12_puerta_este.png | 256 × 640 | Muralla N–S; paso E–O; frente hacia el este |
| b12_puerta_oeste.png | 256 × 640 | Muralla N–S; paso E–O; frente hacia el oeste |
| b12_arco_rio_ne.png | 640 × 800 | Arco fluvial sobre muralla diagonal / |

Las fuentes de generación están en `sources/b12_*.png`. Las primeras dos piezas reemplazan los recortes diagonales anteriores. Los otros tres archivos amplían el catálogo a 77 módulos.

## Prompts finales de generación

**Especificación común:** un único sprite modular aislado, pixel art de RPG top down a tres cuartos para Briar. Usar la lámina de las murallas y del portón original como referencia exacta de estilo: bloques de caliza gris cálida, almenas cuadradas claras con biseles, contornos oscuros finos, ménsulas, raíces y hiedra contenidas con rosas pequeñas. Luz superior izquierda. Transparencia real, incluido el interior de los arcos. Sin paisaje, piso, agua, personajes, sombras sobre el suelo, texto, desenfoque ni acabado pictórico. Mantener verticales los bordes verticales de las construcciones.

1. **Muralla /:** sección recta ascendente de izquierda abajo a derecha arriba a 45°. Seguir únicamente la geometría de la guía NE, con línea de base aproximada (70,1390) a (960,500) en lienzo 1024 × 1536. Parapeto estrecho, almenas y cara de piedra con altura de 350–400 px en la fuente. Extremos de igual altura y grosor para repetición. Sin torres, tejados, escaleras, puertas ni banderas.
2. **Muralla \\:** la misma especificación de materiales y cámara, siguiendo la guía SE de izquierda arriba a derecha abajo a 45°. Línea de base aproximada (70,500) a (960,1390). Misma altura y conexiones; sin torres, tejados, escaleras, puertas ni banderas.
3. **Puerta este:** dos torres pequeñas con tejados verdes, remates dorados, estandartes de rosa y lámparas, dispuestas una ENCIMA de la otra en el eje norte–sur de la pantalla. Conectarlas mediante un único arco lateral abierto, visible por el lado derecho/este. El jugador debe atravesar de izquierda a derecha. Interior al oeste y exterior al este. Lienzo vertical, sin base isométrica, piso ni rastrillo cerrado. Conservar el estilo exacto del portón existente.
4. **Puerta oeste:** la misma especificación, con el arco abierto visible por el lado izquierdo/oeste. Interior al este y exterior al oeste. Dos torres sobre el mismo eje vertical, no una puerta frontal horizontal. Mantener la iluminación superior izquierda.
5. **Paso del río:** muralla diagonal ascendente / a 45°, con un solo arco central muy ancho, sin pilar central. Apoyos estrechos en ambos extremos, separados para dejar libre el cauce. Parapeto continuo encima y banderas verdes discretas en los apoyos. Línea de base aproximada (48,1450) a (976,522) en lienzo 1024 × 1536, altura de muro cercana a 400 px en la fuente. El hueco debe ser transparente y ocupar la mayor parte de la luz; sin agua, terreno, barcos, tejados ni torres.

## Registro, escala y uniones

`tools/prepare_defenses.cjs` exporta las cinco fuentes a sus tamaños nativos. La transformación registra la línea de apoyo diagonal sin inclinar los bordes verticales: se conserva la coordenada horizontal y se normalizan los desplazamientos verticales respecto de la línea de apoyo. Las puertas conservan una escala uniforme de 0,40 de la fuente. No hay rotaciones de sprites frontales para simular puertas laterales.

`catalogo.json` contiene `world_anchor`, `connection_points`, `baseline` y `depth_slices`. El origen de cada objeto del mapa sigue siendo el pie central del rectángulo PNG. `world_anchor` indica el punto que debe coincidir con el eje físico de la muralla o el centro del paso.

Las diagonales se repiten con 16 px de solape. Sus franjas verticales de 32 px se ordenan por la profundidad real de la base, tanto en navegador como en Godot. Esto permite combinar las piezas con torres y personajes. La atenuación de las diagonales también sigue su línea de base.

Los dos cruces del río se calculan mediante intersección de su recorrido con el octágono. Ambos pertenecen a lados de orientación /. El lado sudeste difiere 0,274° de una diagonal exacta por las dimensiones del octágono; el registro y el solape absorben esa diferencia.

Para repetir la integración sin regenerar el terreno:

```sh
node tools/prepare_defenses.cjs
python3 tools/refine_defenses.py
npm run render
npm run tiled
npm run web
```

## Comprobación

- Lámina comparativa con las dos murallas originales, las dos diagonales, ambos portones y ambos cruces fluviales: `previews/Briar_Murallas_Corregidas.png`. Cada panel muestra un recorte real del mapa de 1280 × 960 a escala 1:2, sin reconstrucción ilustrativa.
- Capturas nativas adicionales de 960 × 540 en `previews/`.
- 1496 muestras sobre los tramos diagonales colocados: sin huecos en el paño de la muralla fuera de los pasos de agua.
- Arcos despejados sobre el ancho central del río. Terreno y grilla de navegación coinciden byte a byte con la versión B.1.
- Navegador: cruces de este y oeste en ambos sentidos; cámara, puentes, catálogo, habitantes y barcas sin fallos. Godot 4.5.2: importación y ejecución sin errores.
- Exportación Tiled e importación de vuelta conservan posiciones, terreno, colisiones, destinos y rutas. El importador conserva ahora las coordenadas de registro hasta tres decimales.
