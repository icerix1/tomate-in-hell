extends Node2D

const SCRIPT_JUGADOR = preload("res://Jugador.gd")
const SCRIPT_DEMONIO = preload("res://Demonio.gd")
const SCRIPT_UI = preload("res://Interfaz.gd")

var oleada_actual: int = 1
var tiempo_oleada: float = 45.0
var temporizador_spawn: float = 0.0

var esencia_total: int = 0
var monedas_totales: int = 0
var nivel_actual: int = 1
var esencia_siguiente_nivel: int = 20
var subidas_pendientes: int = 0

var ref_jugador: CharacterBody2D = null
var en_pausa_intermedia: bool = false

# Perímetro interior seguro de la arena (paredes en -1000 a 1000 y -562 a 562)
const ARENA_MIN_X: float = -920.0
const ARENA_MAX_X: float = 920.0
const ARENA_MIN_Y: float = -490.0
const ARENA_MAX_Y: float = 490.0

func _ready() -> void:
	crear_arena()
	crear_jugador()
	
	var ui := CanvasLayer.new()
	ui.set_script(SCRIPT_UI)
	add_child(ui)
	
	Eventos.enemigo_muerto.connect(_al_enemigo_muerto)
	Eventos.mejora_seleccionada.connect(_al_elegir_mejora)
	Eventos.arma_comprada.connect(_al_comprar_arma)
	Eventos.cerrar_tienda.connect(iniciar_siguiente_oleada)
	Eventos.jugador_murio.connect(func(): get_tree().reload_current_scene())
	
	iniciar_oleada(oleada_actual)

func crear_arena() -> void:
	var limites := StaticBody2D.new()
	limites.collision_layer = 1
	var rect := Rect2(-1000, -562, 2000, 1125)
	
	var config_bordes: Array = [
		[Vector2(0, rect.position.y), Vector2(rect.size.x, 32)],
		[Vector2(0, rect.end.y), Vector2(rect.size.x, 32)],
		[Vector2(rect.position.x, 0), Vector2(32, rect.size.y)],
		[Vector2(rect.end.x, 0), Vector2(32, rect.size.y)]
	]
	for c in config_bordes:
		var col := CollisionShape2D.new()
		var forma := RectangleShape2D.new()
		forma.size = c[1]
		col.shape = forma
		col.position = c[0]
		limites.add_child(col)
	add_child(limites)

func crear_jugador() -> void:
	ref_jugador = CharacterBody2D.new()
	ref_jugador.set_script(SCRIPT_JUGADOR)
	ref_jugador.position = Vector2.ZERO
	add_child(ref_jugador)
	
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.zoom = Vector2(1.05, 1.05)
	ref_jugador.add_child(cam)

func iniciar_oleada(num: int) -> void:
	oleada_actual = num
	tiempo_oleada = DatosJuego.duracion_oleada(oleada_actual)
	en_pausa_intermedia = false
	temporizador_spawn = 0.5
	
	var ciclo_15: int = oleada_actual % 15
	if ciclo_15 == 5:
		spawnear_demonio(SCRIPT_DEMONIO.Categoria.MINIBOSS)
	elif ciclo_15 == 10:
		spawnear_demonio(SCRIPT_DEMONIO.Categoria.BOSS)
	elif ciclo_15 == 0:
		spawnear_demonio(SCRIPT_DEMONIO.Categoria.MINIBOSS)
		spawnear_demonio(SCRIPT_DEMONIO.Categoria.BOSS)

func _physics_process(delta: float) -> void:
	if en_pausa_intermedia: return
	
	tiempo_oleada -= delta
	Eventos.tiempo_oleada_actualizado.emit(tiempo_oleada)
	
	temporizador_spawn -= delta
	if temporizador_spawn <= 0.0 and tiempo_oleada > 0.0:
		var vivos: int = get_tree().get_nodes_in_group("demonios").size()
		if vivos < 160:
			spawnear_horda_oleada()
		temporizador_spawn = max(0.2, 0.9 - (oleada_actual * 0.015))
		
	if tiempo_oleada <= 0.0:
		verificar_fin_oleada()

func spawnear_horda_oleada() -> void:
	var suerte: float = randf()
	var cat: SCRIPT_DEMONIO.Categoria = SCRIPT_DEMONIO.Categoria.DIABLILLO
	if oleada_actual >= 2 and suerte < 0.25:
		cat = SCRIPT_DEMONIO.Categoria.CORREDOR
	elif oleada_actual >= 3 and suerte < 0.40:
		cat = SCRIPT_DEMONIO.Categoria.BRUTO
		
	var es_elite: bool = (oleada_actual >= 8) and (randf() < 0.06)
	spawnear_demonio(cat, es_elite)

