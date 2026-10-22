# Briar — F.C: Meandros y mercados

Proyecto principal actualizado con el trazado **F.C**, el castillo central, el río serpenteante de noroeste a sudeste y la escala de **10 × 18 pantallas** de 960 × 540: **9.600 × 9.720 píxeles**. La arquitectura, los suelos R02 y Elías conservan su arte aprobado a escala nativa.

## Abrir

- **Godot 4.5.1:** importá `project.godot` y presioná F5. La primera importación procesa las imágenes de terreno.
- **Navegador:** abrí `Briar_Jugable.html`. Es autónomo y funciona sin servidor ni conexión. Hacé clic sobre el juego para dar foco al teclado.

| Acción | Control |
|---|---|
| Caminar | WASD / flechas |
| Correr | Mayús |
| Conversar | E |
| Mapa y destinos | M |
| Día / atardecer | N |
| Colisiones | C |
| Catálogo, en HTML | T |
| Grilla, en HTML | G |

El HTML conserva los controles táctiles. Esta entrega permite explorar los exteriores; no agrega interiores de los edificios.

## Distribución

- Muralla octagonal, cuatro puertas y dos pasos diagonales sobre el río.
- Castillo en el distrito central; un único castillo, catedral, mando militar y universidad. La biblioteca es independiente.
- 192 edificaciones de barrio, colocadas conservando su escala y sus polígonos de suelo.
- Plaza de los pregones con tarima y pregonero, plaza del mercado, plazoleta de la fuente y atrio de la catedral.
- 28 patios de trabajo, carga, comercio, agua o descanso. Los espacios de circulación quedan conectados con los accesos.
- Siete puentes de piedra y madera, montados mediante cabeceras y módulos centrales repetibles en ambas diagonales, sin estirar los sprites.
- Dos muelles transitables y áreas de carga sobre la ribera sur.
- Bosque exterior con 700 árboles de doce siluetas y sotobosque irregular.
- 388 habitantes con rutas y pausas, siete barcas y efectos ambientales.
- Calles horizontales, verticales y a 45°. El río utiliza curvas naturales.

Los patios y plazas son espacios funcionales de la distribución. Los interiores, horarios de trabajo y economía de sus vecinos todavía no son sistemas jugables.

## Arte y archivos

| Recurso | Ubicación |
|---|---|
| Mapa, calles, destinos, espacios comunes y habitantes | `mapa/ciudad.json` |
| Catálogo con anclas y colisiones | `catalogo.json` |
| Arte aprobado de edificios, árboles y puentes R02 | `assets/aprobados/` |
| Elías: ocho cuadros de caminata y ocho de carrera por dirección | `assets/elias_64.png` |
| 17 materiales de suelo y campos amplios | `terrenos/materiales/`, `terrenos/campos/` |
| 141 transiciones y 48 piezas diagonales | `terrenos/transiciones/`, `terrenos/diagonales/` |
| Terreno de Godot: 361 bloques de 512 px | `terrenos/chunks/` |
| Colisión activa: 1.200 × 1.215 celdas de 8 px | `mapa/colision8.bin` |
| Máscaras de materiales y distancia al río | `mapa/superficie.png`, `mapa/rio_distancia.png` |
| Proyecto de Tiled | `tiled/Briar_Gran_Ciudad.tmx` |
| Capturas del motor y plano | `previews/` |
| Reglas reproducibles de F.C | `tools/build_fc.py` |

Los bloques de terreno se cargan alrededor de la cámara. Se corrigieron los límites de carga de Godot para que dependan de las dimensiones actuales y no del antiguo mapa de 15 × 27.

## Edición y reconstrucción

Para jugar no se necesitan dependencias adicionales. Para reconstruir: Python 3 con Pillow, NumPy y SciPy; Node.js y las dependencias de `package.json`.

```sh
python3 -m pip install -r requirements.txt
npm install
npm run layout
npm run build
```

**`layout` reconstruye toda la distribución y reemplaza cambios manuales del mapa.** Usá solamente `npm run build` para conservar las posiciones actuales y reconstruir terreno, vistas, Tiled y HTML. El generador F.C reutiliza funciones geométricas de `integrate_approved.py`; ese archivo conserva el generador R02 anterior y no debe ejecutarse directamente para reconstruir F.C.

Tiled permite editar instancias, destinos, rutas y la colisión. Al mover un edificio hay que actualizar su colisión. Los puentes se modifican como conjuntos desde el generador.

```sh
python3 tools/import_tiled.py --check
python3 tools/import_tiled.py
npm run build
```

## Verificación

- Godot 4.5.1: importación y ejecución headless, destinos, puentes, animaciones, habitantes, cámara y carga en los extremos del mapa.
- Motor del HTML ejecutado directamente en Node.js con el renderizador de canvas: catorce cruces de puentes, ocho cruces de puertas, ambos muelles, animaciones y rutas.
- Comprobación de acceso a las 197 entradas de edificios, conexión de los 22 destinos y rutas completas de los habitantes.
- Validación de la exportación e importación sin cambios de Tiled; no se abrió su interfaz gráfica.
- Revisión visual del plano y de capturas a 960 × 540. La interfaz del navegador no tuvo una nueva prueba interactiva en esta entrega; la verificación del HTML corresponde a su motor de juego. Los informes web R02 anteriores están en `docs/historico_r02/`.

```sh
godot --headless --editor --path . --import
godot --headless --path . -- --verify
npm run test:engine
python3 tools/validate_fc.py
npm run check:tiled
```

Informes actuales: `docs/integration_layout.json`, `docs/godot_validation.json`, `docs/engine_validation.json`, `docs/fc_validation.json`, `docs/fc_door_access.json` y `docs/tiled_validation.json`. Los assets usados conservan sus dimensiones y anclas; `docs/fc_assets_sha256.json` registra las huellas y `docs/asset_versions.json` identifica las revisiones aprobadas.
