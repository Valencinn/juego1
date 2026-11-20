extends Node3D

## Hitscan semiautomatico: cada pulsacion produce como maximo un disparo.
signal shot_fired(hit: Dictionary)

@export_range(1.0, 200.0) var damage: float = 25.0
@export_range(1.0, 500.0) var shot_range: float = 100.0
@export_range(0.05, 1.0) var fire_interval: float = 0.18
@export_flags_3d_physics var hit_mask: int = 1

@onready var camera: Camera3D = get_parent() as Camera3D
@onready var player: CharacterBody3D = get_parent().get_parent().get_parent() as CharacterBody3D
@onready var model: Node3D = $Model
@onready var muzzle: Marker3D = $Model/Muzzle
@onready var flash: MeshInstance3D = $Model/Muzzle/Flash
@onready var flash_light: OmniLight3D = $Model/Muzzle/Light
@onready var sound: AudioStreamPlayer = $ShotSound
@onready var hud: Control = $HUD/Reticle

var cooldown: float = 0.0
var pending_shot: bool = false
var flash_time: float = 0.0
var recoil: float = 0.0
var impacts: Array[MeshInstance3D] = []


func _ready() -> void:
	sound.stream = _make_shot_sound()
	flash.visible = false
	flash_light.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pending_shot = true
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if pending_shot:
		pending_shot = false
		fire()


func _process(delta: float) -> void:
	flash_time = maxf(0.0, flash_time - delta)
	flash.visible = flash_time > 0.0
	flash_light.visible = flash.visible
	recoil = move_toward(recoil, 0.0, delta * 7.0)
	model.position = Vector3(0.0, recoil * 0.025, recoil * 0.09)
	model.rotation.x = recoil * 0.10
	hud.visible = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


## Se ejecuta en el paso de fisica para consultar colisiones de forma segura.
func fire() -> bool:
	if cooldown > 0.0 or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return false
	cooldown = fire_interval
	var origin := camera.global_position
	var direction := -camera.global_basis.z.normalized()
	var hit := _ray(origin, origin + direction * shot_range)
	var aim_point: Vector3 = hit.get("position", origin + direction * shot_range)
	var barrel := muzzle.global_position
	# Evita disparar a traves de una pared aunque el modelo del arma la atraviese.
	var obstruction := _ray(origin, barrel)
	if not obstruction.is_empty():
		hit = obstruction
	else:
		var barrel_hit := _ray(barrel, aim_point + direction * 0.01)
		if not barrel_hit.is_empty():
			hit = barrel_hit
	var end: Vector3 = hit.get("position", aim_point)
	var damaged := false
	if not hit.is_empty():
		var receiver := hit["collider"] as Node
		while receiver != null:
			if receiver.has_method("take_damage"):
				receiver.call("take_damage", damage)
				damaged = true
				break
			receiver = receiver.get_parent()
		_add_impact(end, hit["normal"])
	_add_tracer(barrel if obstruction.is_empty() else origin, end)
	recoil = 1.0
	flash_time = 0.045
	flash.visible = true
	flash_light.visible = true
	sound.pitch_scale = randf_range(0.96, 1.04)
	sound.play()
	hud.call("show_shot", damaged)
	shot_fired.emit(hit)
	return true


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, hit_mask, [player.get_rid()])
	query.collide_with_areas = true
	query.hit_from_inside = true
	return get_world_3d().direct_space_state.intersect_ray(query)


func _effect_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material


func _add_tracer(from: Vector3, to: Vector3) -> void:
	var distance := from.distance_to(to)
	if distance < 0.01:
		return
	var tracer := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.006
	mesh.bottom_radius = 0.006
	mesh.height = distance
	mesh.radial_segments = 6
	tracer.mesh = mesh
	tracer.material_override = _effect_material(Color(1.0, 0.77, 0.3))
	tracer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(tracer)
	tracer.top_level = true
	tracer.global_position = (from + to) * 0.5
	var axis := (to - from).normalized()
	var side := axis.cross(Vector3.RIGHT if absf(axis.dot(Vector3.UP)) > 0.99 else Vector3.UP).normalized()
	tracer.global_basis = Basis(side, axis, side.cross(axis)).orthonormalized()
	get_tree().create_timer(0.045).timeout.connect(tracer.queue_free)


func _add_impact(at: Vector3, normal: Vector3) -> void:
	var impact := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.025
	mesh.height = 0.05
	impact.mesh = mesh
	impact.material_override = _effect_material(Color(0.16, 0.12, 0.08))
	add_child(impact)
	impact.top_level = true
	impact.global_position = at + normal * 0.008
	impacts.append(impact)
	while impacts.size() > 32:
		var oldest := impacts.pop_front() as MeshInstance3D
		if is_instance_valid(oldest):
			oldest.queue_free()
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		impacts.erase(impact)
		if is_instance_valid(impact):
			impact.queue_free()
	)


func _make_shot_sound() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var data := PackedByteArray()
	var samples := int(22050 * 0.16)
	data.resize(samples * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 42
	for i in range(samples):
		var t := float(i) / 22050.0
		var envelope := exp(-t * 42.0)
		var sample := (random.randf_range(-1.0, 1.0) * 0.65 + sin(TAU * 95.0 * t) * 0.35) * envelope
		data.encode_s16(i * 2, int(sample * 24000.0))
	stream.data = data
	return stream