func spawnear_demonio(cat: SCRIPT_DEMONIO.Categoria, elite: bool = false) -> void:
	if not ref_jugador: return
	
	var pos_elegida := Vector2.ZERO
	var encontrada := false
	
	# Buscar una posición que esté dentro de la arena y a más de 350px del jugador
	for i in range(16):
		var ang: float = randf() * TAU
		var dist: float = randf_range(360.0, 600.0)
		var candidato: Vector2 = ref_jugador.global_position + Vector2.from_angle(ang) * dist
		
		if candidato.x >= ARENA_MIN_X and candidato.x <= ARENA_MAX_X and candidato.y >= ARENA_MIN_Y and candidato.y <= ARENA_MAX_Y:
			pos_elegida = candidato
			encontrada = true
			break
			
	# Si el jugador está arrinconado, generar aleatoriamente en el mapa lejos del jugador
	if not encontrada:
		var pos_aleatoria := Vector2(
			randf_range(ARENA_MIN_X, ARENA_MAX_X),
			randf_range(ARENA_MIN_Y, ARENA_MAX_Y)
		)
		if pos_aleatoria.distance_to(ref_jugador.global_position) < 350.0:
			var dir_lejos: Vector2 = (pos_aleatoria - ref_jugador.global_position).normalized()
			if dir_lejos == Vector2.ZERO:
				dir_lejos = Vector2.UP
			pos_elegida = ref_jugador.global_position + dir_lejos * 380.0
			pos_elegida.x = clamp(pos_elegida.x, ARENA_MIN_X, ARENA_MAX_X)
			pos_elegida.y = clamp(pos_elegida.y, ARENA_MIN_Y, ARENA_MAX_Y)
		else:
			pos_elegida = pos_aleatoria
			
	var d := CharacterBody2D.new()
	d.set_script(SCRIPT_DEMONIO)
	d.global_position = pos_elegida
	d.configurar(cat, oleada_actual, elite)
	add_child(d)

func verificar_fin_oleada() -> void:
	var demonios = get_tree().get_nodes_in_group("demonios")
	var jefes_vivos: bool = false
	for d in demonios:
		if is_instance_valid(d) and (d.get("categoria") == SCRIPT_DEMONIO.Categoria.BOSS or d.get("categoria") == SCRIPT_DEMONIO.Categoria.MINIBOSS):
			jefes_vivos = true
			break
			
	if not jefes_vivos:
		for d in demonios:
			if is_instance_valid(d): d.queue_free()
		abrir_fase_recompensas()

func abrir_fase_recompensas() -> void:
	en_pausa_intermedia = true
	if subidas_pendientes > 0:
		Eventos.abrir_subida_nivel.emit(subidas_pendientes)
	else:
		Eventos.abrir_tienda.emit()

func _al_elegir_mejora(mejora: Dictionary) -> void:
	if ref_jugador:
		ref_jugador.aplicar_mejora(mejora)
	subidas_pendientes -= 1
	if subidas_pendientes > 0:
		Eventos.abrir_subida_nivel.emit(subidas_pendientes)
	else:
		Eventos.abrir_tienda.emit()

func _al_comprar_arma(item: Dictionary) -> void:
	var precio: int = item.get("precio", 0)
	if monedas_totales >= precio:
		if ref_jugador and ref_jugador.anadir_o_mejorar_arma(item.get("clave", "pistola")):
			monedas_totales -= precio
			Eventos.monedas_actualizadas.emit(monedas_totales)

func iniciar_siguiente_oleada() -> void:
	iniciar_oleada(oleada_actual + 1)

func _al_enemigo_muerto(_pos: Vector2, es: int, mon: int, _boss: bool) -> void:
	if es > 0:
		esencia_total += es
		if esencia_total >= esencia_siguiente_nivel:
			esencia_total -= esencia_siguiente_nivel
			nivel_actual += 1
			subidas_pendientes += 1
			esencia_siguiente_nivel = DatosJuego.calcular_coste_nivel(nivel_actual)
		Eventos.esencia_actualizada.emit(esencia_total, esencia_siguiente_nivel, nivel_actual)
		
	if mon > 0:
		monedas_totales += mon
		Eventos.monedas_actualizadas.emit(monedas_totales)

func _draw() -> void:
	draw_rect(Rect2(-1000, -562, 2000, 1125), Color(0.12, 0.08, 0.09))
	draw_rect(Rect2(-1000, -562, 2000, 1125), Color(0.85, 0.25, 0.1, 0.8), false, 4.0)
