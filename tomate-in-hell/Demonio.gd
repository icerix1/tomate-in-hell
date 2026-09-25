extends CharacterBody2D

const SCRIPT_DROP = preload("res://Coleccionable.gd")

enum Categoria { DIABLILLO, CORREDOR, BRUTO, MINIBOSS, BOSS }

var categoria: Categoria = Categoria.DIABLILLO
var hp_maximo: float = 18.0
var hp_actual: float = 18.0
var velocidad_base: float = 140.0
var danio_contacto: float = 8.0
var valor_esencia: int = 1
var valor_monedas: int = 1

var flash_timer: float = 0.0
var es_elite: bool = false

var tiempo_telegrafo: float = 0.0
var atacando: bool = false
var dir_embestida: Vector2 = Vector2.ZERO

const LIMITE_MAPA_X: float = 930.0
const LIMITE_MAPA_Y: float = 500.0

func configurar(cat: Categoria, oleada: int, elite: bool = false) -> void:
	categoria = cat
	es_elite = elite
	
	match categoria:
		Categoria.DIABLILLO:
			hp_maximo = DatosJuego.calcular_vida_enemigo(18.0, oleada)
			velocidad_base = 140.0
			danio_contacto = DatosJuego.calcular_danio_enemigo(8.0, oleada)
			valor_esencia = 1
			valor_monedas = 1
		Categoria.CORREDOR:
			hp_maximo = DatosJuego.calcular_vida_enemigo(14.0, oleada)
			velocidad_base = 220.0
			danio_contacto = DatosJuego.calcular_danio_enemigo(7.0, oleada)
			valor_esencia = 1
			valor_monedas = 1
		Categoria.BRUTO:
			hp_maximo = DatosJuego.calcular_vida_enemigo(80.0, oleada)
			velocidad_base = 90.0
			danio_contacto = DatosJuego.calcular_danio_enemigo(18.0, oleada)
			valor_esencia = 3
			valor_monedas = 2
		Categoria.MINIBOSS:
			hp_maximo = DatosJuego.calcular_vida_boss(850.0, oleada)
			velocidad_base = 110.0
			danio_contacto = DatosJuego.calcular_danio_enemigo(25.0, oleada)
			valor_esencia = 25
			valor_monedas = 25
		Categoria.BOSS:
			hp_maximo = DatosJuego.calcular_vida_boss(3000.0, oleada)
			velocidad_base = 85.0
			danio_contacto = DatosJuego.calcular_danio_enemigo(35.0, oleada)
			valor_esencia = 60
			valor_monedas = 60
			
	if es_elite and categoria != Categoria.BOSS and categoria != Categoria.MINIBOSS:
		hp_maximo *= 2.5
		danio_contacto *= 1.3
		valor_esencia *= 4
		valor_monedas *= 4
		
	hp_actual = hp_maximo

func _ready() -> void:
	add_to_group("demonios")
	collision_layer = 4
	collision_mask = 3
	
	var col := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 28.0 if categoria == Categoria.BOSS else (20.0 if categoria == Categoria.MINIBOSS else 14.0)
	col.shape = forma
	add_child(col)

func _physics_process(delta: float) -> void:
	# Corrección de seguridad: si el demonio sobrepasa la pared, se reubica dentro
	global_position.x = clamp(global_position.x, -LIMITE_MAPA_X, LIMITE_MAPA_X)
	global_position.y = clamp(global_position.y, -LIMITE_MAPA_Y, LIMITE_MAPA_Y)
	
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0: queue_redraw()
		
	var jugador = get_tree().get_first_node_in_group("jugador")
	if not jugador or not is_instance_valid(jugador): return
	
	if categoria == Categoria.MINIBOSS or categoria == Categoria.BOSS:
		procesar_ia_boss(delta, jugador)
	else:
		var dir: Vector2 = (jugador.global_position - global_position).normalized()
		velocity = dir * velocidad_base
		move_and_slide()
		
	for i in range(get_slide_collision_count()):
		var col: KinematicCollision2D = get_slide_collision(i)
		var obj: Object = col.get_collider()
		if obj and (obj as Node).is_in_group("jugador") and obj.has_method("recibir_danio"):
			obj.recibir_danio(danio_contacto)

