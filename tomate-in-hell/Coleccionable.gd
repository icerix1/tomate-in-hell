extends Area2D

enum Tipo { ESENCIA, MONEDA, CORAZON, BOMBA }

var tipo_item: Tipo = Tipo.ESENCIA
var valor: int = 1
var objetivo_jugador: Node2D = null
var velocidad_iman: float = 0.0

func configurar(tipo: Tipo, cantidad: int = 1) -> void:
	tipo_item = tipo
	valor = cantidad
	queue_redraw()

func _ready() -> void:
	collision_layer = 32
	collision_mask = 2
	area_entered.connect(_al_entrar_rango_iman)
	body_entered.connect(_al_tocar_jugador)
	
	var col := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 12.0
	col.shape = forma
	add_child(col)

func _physics_process(delta: float) -> void:
	if objetivo_jugador and is_instance_valid(objetivo_jugador):
		velocidad_iman += 1400.0 * delta
		global_position = global_position.move_toward(objetivo_jugador.global_position, velocidad_iman * delta)

func _al_entrar_rango_iman(area: Area2D) -> void:
	if area.name == "AreaRecogida":
		objetivo_jugador = area.get_parent()

func _al_tocar_jugador(cuerpo: Node2D) -> void:
	if cuerpo.is_in_group("jugador"):
		match tipo_item:
			Tipo.ESENCIA:
				Eventos.enemigo_muerto.emit(global_position, valor, 0, false)
			Tipo.MONEDA:
				Eventos.enemigo_muerto.emit(global_position, 0, valor, false)
			Tipo.CORAZON:
				if cuerpo.has_method("curar"):
					cuerpo.curar(cuerpo.vida_maxima * 0.10)
			Tipo.BOMBA:
				detonar_bomba()
		queue_free()

func detonar_bomba() -> void:
	var demonios = get_tree().get_nodes_in_group("demonios")
	for d in demonios:
		if is_instance_valid(d) and d.has_method("recibir_danio"):
			d.recibir_danio(80.0, true)

func _draw() -> void:
	match tipo_item:
		Tipo.ESENCIA:
			var rombo := PackedVector2Array([Vector2(0, -8), Vector2(6, 0), Vector2(0, 8), Vector2(-6, 0)])
			draw_colored_polygon(rombo, Color(0.0, 0.85, 1.0, 0.9))
			draw_circle(Vector2.ZERO, 2.0, Color.WHITE)
		Tipo.MONEDA:
			draw_circle(Vector2.ZERO, 7.0, Color(0.9, 0.75, 0.1))
			draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.9, 0.3))
		Tipo.CORAZON:
			draw_circle(Vector2(-3, -2), 4.0, Color.RED)
			draw_circle(Vector2(3, -2), 4.0, Color.RED)
			var tri := PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(0, 7)])
			draw_colored_polygon(tri, Color.RED)
		Tipo.BOMBA:
			draw_circle(Vector2.ZERO, 6.0, Color(0.15, 0.15, 0.15))
			draw_circle(Vector2(2, -3), 2.0, Color.ORANGE)
