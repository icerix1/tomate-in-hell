extends Node2D

const SCRIPT_BALA = preload("res://Bala.gd")

var clave_arma: String = "pistola"
var nombre_arma: String = "Pistola 9 mm"
var tipo: String = "pistola"
var tier: int = 1
var danio_base: float = 22.0
var cadencia: float = 2.5
var alcance: float = 700.0
var velocidad_bala: float = 1200.0
var critico_base: float = 0.05
var mult_critico: float = 1.5
var penetracion: int = 0
var perdigones: int = 1

var angulo_asistencia: float = deg_to_rad(45.0)
var velocidad_giro: float = 18.0

var temporizador_disparo: float = 0.0
var objetivo_actual: Node2D = null

func configurar(datos: Dictionary, nuevo_tier: int = 1) -> void:
	clave_arma = datos.get("clave", "pistola")
	nombre_arma = datos.get("nombre", "Pistola")
	tipo = datos.get("tipo", "pistola")
	tier = nuevo_tier
	
	var mult_tier: float = 1.0
	match tier:
		1: mult_tier = 1.0
		2: mult_tier = 1.25
		3: mult_tier = 1.60
		4: mult_tier = 2.10
		5: mult_tier = 2.80
		
	danio_base = datos.get("danio_base", 20.0) * mult_tier
	cadencia = datos.get("cadencia", 2.0)
	alcance = datos.get("alcance", 700.0)
	velocidad_bala = datos.get("velocidad_bala", 1100.0)
	critico_base = datos.get("critico", 0.05)
	mult_critico = datos.get("mult_critico", 1.5)
	penetracion = datos.get("penetracion", 0)
	perdigones = datos.get("perdigones", 1)
	
	if tipo == "pesada":
		velocidad_giro = 8.0
		angulo_asistencia = deg_to_rad(30.0)
	elif tipo == "escopeta":
		velocidad_giro = 14.0
		angulo_asistencia = deg_to_rad(50.0)
	else:
		velocidad_giro = 18.0
		angulo_asistencia = deg_to_rad(45.0)
		
	queue_redraw()

func _physics_process(delta: float) -> void:
	if temporizador_disparo > 0.0:
		temporizador_disparo -= delta
		
	procesar_asistencia_apuntado(delta)

func procesar_asistencia_apuntado(delta: float) -> void:
	var pos_raton: Vector2 = get_global_mouse_position()
	var dir_preferente: Vector2 = (pos_raton - global_position).normalized()
	var angulo_deseado: float = dir_preferente.angle()
	
	var demonios: Array[Node] = get_tree().get_nodes_in_group("demonios")
	var mejor_objetivo: Node2D = null
	var mejor_alineacion: float = cos(angulo_asistencia)
	
	for d: Node in demonios:
		if not is_instance_valid(d): continue
		var d2d := d as Node2D
		var hacia_enemigo: Vector2 = d2d.global_position - global_position
		var distancia: float = hacia_enemigo.length()
		
		if distancia <= alcance:
			var dir_enemigo: Vector2 = hacia_enemigo.normalized()
			var alineacion: float = dir_preferente.dot(dir_enemigo)
			
			if alineacion > mejor_alineacion:
				mejor_alineacion = alineacion
				mejor_objetivo = d2d
				
	objetivo_actual = mejor_objetivo
	
	if objetivo_actual and is_instance_valid(objetivo_actual):
		angulo_deseado = (objetivo_actual.global_position - global_position).angle()
		
	rotation = lerp_angle(rotation, angulo_deseado, velocidad_giro * delta)

func puede_disparar() -> bool:
	return temporizador_disparo <= 0.0

func ejecutar_disparo() -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	var mult_danio: float = jugador.danio_mult if jugador else 1.0
	var cadencia_jugador: float = jugador.cadencia_mult if jugador else 1.0
	var prob_crit: float = clamp(critico_base + (jugador.critico_extra if jugador else 0.0), 0.0, 1.0)
	
	var cadencia_final: float = min(cadencia * cadencia_jugador, cadencia * 4.0)
	temporizador_disparo = 1.0 / max(cadencia_final, 0.1)
	
	for i in range(perdigones):
		var dispersio_ang: float = 0.0
		if perdigones > 1:
			dispersio_ang = deg_to_rad(randf_range(-14.0, 14.0))
			
		var bala := Area2D.new()
		bala.set_script(SCRIPT_BALA)
		bala.global_position = global_position + Vector2.RIGHT.rotated(rotation) * 16.0
		bala.set("direccion", Vector2.RIGHT.rotated(rotation + dispersio_ang))
		bala.set("velocidad", velocidad_bala)
		bala.set("alcance_maximo", alcance)
		bala.set("penetracion_restante", penetracion)
		
		var es_crit: bool = randf() < prob_crit
		var danio_final: float = danio_base * mult_danio
		if es_crit:
			danio_final *= mult_critico
		bala.set("danio", danio_final)
		bala.set("es_critico", es_crit)
		
		get_tree().current_scene.add_child(bala)

func _draw() -> void:
	var color_metal := Color(0.3, 0.3, 0.35)
	if tier == 2: color_metal = Color(0.2, 0.5, 0.8)
	elif tier == 3: color_metal = Color(0.6, 0.2, 0.8)
	elif tier == 4: color_metal = Color(0.9, 0.3, 0.1)
	elif tier >= 5: color_metal = Color(0.95, 0.1, 0.1)
	
	# Representación del arma montada en el cuerpo del tomate
	draw_rect(Rect2(0, -3, 16, 6), color_metal)
	draw_rect(Rect2(2, 3, 4, 6), Color(0.35, 0.2, 0.1))
