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

var cooldown_entre_armas: float = 0.12
var timer_entre_armas: float = 0.0
var indice_arma_actual: int = 0

var Animatedsprite := AnimatedSprite2D.new()
var particles := GPUParticles3D.new()
var direction :=0;

func _ready() -> void:
	add_to_group("jugador")
	collision_layer = 2
	collision_mask = 1
	
	cargar_datos_personaje()
	
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
	circ_iman.radius = radio_recogida_base * recogida_mult
	col_iman.shape = circ_iman
	area_iman.add_child(col_iman)
	add_child(area_iman)

	Animatedsprite.name = "PlayerSprite"
	Animatedsprite.sprite_frames = load("res://Animations/BasicTomatto.tres")
	Animatedsprite.scale = Vector2(0.05, 0.05)
	add_child(Animatedsprite)
	Animatedsprite.play("IdleRight")

	# particles.name = "Particles"
	# # Basic particle settings
	# particles.amount = 100
	# particles.lifetime = 1.0
	# particles.emitting = true

    # # Create the particle behavior/material
	# var particle_material := ParticleProcessMaterial.new()

	# particle_material.direction = Vector3(0, 1, 0)
	# particle_material.spread = 30.0
	# particle_material.initial_velocity_min = 2.0
	# particle_material.initial_velocity_max = 4.0
	# particle_material.gravity = Vector3(0, -1, 0)

	# particles.process_material = particle_material

    # # Create the mesh that each particle displays
	# var particle_mesh := QuadMesh.new()
	# particle_mesh.size = Vector2(0.1, 0.1)

	# particles.draw_pass_1 = particle_mesh

    # # Add GPUParticles3D to this node
	# add_child(particles)

func cargar_datos_personaje() -> void:
	var datos: Dictionary = DatosJuego.personaje_actual
	if datos.is_empty():
		datos = DatosJuego.CATALOGO_PERSONAJES["clasico"]
		
	vida_maxima = datos.get("hp", 100.0)
	vida_actual = vida_maxima
	danio_mult = datos.get("danio_mult", 1.0)
	velocidad_mult = datos.get("velocidad_mult", 1.0)
	cadencia_mult = datos.get("cadencia_mult", 1.0)
	armadura = datos.get("armadura", 0.0)
	critico_extra = datos.get("critico_extra", 0.0)
	robo_vida = datos.get("robo_vida", 0.0)
	esquiva = datos.get("esquiva", 0.0)
	
	var arma_inicial: String = datos.get("arma", "pistola")
	equipar_arma_inicial(arma_inicial)

func equipar_arma_inicial(clave: String) -> void:
	if ranuras_armas.size() < max_armas:
		var datos_arma: Dictionary = DatosJuego.CATALOGO_ARMAS.get(clave, DatosJuego.CATALOGO_ARMAS["pistola"])
		var arma := Node2D.new()
		arma.set_script(SCRIPT_ARMA)
		add_child(arma)
		arma.configurar(datos_arma, 1)
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
		direction =1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		entrada.y += 1.0
		direction =2
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		entrada.x -= 1.0
		direction =3
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		entrada.x += 1.0
		direction =4

	if entrada.x > 0:
		Animatedsprite.play("WalkingRight")
	elif entrada.x < 0:
		Animatedsprite.play("WalkingLeft")
	elif entrada.y < 0:
		pass
	elif entrada.y > 0:
		pass

	if abs(entrada.x)<=0 and abs(entrada.y)<=0:
		match direction:
			1:pass
			2:pass
			3:Animatedsprite.play("IdleLeft")
			4:Animatedsprite.play("IdleRight")
		
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
