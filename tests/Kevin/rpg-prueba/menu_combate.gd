extends CanvasLayer

@onready var menu_principal = $Panel/VBoxContainer
@onready var menu_armas = $Panel/MenuArmas

@onready var combate_espada = $CombateEspada
@onready var combate_dagas = $CombateDagas


func _ready():
	menu_armas.hide()
	combate_espada.hide()
	combate_dagas.hide()
	
	combate_espada.ataque_finalizado.connect(_on_ataque_finalizado)
	combate_dagas.ataque_finalizado.connect(_on_ataque_finalizado)


func _on_combatir_pressed():
	menu_principal.hide()
	menu_armas.show()


func _on_espada_pressed() -> void:
	menu_armas.hide()
	combate_espada.show()
	combate_espada.iniciar_ataque()


func _on_dagas_pressed() -> void:
	menu_armas.hide()
	combate_dagas.show()
	combate_dagas.iniciar_ataque()


func _on_ataque_finalizado():
	menu_principal.show()



# ============================================================
# CODIGO VIEJO - BACKUP ANTES DE SEPARAR LOS MINIJUEGOS
# ============================================================
#extends CanvasLayer
##Onready de la espada
#@onready var menu_principal = $Panel/VBoxContainer
#@onready var menu_armas = $Panel/MenuArmas
#@onready var combate_espada = $CombateEspada
#
##Onready de las Dagas
#@onready var combate_dagas = $CombateDagas
##@onready var indicador_dagas = $CombateDagas/Indicador
##@onready var barra_dagas = $CombateDagas/BarraDagas
#
##Variables ESPADA
##var velocidad_indicador = 300.0  #Nos indica que tan rapido se mueve la barra
##var direccion_indicador = 1      #Nos indica la direccion en la que se mueve la barra, 1 derecha, -1 izquierda
##var indicador_activo = true #Esta variable nos sirve para saber si el ataque esta detenido.
#
##Variables DAGAS
##var velocidad_indicador_dagas = 300.0
##var indicador_dagas_activo = false
##var aciertos_dagas = 0
##var zonas_dagas_acertadas = [false, false, false, false, false]
##var zonas_dagas_procesadas = [false, false, false, false, false]
#
#func _ready():
	#menu_armas.hide()
	#combate_espada.hide()
	#combate_dagas.hide()
	#
	#combate_espada.ataque_finalizado.connect(_on_ataque_finalizado)
	#combate_dagas.ataque_finalizado.connect(_on_ataque_finalizado)
#
##func _process(delta):
	##if combate_espada.visible and indicador_activo:
		##var indicador = $CombateEspada/Indicador
		##
		##indicador.position.x += velocidad_indicador * direccion_indicador * delta
		##
		##if indicador.position.x >= 495:
			##direccion_indicador = -1
		##
		##if indicador.position.x <= 0:
			##direccion_indicador = 1
	##if combate_dagas.visible and indicador_dagas_activo:
		##indicador_dagas.position.x += velocidad_indicador_dagas * delta
		##
		##comprobar_zonas_pasadas_dagas()
		##
		##var final_barra = barra_dagas.position.x + barra_dagas.size.x - indicador_dagas.size.x
		##
		##if indicador_dagas.position.x >= final_barra:
			##indicador_dagas.position.x = final_barra
			##indicador_dagas_activo = false
			##finalizar_dagas()
#
#func _on_combatir_pressed():
	#menu_principal.hide()
	#menu_armas.show()
#
#func _on_espada_pressed() -> void:
	#menu_armas.hide()
	#combate_espada.show()
	#combate_espada.iniciar.ataque()
	##indicador_activo = true
#
#func _on_dagas_pressed() -> void:
	#menu_armas.hide()
	#combate_dagas.show()
	#combate_dagas.iniciar_ataque()
	#
	##aciertos_dagas = 0
	##zonas_dagas_acertadas = [false, false, false, false, false]
	##zonas_dagas_procesadas = [false, false, false, false, false]
	##
	##indicador_dagas.position.x = barra_dagas.position.x
	##indicador_dagas_activo = true
#
##func _input(event):
	##if combate_espada.visible:
		##if event.is_action_pressed("ui_accept"):
			##detener_indicador()
	##if combate_dagas.visible and indicador_dagas_activo:
		##if event.is_action_pressed("ui_accept"):
			##comprobar_golpe_dagas()
#
##func detener_indicador():
	##indicador_activo = false
	##
	##var indicador = $CombateEspada/Indicador
	##var zona = $CombateEspada/ZonaPrecision
	##
	##var indicador_inicio = indicador.position.x
	##var indicador_final = indicador.position.x + indicador.size.x
	##
	##var zona_inicio = zona.position.x
	##var zona_final = zona.position.x + zona.size.x
	##
	##if indicador_final >= zona_inicio and indicador_inicio <= zona_final:
		##print("¡GOLPE PRECISO!")
	##else:
		##print("¡FALLO!")
	##
	##finalizar_espada()
#
##func comprobar_golpe_dagas():
	##var zonas = [
		##$CombateDagas/Zona1,
		##$CombateDagas/Zona2,
		##$CombateDagas/Zona3,
		##$CombateDagas/Zona4,
		##$CombateDagas/Zona5
	##]
	##
	##var indicador_inicio = indicador_dagas.position.x
	##var indicador_final = indicador_dagas.position.x + indicador_dagas.size.x
	##
	##for i in range(zonas.size()):
		##var zona = zonas[i]
		##
		##var zona_inicio = zona.position.x
		##var zona_final = zona.position.x + zona.size.x
		##
		##if indicador_final >= zona_inicio and indicador_inicio <= zona_final:
			##
			##if zonas_dagas_acertadas[i] == false:
				##zonas_dagas_acertadas[i] = true
				##zonas_dagas_procesadas[i] = true
				##aciertos_dagas += 1
				##
				##print("¡GOLPE ACERTADO! Zona ", i + 1)
				##print("Aciertos: ", aciertos_dagas)
			##
			##return
	##
	##print("¡FALLO!")
#
##func comprobar_zonas_pasadas_dagas():
	##var zonas = [
		##$CombateDagas/Zona1,
		##$CombateDagas/Zona2,
		##$CombateDagas/Zona3,
		##$CombateDagas/Zona4,
		##$CombateDagas/Zona5
	##]
	##
	##for i in range(zonas.size()):
		##var zona = zonas[i]
		##var zona_final = zona.position.x + zona.size.x
		##
		##if indicador_dagas.position.x > zona_final and zonas_dagas_procesadas[i] == false:
			##zonas_dagas_procesadas[i] = true
			##
			##if zonas_dagas_acertadas[i] == false:
				##print("¡FALLASTE LA ZONA ", i + 1, "!")
#
##func finalizar_espada():
	##print("FIN DEL ATAQUE")
	##
	##await get_tree().create_timer(3.0).timeout
	##
	##combate_espada.hide()
	##menu_principal.show()
#
##func finalizar_dagas():
	##print("FIN DEL ATAQUE")
	##print("Aciertos totales: ", aciertos_dagas, "/5")
	##
	##await get_tree().create_timer(2.0).timeout
	##
	##combate_dagas.hide()
	##menu_principal.show()
#
#func _on_ataque_finalizado():
	#menu_principal.show()
