extends CanvasLayer

var label_oleada: Label
var barra_vida: ProgressBar
var barra_esencia: ProgressBar
var label_monedas: Label

var panel_nivel: Panel
var contenedor_opciones: HBoxContainer

var panel_tienda: Panel
var contenedor_tienda: HBoxContainer
var btn_reroll: Button
var btn_siguiente_oleada: Button
var coste_reroll: int = 5

var panel_pausa: Panel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	crear_hud()
	crear_modal_subida_nivel()
	crear_modal_tienda()
	crear_modal_pausa()
	
	Eventos.jugador_daniado.connect(actualizar_vida)
	Eventos.jugador_curado.connect(actualizar_vida)
	Eventos.esencia_actualizada.connect(actualizar_esencia)
	Eventos.monedas_actualizadas.connect(actualizar_monedas)
	Eventos.tiempo_oleada_actualizado.connect(actualizar_tiempo)
	Eventos.abrir_subida_nivel.connect(mostrar_subida_nivel)
	Eventos.abrir_tienda.connect(mostrar_tienda)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			alternar_pausa()

func crear_hud() -> void:
	label_oleada = Label.new()
	label_oleada.position = Vector2(40, 20)
	label_oleada.text = "OLEADA 1 | 00:45"
	add_child(label_oleada)
	
	barra_vida = ProgressBar.new()
	barra_vida.size = Vector2(250, 20)
	barra_vida.position = Vector2(40, 50)
	barra_vida.max_value = 100.0
	barra_vida.value = 100.0
	add_child(barra_vida)
	
	barra_esencia = ProgressBar.new()
	barra_esencia.size = Vector2(250, 10)
	barra_esencia.position = Vector2(40, 75)
	barra_esencia.max_value = 20.0
	barra_esencia.value = 0.0
	add_child(barra_esencia)
	
	label_monedas = Label.new()
	label_monedas.position = Vector2(40, 95)
	label_monedas.text = "Monedas: 0"
	add_child(label_monedas)

func crear_modal_subida_nivel() -> void:
	panel_nivel = Panel.new()
	panel_nivel.size = Vector2(650, 280)
	panel_nivel.position = Vector2(300, 200)
	panel_nivel.visible = false
	add_child(panel_nivel)
	
	var tit := Label.new()
	tit.text = "¡SUBIDA DE NIVEL! ELIGE UNA MEJORA:"
	tit.position = Vector2(170, 20)
	panel_nivel.add_child(tit)
	
	contenedor_opciones = HBoxContainer.new()
	contenedor_opciones.position = Vector2(30, 80)
	contenedor_opciones.size = Vector2(590, 160)
	panel_nivel.add_child(contenedor_opciones)

