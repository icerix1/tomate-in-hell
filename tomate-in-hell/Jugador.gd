extends CharacterBody2D

const SCRIPT_ARMA = preload("res://Arma.gd")

var vida_maxima: float = 100.0
var vida_actual: float = 100.0
var velocidad_base: float = 300.0
var armadura: float = 0.0

var danio_mult: float = 1.0
var cadencia_mult: float = 1.0
var velocidad_mult: float = 1.0
var critico_extra: float = 0.0
var robo_vida: float = 0.0
var esquiva: float = 0.0
var recogida_mult: float = 1.0

var duracion_dash: float = 0.20
var timer_dash: float = 0.0
var cooldown_dash: float = 3.5
var timer_cooldown_dash: float = 0.0
var en_dash: bool = false
var es_invulnerable: bool = false
var dir_dash: Vector2 = Vector2.RIGHT

var timer_inmunidad: float = 0.0
var parpadeo_vis: bool = false

var ranuras_armas: Array[Node2D] = []
var max_armas: int = 6
var radio_recogida_base: float = 120.0

# Disparo secuencial (una por una)
var cooldown_entre_armas: float = 0.12
var timer_entre_armas: float = 0.0
var indice_arma_actual: int = 0

func _ready() -> void:
	add_to_group("jugador")
	collision_layer = 2
	collision_mask = 1
	
	var col := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 18.0
	col.shape = forma
	add_child(col)
	
	var area_iman := Area2D.new()
	area_iman.name = "AreaRecogida"
	area_iman.collision_layer = 0
	area_iman.collision_mask = 32
	var col_iman := CollisionShape2D.new()
	var circ_iman := CircleShape2D.new()
	circ_iman.radius = radio_recogida_base
	col_iman.shape = circ_iman
	area_iman.add_child(col_iman)
	add_child(area_iman)
	
	equipar_arma_inicial("pistola")

func equipar_arma_inicial(clave: String) -> void:
	if ranuras_armas.size() < max_armas:
		var datos: Dictionary = DatosJuego.CATALOGO_ARMAS.get(clave, DatosJuego.CATALOGO_ARMAS["pistola"])
		var arma := Node2D.new()
		arma.set_script(SCRIPT_ARMA)
		add_child(arma)
		arma.configurar(datos, 1)
		ranuras_armas.append(arma)
		reorganizar_armas()

func anadir_o_mejorar_arma(clave: String) -> bool:
	for arma in ranuras_armas:
		if arma.get("clave_arma") == clave and arma.get("tier") < 4:
			arma.configurar(DatosJuego.CATALOGO_ARMAS[clave], arma.get("tier") + 1)
			return true
			
	if ranuras_armas.size() < max_armas:
		var arma := Node2D.new()
		arma.set_script(SCRIPT_ARMA)
		add_child(arma)
		arma.configurar(DatosJuego.CATALOGO_ARMAS[clave], 1)
		ranuras_armas.append(arma)
		reorganizar_armas()
		return true
		
	return false

func reorganizar_armas() -> void:
	var total: int = ranuras_armas.size()
	for i in range(total):
		var angulo: float = (TAU / total) * i
		ranuras_armas[i].position = Vector2.RIGHT.rotated(angulo) * 22.0

func _physics_process(delta: float) -> void:
	if timer_cooldown_dash > 0.0:
		timer_cooldown_dash -= delta
		
	if timer_entre_armas > 0.0:
		timer_entre_armas -= delta
		
	if timer_inmunidad > 0.0:
		timer_inmunidad -= delta
		parpadeo_vis = int(timer_inmunidad * 16.0) % 2 == 0
		queue_redraw()
		if timer_inmunidad <= 0.0:
			es_invulnerable = false
			parpadeo_vis = false
			queue_redraw()
			
	if en_dash:
		timer_dash -= delta
		velocity = dir_dash * (velocidad_base * velocidad_mult * 2.8)
		move_and_slide()
		if timer_dash <= 0.0:
			en_dash = false
			es_invulnerable = false
		return
		
	var entrada := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		entrada.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		entrada.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		entrada.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		entrada.x += 1.0
		
	entrada = entrada.normalized()
	velocity = entrada * (velocidad_base * velocidad_mult)
	move_and_slide()
	
	if Input.is_key_pressed(KEY_SPACE) and timer_cooldown_dash <= 0.0:
		iniciar_dash(entrada)
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and timer_entre_armas <= 0.0:
		disparar_armas_secuencial()

