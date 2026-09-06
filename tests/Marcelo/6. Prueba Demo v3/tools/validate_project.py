#!/usr/bin/env python3
"""Validación rápida de rutas, JSON, PNG y WAV del proyecto."""

from __future__ import annotations

import json
import re
import struct
import sys
import wave
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RESOURCE_PATTERN = re.compile(r"res://[A-Za-z0-9_./-]+")
EXT_DECLARATION = re.compile(r'^\[ext_resource\b[^]]*\bid="([^"]+)"[^]]*\]$')
SUB_DECLARATION = re.compile(r'^\[sub_resource\b[^]]*\bid="([^"]+)"[^]]*\]$')
EXT_USAGE = re.compile(r'ExtResource\("([^"]+)"\)')
SUB_USAGE = re.compile(r'SubResource\("([^"]+)"\)')
NODE_NAME = re.compile(r'^\[node\b[^]]*\bname="([^"]+)"[^]]*\]$')
NODE_PARENT = re.compile(r'\bparent="([^"]+)"')
CONNECTION_PATH = re.compile(r'\b(from|to)="([^"]+)"')
LOAD_STEPS = re.compile(r"load_steps=(\d+)")


def png_size(path: Path) -> tuple[int, int]:
    contents = path.read_bytes()
    if contents[:8] != b"\x89PNG\r\n\x1a\n" or len(contents) < 24:
        raise ValueError(f"PNG inválido: {path}")
    width, height = struct.unpack(">II", contents[16:24])

    offset = 8
    found_end = False
    while offset + 12 <= len(contents):
        chunk_length = struct.unpack(">I", contents[offset : offset + 4])[0]
        chunk_end = offset + 12 + chunk_length
        if chunk_end > len(contents):
            raise ValueError(f"PNG truncado: {path}")
        chunk_type = contents[offset + 4 : offset + 8]
        chunk_data = contents[offset + 8 : offset + 8 + chunk_length]
        stored_crc = struct.unpack(">I", contents[offset + 8 + chunk_length : chunk_end])[0]
        calculated_crc = zlib.crc32(chunk_type + chunk_data) & 0xFFFFFFFF
        if stored_crc != calculated_crc:
            raise ValueError(f"CRC inválido en PNG: {path}")
        offset = chunk_end
        if chunk_type == b"IEND":
            found_end = True
            break
    if not found_end:
        raise ValueError(f"PNG sin cierre IEND: {path}")
    return width, height


def validate_json(path: Path, errors: list[str]) -> None:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"{path.relative_to(ROOT)}: {exc}")
        return
    if path.parent.name == "cinematics":
        beats = data.get("beats", [])
        if not beats:
            errors.append(f"{path.relative_to(ROOT)}: no contiene beats")
        for beat_index, beat in enumerate(beats):
            panels = beat.get("panels", [])
            if not 1 <= len(panels) <= 4:
                errors.append(
                    f"{path.relative_to(ROOT)} beat {beat_index}: debe tener entre 1 y 4 paneles"
                )
            for panel_index, panel in enumerate(panels):
                rect = panel.get("rect", [])
                if len(rect) != 4 or any(not 0.0 <= float(value) <= 1.0 for value in rect):
                    errors.append(
                        f"{path.relative_to(ROOT)} beat {beat_index}, panel {panel_index}: rect inválido"
                    )
                for text_index, text_item in enumerate(panel.get("texts", [])):
                    text_rect = text_item.get("rect", [])
                    rect_is_valid = len(text_rect) == 4 and all(
                        0.0 <= float(value) <= 1.0 for value in text_rect
                    )
                    if rect_is_valid and not bool(text_item.get("allow_overflow", False)):
                        rect_is_valid = (
                            float(text_rect[0]) + float(text_rect[2]) <= 1.0
                            and float(text_rect[1]) + float(text_rect[3]) <= 1.0
                        )
                    if not rect_is_valid:
                        errors.append(
                            f"{path.relative_to(ROOT)} beat {beat_index}, panel {panel_index}, "
                            f"texto {text_index}: rect inválido"
                        )
                    if not str(text_item.get("text", "")).strip():
                        errors.append(
                            f"{path.relative_to(ROOT)} beat {beat_index}, panel {panel_index}, "
                            f"texto {text_index}: contenido vacío"
                        )