func mostrar_subida_nivel(_pendientes: int) -> void:
	for c in contenedor_opciones.get_children():
		c.queue_free()
		
	var pool: Array[Dictionary] = DatosJuego.MEJORAS_STATS.duplicate()
	pool.shuffle()
	
	for i in range(min(3, pool.size())):
		var mej: Dictionary = pool[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(180, 140)
		btn.text = mej["nombre"]
		btn.pressed.connect(func():
			Eventos.mejora_seleccionada.emit(mej)
			panel_nivel.visible = false
		)
		contenedor_opciones.add_child(btn)
		
	panel_nivel.visible = true

func crear_modal_tienda() -> void:
	panel_tienda = Panel.new()
	panel_tienda.size = Vector2(800, 380)
	panel_tienda.position = Vector2(240, 160)
	panel_tienda.visible = false
	add_child(panel_tienda)
	
	var tit := Label.new()
	tit.text = "TIENDA INFERNAL"
	tit.position = Vector2(340, 15)
	panel_tienda.add_child(tit)
	
	contenedor_tienda = HBoxContainer.new()
	contenedor_tienda.position = Vector2(40, 60)
	contenedor_tienda.size = Vector2(720, 220)
	panel_tienda.add_child(contenedor_tienda)
	
	btn_reroll = Button.new()
	btn_reroll.size = Vector2(150, 40)
	btn_reroll.position = Vector2(40, 310)
	btn_reroll.text = "Reroll (%d G)" % coste_reroll
	btn_reroll.pressed.connect(_al_pulsar_reroll)
	panel_tienda.add_child(btn_reroll)
	
	btn_siguiente_oleada = Button.new()
	btn_siguiente_oleada.size = Vector2(180, 40)
	btn_siguiente_oleada.position = Vector2(580, 310)
	btn_siguiente_oleada.text = "Siguiente Oleada"
	btn_siguiente_oleada.pressed.connect(func():
		panel_tienda.visible = false
		Eventos.cerrar_tienda.emit()
	)
	panel_tienda.add_child(btn_siguiente_oleada)

func mostrar_tienda() -> void:
	coste_reroll = 5
	btn_reroll.text = "Reroll (%d G)" % coste_reroll
	generar_articulos_tienda()
	panel_tienda.visible = true

func generar_articulos_tienda() -> void:
	for c in contenedor_tienda.get_children():
		c.queue_free()
		
	var llaves: Array = DatosJuego.CATALOGO_ARMAS.keys()
	llaves.shuffle()
	
	for i in range(min(4, llaves.size())):
		var clave: String = llaves[i]
		var item: Dictionary = DatosJuego.CATALOGO_ARMAS[clave]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(165, 200)
		btn.text = "%s\nTier I\nPrecio: %d G" % [item["nombre"], item["precio"]]
		btn.pressed.connect(func():
			Eventos.arma_comprada.emit({"clave": clave, "precio": item["precio"]})
			btn.disabled = true
			btn.text = "COMPRADO"
		)
		contenedor_tienda.add_child(btn)

func _al_pulsar_reroll() -> void:
	var escena = get_tree().current_scene
	if escena.get("monedas_totales") >= coste_reroll:
		escena.monedas_totales -= coste_reroll
		coste_reroll += 5
		btn_reroll.text = "Reroll (%d G)" % coste_reroll
		actualizar_monedas(escena.monedas_totales)
		generar_articulos_tienda()

func crear_modal_pausa() -> void:
	panel_pausa = Panel.new()
	panel_pausa.size = Vector2(360, 240)
	panel_pausa.position = Vector2(460, 240)
	panel_pausa.visible = false
	add_child(panel_pausa)
	
	var tit := Label.new()
	tit.text = "JUEGO EN PAUSA"
	tit.position = Vector2(120, 25)
	panel_pausa.add_child(tit)
	
	var btn_reanudar := Button.new()
	btn_reanudar.size = Vector2(260, 40)
	btn_reanudar.position = Vector2(50, 75)
	btn_reanudar.text = "Reanudar"
	btn_reanudar.pressed.connect(alternar_pausa)
	panel_pausa.add_child(btn_reanudar)
	
	var btn_menu := Button.new()
	btn_menu.size = Vector2(260, 40)
	btn_menu.position = Vector2(50, 135)
	btn_menu.text = "Volver al Menú Principal"
	btn_menu.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
	)
	panel_pausa.add_child(btn_menu)

func alternar_pausa() -> void:
	if panel_nivel.visible or panel_tienda.visible:
		return
		
	var estado := not get_tree().paused
	get_tree().paused = estado
	panel_pausa.visible = estado

func actualizar_vida(cur: float, mx: float) -> void:
	barra_vida.max_value = mx
	barra_vida.value = cur

func actualizar_esencia(cur: int, req: int, _n: int) -> void:
	barra_esencia.max_value = req
	barra_esencia.value = cur

func actualizar_monedas(m: int) -> void:
	label_monedas.text = "Monedas: %d" % m

func actualizar_tiempo(t: float) -> void:
	var escena = get_tree().current_scene
	var ol: int = escena.get("oleada_actual") if escena else 1
	label_oleada.text = "OLEADA %d | 00:%02d" % [ol, max(0, int(t))]
