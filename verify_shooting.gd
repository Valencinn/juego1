extends SceneTree

var shot_count: int = 0
var last_hit: Dictionary = {}


func _initialize() -> void:
	call_deferred("verify")


func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
		assert(condition, message)


func click() -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	Input.parse_input_event(press)


func release_click() -> void:
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(release)


func wait_cooldown(weapon: Node) -> void:
	while weapon.cooldown > 0.0:
		await physics_frame


func blocker(at: Vector3, dimensions: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	root.add_child(body)
	body.global_position = at
	return body


func verify() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Esta prueba requiere ventana para verificar la captura del mouse. Ejecutar sin --headless.")
		quit(1)
		return
	var scene := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in range(120):
		await physics_frame
	var player := scene.get_node("Player")
	var camera := player.get_node("Head/Camera3D") as Camera3D
	var weapon := camera.get_node("Weapon")
	var target := scene.get_node("PracticeCenter")
	if OS.get_cmdline_user_args().has("--capture"):
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/shooting_preview.png")
	weapon.shot_fired.connect(func(hit: Dictionary) -> void:
		shot_count += 1
		last_hit = hit
	)
	for target_name in ["PracticeLeft", "PracticeCenter", "PracticeRight"]:
		var practice := scene.get_node(target_name)
		var sightline: Dictionary = weapon._ray(camera.global_position, practice.global_position)
		check(sightline.get("collider") == practice, "El blanco %s esta tapado desde el inicio" % target_name)
	camera.look_at(target.global_position, Vector3.UP)
	check(InputMap.has_action("shoot"), "Falta la accion shoot")
	check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "No captura el mouse al iniciar")
	click()
	await physics_frame
	await physics_frame
	check(shot_count == 1, "El clic no dispara exactamente una vez")
	check(last_hit.get("collider") == target, "El disparo no coincide con el centro de la camara")
	check(target.health == 75.0, "El impacto no aplica 25 de dano")
	check(not weapon.fire(), "Ignora el intervalo entre disparos")
	for i in range(30):
		await physics_frame
	check(shot_count == 1, "Mantener clic dispara automaticamente")
	release_click()
	for i in range(3):
		await wait_cooldown(weapon)
		click()
		await physics_frame
		await physics_frame
		release_click()
	check(target.health == 0.0 and target.resetting, "El blanco no se destruye con cuatro impactos")
	for i in range(105):
		await physics_frame
	check(target.health == 100.0 and not target.resetting, "El blanco no reaparece")
	# Una pared delante del blanco debe absorber el disparo.
	var direction := -camera.global_basis.z
	var wall := blocker(camera.global_position + direction * 2.0, Vector3(2, 2, 0.2))
	await physics_frame
	await physics_frame
	click()
	await physics_frame
	await physics_frame
	release_click()
	check(last_hit.get("collider") == wall and target.health == 100.0, "Dispara a traves de paredes")
	wall.queue_free()
	await physics_frame
	await wait_cooldown(weapon)
	# Cobertura que tapa el canon pero deja libre la mira tambien bloquea.
	var muzzle: Vector3 = weapon.get_node("Model/Muzzle").global_position
	var cover := blocker(camera.global_position.lerp(muzzle, 0.7), Vector3(0.13, 0.13, 0.13))
	await physics_frame
	await physics_frame
	click()
	await physics_frame
	await physics_frame
	release_click()
	check(last_hit.get("collider") == cover and target.health == 100.0, "El canon atraviesa cobertura cercana")
	cover.queue_free()
	await physics_frame
	await wait_cooldown(weapon)
	# Escape pausa el disparo; el primer clic posterior solo captura el mouse.
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await physics_frame
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Escape no libera el mouse")
	check(not weapon.fire(), "Dispara con el mouse liberado")
	var before := shot_count
	click()
	await physics_frame
	await physics_frame
	release_click()
	check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and shot_count == before, "Recapturar dispara accidentalmente")
	click()
	await physics_frame
	await physics_frame
	release_click()
	check(shot_count == before + 1 and target.health == 75.0, "No vuelve a disparar despues de recapturar")
	await wait_cooldown(weapon)
	camera.look_at(camera.global_position + Vector3(0, 10, -1))
	click()
	await physics_frame
	await physics_frame
	release_click()
	check(last_hit.is_empty(), "Un disparo al cielo debe fallar sin errores")
	check(weapon.impacts.size() <= 32, "Los impactos no tienen limite")
	player._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Perder el foco no libera el mouse")
	print("VERIFICACION OK: clic, cadencia, mantener clic, punteria, dano, blancos, paredes, canon, Escape, recaptura y foco")
	scene.queue_free()
	await process_frame
	quit()