def validate_references(errors: list[str]) -> int:
    references: set[str] = set()
    for suffix in ("*.gd", "*.tscn", "*.json", "*.godot", "*.tres"):
        for path in ROOT.rglob(suffix):
            text = path.read_text(encoding="utf-8")
            references.update(RESOURCE_PATTERN.findall(text))
    for reference in sorted(references):
        relative = reference.removeprefix("res://")
        if not (ROOT / relative).exists():
            errors.append(f"Referencia inexistente: {reference}")
    return len(references)


def validate_text_resources(errors: list[str]) -> None:
    for path in ROOT.rglob("*.tres"):
        first_line = path.read_text(encoding="utf-8").splitlines()[0]
        if not first_line.startswith("[gd_resource "):
            errors.append(f"Cabecera de recurso inválida: {path.relative_to(ROOT)}")
        elif 'type="' not in first_line:
            errors.append(f"Falta el tipo del recurso: {path.relative_to(ROOT)}")

    bus_layout = (ROOT / "default_bus_layout.tres").read_text(encoding="utf-8")
    if not bus_layout.startswith('[gd_resource type="AudioBusLayout" format=3]'):
        errors.append("default_bus_layout.tres no declara AudioBusLayout")


def validate_scene_structure(path: Path, errors: list[str]) -> None:
    """Comprueba ids, padres y load_steps sin depender de la caché de Godot."""
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if not lines or not lines[0].startswith("[gd_scene "):
        errors.append(f"Cabecera de escena inválida: {path.relative_to(ROOT)}")
        return

    ext_ids = [match.group(1) for line in lines if (match := EXT_DECLARATION.match(line))]
    sub_ids = [match.group(1) for line in lines if (match := SUB_DECLARATION.match(line))]
    if len(ext_ids) != len(set(ext_ids)):
        errors.append(f"Ids de recurso externo duplicados: {path.relative_to(ROOT)}")
    if len(sub_ids) != len(set(sub_ids)):
        errors.append(f"Ids de subrecurso duplicados: {path.relative_to(ROOT)}")
    for used_id in EXT_USAGE.findall(text):
        if used_id not in ext_ids:
            errors.append(f"ExtResource inexistente {used_id}: {path.relative_to(ROOT)}")
    for used_id in SUB_USAGE.findall(text):
        if used_id not in sub_ids:
            errors.append(f"SubResource inexistente {used_id}: {path.relative_to(ROOT)}")

    load_match = LOAD_STEPS.search(lines[0])
    if load_match:
        expected_steps = len(ext_ids) + len(sub_ids) + 1
        if int(load_match.group(1)) != expected_steps:
            errors.append(
                f"load_steps incorrecto en {path.relative_to(ROOT)}: "
                f"{load_match.group(1)} en vez de {expected_steps}"
            )

    known_paths = {"."}
    root_count = 0
    for line in lines:
        node_match = NODE_NAME.match(line)
        if not node_match:
            continue
        name = node_match.group(1)
        parent_match = NODE_PARENT.search(line)
        if parent_match is None:
            root_count += 1
            continue
        parent = parent_match.group(1)
        if parent not in known_paths:
            errors.append(
                f"Padre de nodo inexistente '{parent}' en {path.relative_to(ROOT)}"
            )
            continue
        node_path = name if parent == "." else f"{parent}/{name}"
        known_paths.add(node_path)
    if root_count != 1:
        errors.append(f"{path.relative_to(ROOT)} debe tener un único nodo raíz")

    for line in lines:
        if not line.startswith("[connection "):
            continue
        for role, scene_path in CONNECTION_PATH.findall(line):
            if scene_path not in known_paths:
                errors.append(
                    f"Conexión con {role} inexistente '{scene_path}' en "
                    f"{path.relative_to(ROOT)}"
                )


