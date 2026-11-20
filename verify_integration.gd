extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var player = scene.get_node("Player")
	for i in range(120):
		await physics_frame
	assert(player.is_on_floor(), "El jugador no aterriza en el suelo")
	assert(player.global_basis.is_equal_approx(Basis.IDENTITY), "El jugador hereda la rotacion o escala del mapa")
	assert(player.get_node("Head/Camera3D").current)
	var start = player.global_position
	Input.action_press("move_forward")
	for i in range(30):
		await physics_frame
	Input.action_release("move_forward")
	assert(player.global_position.z < start.z - 1.0, "No avanza")
	Input.action_press("jump")
	for i in range(6):
		await physics_frame
	Input.action_release("jump")
	assert(player.global_position.y > start.y + 0.1, "No salta")
	print("VERIFICACION OK: escena, camara, orientacion, suelo, movimiento y salto")
	quit()
