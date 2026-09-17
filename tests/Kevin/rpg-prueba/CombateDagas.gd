extends Control

signal ataque_finalizado

@onready var indicador = $Indicador
@onready var barra_dagas = $BarraDagas

@onready var zonas = [
	$Zona1,
	$Zona2,
	$Zona3,
	$Zona4,
	$Zona5
]

var velocidad_indicador = 300.0
var indicador_activo = false

var aciertos = 0
var zonas_acertadas = [false, false, false, false, false]
var zonas_procesadas = [false, false, false, false, false]


func _process(delta):
	if visible and indicador_activo:
		indicador.position.x += velocidad_indicador * delta
		
		comprobar_zonas_pasadas()
		
		var final_barra = barra_dagas.position.x + barra_dagas.size.x - indicador.size.x
		
		if indicador.position.x >= final_barra:
			indicador.position.x = final_barra
			indicador_activo = false
			finalizar_dagas()


func _input(event):
	if visible and indicador_activo:
		if event.is_action_pressed("ui_accept"):
			comprobar_golpe()


func iniciar_ataque():
	aciertos = 0
	
	zonas_acertadas = [
		false,
		false,
		false,
		false,
		false
	]
	
	zonas_procesadas = [
		false,
		false,
		false,
		false,
		false
	]
	
	indicador.position.x = barra_dagas.position.x
	indicador_activo = true


func comprobar_golpe():
	var indicador_inicio = indicador.position.x
	var indicador_final = indicador.position.x + indicador.size.x
	
	for i in range(zonas.size()):
		var zona = zonas[i]
		
		var zona_inicio = zona.position.x
		var zona_final = zona.position.x + zona.size.x
		
		if indicador_final >= zona_inicio and indicador_inicio <= zona_final:
			
			if zonas_acertadas[i] == false:
				zonas_acertadas[i] = true
				zonas_procesadas[i] = true
				aciertos += 1
				
				print("¡GOLPE ACERTADO! Zona ", i + 1)
				print("Aciertos: ", aciertos)
			
			return
	
	print("¡FALLO!")


func comprobar_zonas_pasadas():
	for i in range(zonas.size()):
		var zona = zonas[i]
		var zona_final = zona.position.x + zona.size.x
		
		if indicador.position.x > zona_final and zonas_procesadas[i] == false:
			zonas_procesadas[i] = true
			
			if zonas_acertadas[i] == false:
				print("¡FALLASTE LA ZONA ", i + 1, "!")


func finalizar_dagas():
	indicador_activo = false
	
	print("FIN DEL ATAQUE")
	print("Aciertos totales: ", aciertos, "/5")
	
	await get_tree().create_timer(2.0).timeout
	
	hide()
	ataque_finalizado.emit()
