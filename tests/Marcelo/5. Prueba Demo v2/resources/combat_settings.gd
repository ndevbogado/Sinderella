class_name CombatSettings
extends Resource

## Configuración central de dificultad. Editá default_combat_settings.tres
## desde el Inspector; la arena aplica estos valores al comenzar.

@export_category("Estadísticas — Cenicienta")
@export_range(1.0, 10000.0, 1.0) var vida_cenicienta: float = 120.0
@export_range(0.0, 10000.0, 1.0) var ataque_cenicienta: float = 25.0
@export_range(0.0, 10000.0, 1.0) var defensa_cenicienta: float = 50.0

@export_category("Estadísticas — Caperucita")
@export_range(1.0, 10000.0, 1.0) var vida_caperucita: float = 360.0
@export_range(0.0, 10000.0, 1.0) var ataque_caperucita: float = 100.0
@export_range(0.0, 10000.0, 1.0) var defensa_caperucita: float = 25.0

@export_category("Timing de ataque")
@export_range(0.2, 3.0, 0.05) var velocidad_marcador: float = 1.15
@export_range(1.0, 40.0, 0.5, "suffix:%") var ancho_zona_buena: float = 16.0
@export_range(0.5, 20.0, 0.5, "suffix:%") var ancho_zona_perfecta: float = 5.5

@export_category("Defensa con teclas")
@export_range(1, 12, 1) var cantidad_teclas: int = 6
@export_range(0.2, 3.0, 0.05, "suffix:s") var tiempo_por_tecla: float = 0.7
@export_range(0.05, 0.6, 0.05, "suffix:s") var tiempo_resultado_tecla: float = 0.18
@export_range(1.0, 25.0, 0.5, "suffix:%") var reduccion_por_acierto: float = 12.5
@export var letras_permitidas: String = "WASD"
@export var incluir_flechas: bool = true

@export_category("Avisos de turno")
@export_range(0.5, 1.6, 0.05, "suffix:s") var duracion_aviso: float = 1.2
@export_range(0.05, 0.2, 0.01, "suffix:s") var fundido_aviso: float = 0.15