def validate_resource_structure(path: Path, errors: list[str]) -> None:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if not lines:
        return
    ext_ids = [match.group(1) for line in lines if (match := EXT_DECLARATION.match(line))]
    sub_ids = [match.group(1) for line in lines if (match := SUB_DECLARATION.match(line))]
    for used_id in EXT_USAGE.findall(text):
        if used_id not in ext_ids:
            errors.append(f"ExtResource inexistente {used_id}: {path.relative_to(ROOT)}")
    for used_id in SUB_USAGE.findall(text):
        if used_id not in sub_ids:
            errors.append(f"SubResource inexistente {used_id}: {path.relative_to(ROOT)}")
    load_match = LOAD_STEPS.search(lines[0])
    if load_match:
        expected_steps = len(ext_ids) + len(sub_ids) + 1
        if int(load_match.group(1)) != expected_steps:
            errors.append(
                f"load_steps incorrecto en {path.relative_to(ROOT)}: "
                f"{load_match.group(1)} en vez de {expected_steps}"
            )


def validate_visual_authoring(errors: list[str]) -> None:
    pages_dir = ROOT / "scenes/cinematic/pages"
    story_pages = [pages_dir / f"page_{index:03d}.tscn" for index in range(1, 9)]
    for page in story_pages:
        if not page.exists():
            errors.append(f"Falta la página visual: {page.relative_to(ROOT)}")
    if any(not page.exists() for page in story_pages):
        return

    panel_pattern = re.compile(r'^\[node name="Panel\d+" type="Control" parent="\."\]$', re.M)
    panel_total = sum(len(panel_pattern.findall(page.read_text(encoding="utf-8"))) for page in story_pages)
    if panel_total != 26:
        errors.append(f"La historia visual debe contener 26 paneles; contiene {panel_total}")

    sequence_text = (ROOT / "resources/cinematics/elias_intro.tres").read_text(encoding="utf-8")
    for page in story_pages:
        expected_reference = f"res://{page.relative_to(ROOT).as_posix()}"
        if expected_reference not in sequence_text:
            errors.append(f"La secuencia visual no incluye {expected_reference}")

    visual_scene_minimums = {
        "scenes/main_menu.tscn": 15,
        "scenes/controls_screen.tscn": 20,
        "scenes/loading_screen.tscn": 7,
        "scenes/elias_room.tscn": 50,
        "scenes/ui/pause_manager.tscn": 15,
        "scenes/ui/options_panel.tscn": 20,
        "scenes/ui/inventory_panel.tscn": 60,
        "scenes/ui/world_speech_bubble.tscn": 7,
    }
    for relative, minimum_nodes in visual_scene_minimums.items():
        source = (ROOT / relative).read_text(encoding="utf-8")
        node_count = source.count("[node ")
        if node_count < minimum_nodes:
            errors.append(f"{relative} volvió a ser una escena vacía ({node_count} nodos)")

    behavior_only_scripts = [
        "scripts/ui/main_menu.gd",
        "scripts/ui/controls_screen.gd",
        "scripts/ui/loading_screen.gd",
        "scripts/ui/options_panel.gd",
        "scripts/autoload/pause_manager.gd",
        "scripts/game/room_scene.gd",
        "scripts/game/elias_controller.gd",
        "scripts/inventory/inventory_manager.gd",
        "scripts/ui/inventory_panel.gd",
        "scripts/ui/world_speech_bubble.gd",
        "scripts/cinematic/cinematic_player.gd",
    ]
    visual_constructors = re.compile(
        r"\b(?:TextureRect|ColorRect|PanelContainer|Button|Label|Sprite2D|CollisionShape2D)\.new\("
    )
    for relative in behavior_only_scripts:
        source = (ROOT / relative).read_text(encoding="utf-8")
        if visual_constructors.search(source):
            errors.append(f"{relative} volvió a construir contenido visual por código")

    project_text = (ROOT / "project.godot").read_text(encoding="utf-8")
    if 'PauseManager="*res://scenes/ui/pause_manager.tscn"' not in project_text:
        errors.append("PauseManager no usa su escena visual")
    if 'Inventory="*res://scenes/game/inventory_manager.tscn"' not in project_text:
        errors.append("Inventory no usa su escena persistente")
    if "res://addons/comic_story_editor/plugin.cfg" not in project_text:
        errors.append("El plugin de edición visual no está habilitado")

    required_input_actions = (
        "move_left",
        "move_right",
        "move_up",
        "move_down",
        "interact",
        "toggle_inventory",
        "advance_story",
        "pause_game",
    )
    if "[input]" not in project_text:
        errors.append("project.godot no contiene un mapa de entradas visual")
    for action in required_input_actions:
        if not re.search(rf"^{re.escape(action)}=\{{", project_text, re.M):
            errors.append(f"Falta la acción editable de entrada: {action}")

    controller_text = (ROOT / "scripts/game/elias_controller.gd").read_text(
        encoding="utf-8"
    )
    if "Input.is_physical_key_pressed(KEY_A)" not in controller_text:
        errors.append("Elias no contiene el respaldo de movimiento físico")
    room_text = (ROOT / "scripts/game/room_scene.gd").read_text(encoding="utf-8")
    if "get_tree().paused = false" not in room_text:
        errors.append("La habitación no limpia el estado de pausa al entrar")

    combined_export_filter = re.compile(r'@export_file\("[^"\n]*,[^"\n]*"\)')
    for path in (ROOT / "scripts").rglob("*.gd"):
        source = path.read_text(encoding="utf-8")
        if combined_export_filter.search(source):
            errors.append(
                f"Filtro @export_file combinado en {path.relative_to(ROOT)}; "
                'usá argumentos separados: @export_file("*.wav","*.ogg","*.mp3")'
            )

    if '@export_file("*.wav","*.ogg","*.mp3")' not in room_text:
        errors.append("La casa no usa el filtro de audio múltiple corregido")

    room_scene_text = (ROOT / "scenes/elias_room.tscn").read_text(encoding="utf-8")
    if 'preparacion_de_viaje = ExtResource(' not in room_scene_text:
        errors.append("La casa no tiene asignada la misión de preparativos")
    if room_scene_text.count("recoger_al_interactuar = true") < 4:
        errors.append("La casa debe contener al menos cuatro objetos de viaje")
    for sector_name in ("BedroomSector", "StudySector", "PantrySector"):
        if f'[node name="{sector_name}"' not in room_scene_text:
            errors.append(f"Falta el sector editable de la casa: {sector_name}")