func disparar_armas_secuencial() -> void:
	if ranuras_armas.is_empty(): return
	
	var total: int = ranuras_armas.size()
	for i in range(total):
		var indice: int = (indice_arma_actual + i) % total
		var arma = ranuras_armas[indice]
		if is_instance_valid(arma) and arma.has_method("puede_disparar") and arma.puede_disparar():
			arma.ejecutar_disparo()
			indice_arma_actual = (indice + 1) % total
			timer_entre_armas = cooldown_entre_armas
			break

func iniciar_dash(dir: Vector2) -> void:
	en_dash = true
	es_invulnerable = true
	timer_dash = duracion_dash
	timer_cooldown_dash = cooldown_dash
	dir_dash = dir if dir != Vector2.ZERO else Vector2.RIGHT

func recibir_danio(cantidad: float) -> void:
	if es_invulnerable: return
	if randf() < min(esquiva, 0.60): return
	
	var reduccion: float = armadura / (armadura + 50.0)
	var danio_final: float = max(cantidad * (1.0 - reduccion), 1.0)
	
	vida_actual -= danio_final
	es_invulnerable = true
	timer_inmunidad = 0.5
	Eventos.jugador_daniado.emit(vida_actual, vida_maxima)
	
	if vida_actual <= 0.0:
		Eventos.jugador_murio.emit()

func curar(cantidad: float) -> void:
	vida_actual = min(vida_actual + cantidad, vida_maxima)
	Eventos.jugador_curado.emit(vida_actual, vida_maxima)

func aplicar_mejora(mejora: Dictionary) -> void:
	var stat: String = mejora.get("stat", "")
	var val: float = mejora.get("valor", 0.0)
	match stat:
		"danio_mult": danio_mult += val
		"cadencia_mult": cadencia_mult += val
		"critico": critico_extra += val
		"vida_max":
			vida_maxima += val
			vida_actual += val
			Eventos.jugador_curado.emit(vida_actual, vida_maxima)
		"velocidad_mult": velocidad_mult += val
		"armadura": armadura += val
		"robo_vida": robo_vida = min(robo_vida + val, 0.15)
		"recogida_mult":
			recogida_mult += val
			var area = get_node_or_null("AreaRecogida")
			if area:
				var col = area.get_child(0) as CollisionShape2D
				if col and col.shape is CircleShape2D:
					col.shape.radius = radio_recogida_base * recogida_mult

func _draw() -> void:
	var a: float = 0.4 if parpadeo_vis else 1.0
	draw_circle(Vector2.ZERO, 18.0, Color(0.92, 0.2, 0.15, a))
	draw_circle(Vector2(-3, -3), 13.0, Color(1.0, 0.35, 0.25, a))
	var hojas := PackedVector2Array([Vector2(0, -18), Vector2(-7, -26), Vector2(0, -22), Vector2(7, -26)])
	draw_colored_polygon(hojas, Color(0.2, 0.8, 0.25, a))
	draw_circle(Vector2(-5, -2), 4.0, Color(1, 1, 1, a))
	draw_circle(Vector2(5, -2), 4.0, Color(1, 1, 1, a))
	draw_circle(Vector2(-4, -2), 2.0, Color(0, 0, 0, a))
	draw_circle(Vector2(6, -2), 2.0, Color(0, 0, 0, a))
