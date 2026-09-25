extends Area2D

var direccion: Vector2 = Vector2.RIGHT
var velocidad: float = 1200.0
var danio: float = 22.0
var alcance_maximo: float = 700.0
var distancia_recorrida: float = 0.0
var es_critico: bool = false
var penetracion_restante: int = 0

func _ready() -> void:
	collision_layer = 8
	collision_mask = 4
	body_entered.connect(_al_colisionar)
	
	var col := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 5.0
	col.shape = forma
	add_child(col)

func _physics_process(delta: float) -> void:
	var paso: Vector2 = direccion * velocidad * delta
	global_position += paso
	distancia_recorrida += paso.length()
	if distancia_recorrida >= alcance_maximo:
		queue_free()

func _draw() -> void:
	var col_nucleo: Color = Color.WHITE if es_critico else Color(1.0, 0.95, 0.3)
	var col_borde: Color = Color(1.0, 0.25, 0.1) if es_critico else Color(1.0, 0.5, 0.1)
	
	var ang: float = direccion.angle()
	var punta: Vector2 = Vector2.RIGHT.rotated(ang) * 6.0
	var cola: Vector2 = Vector2.LEFT.rotated(ang) * 6.0
	
	# Proyectil alargado tipo bala incandescente con núcleo brillante
	draw_line(cola, punta, col_borde, 6.0)
	draw_line(cola * 0.7, punta * 0.7, col_nucleo, 3.0)

func _al_colisionar(cuerpo: Node2D) -> void:
	if cuerpo.has_method("recibir_danio"):
		cuerpo.recibir_danio(danio, es_critico)
		if penetracion_restante > 0:
			penetracion_restante -= 1
		else:
			queue_free()