def validate_autoload_dependencies(errors: list[str]) -> None:
    project_text = (ROOT / "project.godot").read_text(encoding="utf-8")
    autoloads: dict[str, Path] = {}
    in_autoload_section = False
    for raw_line in project_text.splitlines():
        line = raw_line.strip()
        if line.startswith("["):
            in_autoload_section = line == "[autoload]"
            continue
        if not in_autoload_section or "=" not in line:
            continue
        name, value = line.split("=", 1)
        resource_path = value.strip().strip('"').removeprefix("*")
        if resource_path.startswith("res://"):
            autoloads[name.strip()] = ROOT / resource_path.removeprefix("res://")

    graph: dict[str, set[str]] = {name: set() for name in autoloads}
    for name, script_path in autoloads.items():
        source = script_path.read_text(encoding="utf-8")
        if script_path.suffix == ".tscn":
            for reference in RESOURCE_PATTERN.findall(source):
                if reference.endswith(".gd"):
                    referenced_script = ROOT / reference.removeprefix("res://")
                    if referenced_script.exists():
                        source += "\n" + referenced_script.read_text(encoding="utf-8")
        for candidate in autoloads:
            if candidate != name and re.search(rf"\b{re.escape(candidate)}\s*\.", source):
                graph[name].add(candidate)

    visiting: list[str] = []
    visited: set[str] = set()

    def visit(name: str) -> None:
        if name in visiting:
            start = visiting.index(name)
            cycle = visiting[start:] + [name]
            errors.append("Dependencia circular de autoloads: " + " → ".join(cycle))
            return
        if name in visited:
            return
        visiting.append(name)
        for dependency in graph[name]:
            visit(dependency)
        visiting.pop()
        visited.add(name)

    for autoload_name in graph:
        visit(autoload_name)


