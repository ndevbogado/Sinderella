@tool
@icon("res://assets/ui/briar_icon.svg")
class_name VisualComicPage
extends Control

## Una página completa. Sus paneles son hijos VisualComicPanel visibles en el editor.

enum Atmosphere { NINGUNA, LLUVIA, CENIZA, NIEBLA, NIEBLA_Y_CENIZA }

@export_category("Página")
@export var identificador := "pagina_nueva"
@export_range(0.2, 30.0, 0.1) var espera := 6.0
@export_enum("Ninguna", "Lluvia", "Ceniza", "Niebla", "Niebla y ceniza") var atmosfera: int = Atmosphere.NINGUNA
@export_range(0.0, 2.0, 0.05) var intensidad_atmosfera := 1.0

@export_category("Audio de esta página")
@export var efecto_de_sonido: AudioStream
@export_range(-40.0, 6.0, 0.5) var volumen_efecto_db := -6.0

@export_category("Transición a juego")
@export var expandir_al_terminar := false
@export var panel_a_expandir: NodePath

@export_category("Notas para edición")
@export_multiline var notas := "Arrastrá los paneles en el editor 2D. El orden del árbol es el orden de aparición."


func get_panels() -> Array:
	var panels: Array = []
	_collect_panels(self, panels)
	return panels


func get_atmosphere_mode() -> String:
	match atmosfera:
		Atmosphere.LLUVIA:
			return "rain"
		Atmosphere.CENIZA:
			return "ash"
		Atmosphere.NIEBLA:
			return "mist"
		Atmosphere.NIEBLA_Y_CENIZA:
			return "mist_ash"
		_:
			return "none"


func get_design_size() -> Vector2:
	if size.x > 1.0 and size.y > 1.0:
		return size
	return Vector2(1280.0, 720.0)


func _collect_panels(node: Node, result: Array) -> void:
	for child in node.get_children():
		if child is VisualComicPanel:
			result.append(child)
		else:
			_collect_panels(child, result)
