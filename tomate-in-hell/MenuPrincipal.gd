extends Control

var panel_inicio: Control
var panel_seleccion: Control
var grid_personajes: GridContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var fondo := ColorRect.new()
	fondo.color = Color(0.10, 0.05, 0.06)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	
	crear_pantalla_inicio()
	crear_pantalla_seleccion()

func crear_pantalla_inicio() -> void:
	var tam := get_viewport_rect().size
	
	panel_inicio = Control.new()
	panel_inicio.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_inicio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel_inicio)
	
	var label_titulo := Label.new()
	label_titulo.text = "TOMATO IN HELL"
	label_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_titulo.size = Vector2(tam.x, 80)
	label_titulo.position = Vector2(0, tam.y * 0.16)
	label_titulo.add_theme_font_size_override("font_size", 56)
	label_titulo.add_theme_color_override("font_color", Color(0.95, 0.22, 0.15))
	label_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_inicio.add_child(label_titulo)
	
	var label_subtitulo := Label.new()
	label_subtitulo.text = "SOBREVIVE A LAS HORDAS DEL INFIERNO"
	label_subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_subtitulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_subtitulo.size = Vector2(tam.x, 30)
	label_subtitulo.position = Vector2(0, tam.y * 0.28)
	label_subtitulo.add_theme_font_size_override("font_size", 16)
	label_subtitulo.add_theme_color_override("font_color", Color(0.85, 0.65, 0.25))
	label_subtitulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_inicio.add_child(label_subtitulo)
	
	var btn_jugar := Button.new()
	btn_jugar.text = "JUGAR"
	btn_jugar.size = Vector2(240, 52)
	btn_jugar.position = Vector2((tam.x - 240) * 0.5, tam.y * 0.44)
	btn_jugar.add_theme_font_size_override("font_size", 22)
	btn_jugar.pressed.connect(func():
		panel_inicio.visible = false
		panel_seleccion.visible = true
	)
	panel_inicio.add_child(btn_jugar)
	
	var btn_salir := Button.new()
	btn_salir.text = "SALIR"
	btn_salir.size = Vector2(240, 48)
	btn_salir.position = Vector2((tam.x - 240) * 0.5, tam.y * 0.56)
	btn_salir.add_theme_font_size_override("font_size", 18)
	btn_salir.pressed.connect(func():
		get_tree().quit()
	)
	panel_inicio.add_child(btn_salir)

func crear_pantalla_seleccion() -> void:
	var tam := get_viewport_rect().size
	
	panel_seleccion = Control.new()
	panel_seleccion.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_seleccion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_seleccion.visible = false
	add_child(panel_seleccion)
	
	var tit_sel := Label.new()
	tit_sel.text = "SELECCIONA TU TOMATE"
	tit_sel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit_sel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tit_sel.size = Vector2(tam.x, 50)
	tit_sel.position = Vector2(0, tam.y * 0.04)
	tit_sel.add_theme_font_size_override("font_size", 28)
	tit_sel.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	tit_sel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_seleccion.add_child(tit_sel)
	
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(tam.x * 0.06, tam.y * 0.12)
	scroll.size = Vector2(tam.x * 0.88, tam.y * 0.72)
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	panel_seleccion.add_child(scroll)
	
	grid_personajes = GridContainer.new()
	grid_personajes.columns = 4
	grid_personajes.add_theme_constant_override("h_separation", 14)
	grid_personajes.add_theme_constant_override("v_separation", 14)
	grid_personajes.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(grid_personajes)
	
	poblar_grilla_personajes()
	
	var btn_volver := Button.new()
	btn_volver.text = "VOLVER"
	btn_volver.size = Vector2(200, 44)
	btn_volver.position = Vector2((tam.x - 200) * 0.5, tam.y * 0.88)
	btn_volver.add_theme_font_size_override("font_size", 18)
	btn_volver.pressed.connect(func():
		panel_seleccion.visible = false
		panel_inicio.visible = true
	)
	panel_seleccion.add_child(btn_volver)

func poblar_grilla_personajes() -> void:
	for c in grid_personajes.get_children():
		c.queue_free()
		
	var tam := get_viewport_rect().size
	var ancho_boton: float = (tam.x * 0.88 - 60) / 4.0
	
	var claves: Array = DatosJuego.CATALOGO_PERSONAJES.keys()
	for clave: String in claves:
		var datos: Dictionary = DatosJuego.CATALOGO_PERSONAJES[clave]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(ancho_boton, 110)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		btn.text = "%s\nVida: %d HP\nArma: %s\n%s" % [
			datos["nombre"],
			int(datos["hp"]),
			datos["arma"].capitalize(),
			datos["desc"]
		]
		
		# Conexión directa mediante bind para evitar problemas de captura en bucle
		btn.pressed.connect(_al_seleccionar_personaje.bind(datos))
		grid_personajes.add_child(btn)

func _al_seleccionar_personaje(datos: Dictionary) -> void:
	print("Seleccionado: ", datos["nombre"])
	DatosJuego.personaje_actual = datos
	entrar_a_la_arena()

func entrar_a_la_arena() -> void:
	get_tree().paused = false
	
	# 1. Intentar cargar mediante la escena empaquetada si está disponible
	if ResourceLoader.exists("res://Principal.tscn"):
		var escena_recurso = load("res://Principal.tscn")
		if escena_recurso is PackedScene:
			var error := get_tree().change_scene_to_packed(escena_recurso)
			if error == OK:
				return
	
	# 2. Carga directa por script: no depende de archivos .tscn ni de configuraciones de nodo
	print("Instanciando Principal.gd directamente en memoria...")
	var script_principal = load("res://Principal.gd")
	if script_principal:
		var juego := Node2D.new()
		juego.name = "Principal"
		juego.set_script(script_principal)
		
		var root := get_tree().root
		var escena_actual := get_tree().current_scene
		
		root.add_child(juego)
		get_tree().current_scene = juego
		
		if escena_actual:
			escena_actual.queue_free()
	else:
		printerr("Error crítico: No se encontró res://Principal.gd")