def validate_signal_callbacks(errors: list[str]) -> None:
    """Evita Callables tomados de llamadas encadenadas, incompatibles con algunos parsers."""
    chained_callable = re.compile(
        r"\.connect\([^\n]*(?:get_tree|get_node|load)\([^)]*\)\.[A-Za-z_]\w*\s*\)"
    )
    for path in (ROOT / "scripts").rglob("*.gd"):
        source = path.read_text(encoding="utf-8")
        if chained_callable.search(source):
            errors.append(
                f"Callback de señal encadenado en {path.relative_to(ROOT)}; "
                "usá una función con nombre"
            )


def validate_media(errors: list[str]) -> None:
    for path in ROOT.rglob("*.png"):
        try:
            width, height = png_size(path)
            if width <= 0 or height <= 0:
                errors.append(f"Dimensiones inválidas: {path.relative_to(ROOT)}")
        except (OSError, ValueError) as exc:
            errors.append(str(exc))
    sprite_path = ROOT / "assets/sprites/elias_sheet.png"
    sprite_width, sprite_height = png_size(sprite_path)
    if sprite_width % 4 != 0 or sprite_height % 2 != 0:
        errors.append("La hoja de Elías no es divisible en una cuadrícula 4 × 2")
    room_width, room_height = png_size(ROOT / "assets/art/room/elias_room.png")
    if (room_width, room_height) != (1672, 941):
        errors.append("La casa de Elías debe conservar el lienzo jugable de 1672 × 941")
    for icon_name in ("travel_cloak", "road_map", "waterskin", "provisions"):
        icon_path = ROOT / f"assets/ui/inventory/{icon_name}.png"
        if png_size(icon_path) != (192, 192):
            errors.append(f"El icono {icon_name} no mide 192 × 192")
    for path in ROOT.rglob("*.wav"):
        try:
            with wave.open(str(path), "rb") as audio:
                if audio.getnframes() == 0 or audio.getframerate() == 0:
                    errors.append(f"Audio vacío: {path.relative_to(ROOT)}")
        except (OSError, wave.Error) as exc:
            errors.append(f"WAV inválido {path.relative_to(ROOT)}: {exc}")


def main() -> int:
    errors: list[str] = []
    for path in (ROOT / "data/cinematics").glob("*.json"):
        validate_json(path, errors)
    reference_count = validate_references(errors)
    validate_text_resources(errors)
    for path in ROOT.rglob("*.tscn"):
        validate_scene_structure(path, errors)
    for path in ROOT.rglob("*.tres"):
        validate_resource_structure(path, errors)
    validate_visual_authoring(errors)
    validate_autoload_dependencies(errors)
    validate_signal_callbacks(errors)
    validate_media(errors)
    if errors:
        print("VALIDACIÓN FALLIDA")
        for error in errors:
            print(f"- {error}")
        return 1
    file_count = sum(1 for path in ROOT.rglob("*") if path.is_file())
    print(f"VALIDACIÓN CORRECTA · {file_count} archivos · {reference_count} referencias")
    return 0


if __name__ == "__main__":
    sys.exit(main())