func procesar_ia_boss(delta: float, jugador: Node2D) -> void:
	if tiempo_telegrafo > 0.0:
		tiempo_telegrafo -= delta
		velocity = Vector2.ZERO
		queue_redraw()
		if tiempo_telegrafo <= 0.0:
			atacando = true
			dir_embestida = (jugador.global_position - global_position).normalized()
			get_tree().create_timer(0.6).timeout.connect(func(): atacando = false)
		return
		
	if atacando:
		velocity = dir_embestida * (velocidad_base * 3.5)
		move_and_slide()
	else:
		var dir: Vector2 = (jugador.global_position - global_position).normalized()
		velocity = dir * velocidad_base
		move_and_slide()
		if randf() < 0.005:
			tiempo_telegrafo = 1.0

func recibir_danio(cantidad: float, critico: bool = false) -> void:
	hp_actual -= cantidad
	flash_timer = 0.08
	queue_redraw()
	
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador and jugador.robo_vida > 0.0 and randf() < jugador.robo_vida:
		jugador.curar(1.0)
		
	if hp_actual <= 0.0:
		morir()

func morir() -> void:
	soltar_loot()
	queue_free()

func soltar_loot() -> void:
	var escena = get_tree().current_scene
	var e := Area2D.new()
	e.set_script(SCRIPT_DROP)
	e.global_position = global_position
	e.configurar(SCRIPT_DROP.Tipo.ESENCIA, valor_esencia)
	escena.add_child(e)
	
	if randf() <= 0.40 or categoria >= Categoria.MINIBOSS:
		var m := Area2D.new()
		m.set_script(SCRIPT_DROP)
		m.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		m.configurar(SCRIPT_DROP.Tipo.MONEDA, valor_monedas)
		escena.add_child(m)
		
	if randf() <= 0.02:
		var c := Area2D.new()
		c.set_script(SCRIPT_DROP)
		c.global_position = global_position + Vector2(12, 0)
		c.configurar(SCRIPT_DROP.Tipo.CORAZON, 1)
		escena.add_child(c)

func _draw() -> void:
	if tiempo_telegrafo > 0.0:
		draw_circle(Vector2.ZERO, 70.0, Color(1.0, 0.0, 0.0, 0.3))
		draw_circle(Vector2.ZERO, 70.0 * (1.0 - tiempo_telegrafo), Color(1.0, 0.0, 0.0, 0.4))
		
	var col_cuerpo: Color = Color.WHITE if flash_timer > 0.0 else Color(0.65, 0.12, 0.2)
	if categoria == Categoria.CORREDOR: col_cuerpo = Color(0.85, 0.4, 0.1)
	elif categoria == Categoria.BRUTO: col_cuerpo = Color(0.4, 0.05, 0.1)
	elif categoria == Categoria.MINIBOSS: col_cuerpo = Color(0.5, 0.1, 0.7)
	elif categoria == Categoria.BOSS: col_cuerpo = Color(0.2, 0.0, 0.05)
	
	var r: float = 24.0 if categoria == Categoria.BOSS else (18.0 if categoria == Categoria.MINIBOSS else 12.0)
	draw_circle(Vector2.ZERO, r, col_cuerpo)
	draw_circle(Vector2(-r * 0.4, -r * 0.2), 2.5, Color.YELLOW)
	draw_circle(Vector2(r * 0.4, -r * 0.2), 2.5, Color.YELLOW)
	
	if categoria >= Categoria.MINIBOSS or es_elite:
		var pct: float = clamp(hp_actual / hp_maximo, 0.0, 1.0)
		draw_rect(Rect2(-24, -r - 12, 48, 5), Color(0.2, 0.2, 0.2))
		draw_rect(Rect2(-24, -r - 12, 48 * pct, 5), Color.RED)
