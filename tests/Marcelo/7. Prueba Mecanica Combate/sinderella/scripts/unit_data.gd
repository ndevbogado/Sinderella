class_name BattleUnitData
extends Resource
## Immutable definition. Current HP, roles and shields live in BattleState.
@export var id: String = "unit"
@export var display_name: String = "Personaje"
@export var max_hp: int = 100
@export var strength: int = 30
@export var armor: int = 30
@export var wit: int = 30
@export var will: int = 30
@export var speed: int = 30
@export var starting_role: String = "Extra"
@export var texture: Texture2D
@export var portrait: Texture2D
@export var chroma_key: bool = false
@export var tint: Color = Color.WHITE
@export var skills: Array[BattleSkill] = []
