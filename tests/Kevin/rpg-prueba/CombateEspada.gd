extends Control

signal ataque_finalizado

@onready var indicador = $Indicador
@onready var zona_precision = $ZonaPrecision

var velocidad_indicador = 300.0
var direccion_indicador = 1
var indicador_activo = false


func _process(delta):
	if visible and indicador_activo:
		indicador.position.x += velocidad_indicador * direccion_indicador * delta
		
		if indicador.position.x >= 495:
			direccion_indicador = -1
		
		if indicador.position.x <= 0:
			direccion_indicador = 1


func _input(event):
	if visible and indicador_activo:
		if event.is_action_pressed("ui_accept"):
			detener_indicador()


func iniciar_ataque():
	indicador_activo = true
	direccion_indicador = 1


func detener_indicador():
	indicador_activo = false
	
	var indicador_inicio = indicador.position.x
	var indicador_final = indicador.position.x + indicador.size.x
	
	var zona_inicio = zona_precision.position.x
	var zona_final = zona_precision.position.x + zona_precision.size.x
	
	if indicador_final >= zona_inicio and indicador_inicio <= zona_final:
		print("¡GOLPE PRECISO!")
	else:
		print("¡FALLO!")
	
	finalizar_espada()


func finalizar_espada():
	print("FIN DEL ATAQUE")
	
	await get_tree().create_timer(3.0).timeout
	
	hide()
	ataque_finalizado.emit()
