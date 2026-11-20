extends StaticBody3D

@export var max_health: float = 100.0
var health: float = 100.0
var resetting: bool = false
var material: StandardMaterial3D


func _ready() -> void:
	health = max_health
	material = $Plate.material_override.duplicate() as StandardMaterial3D
	$Plate.material_override = material


func take_damage(amount: float) -> void:
	if resetting:
		return
	health = maxf(0.0, health - amount)
	$Health.text = "%d / %d" % [int(health), int(max_health)]
	material.albedo_color = Color(1.0, 0.35, 0.12)
	if health <= 0.0:
		resetting = true
		$Health.text = "ACIERTO"
		$CollisionShape3D.set_deferred("disabled", true)
		$Plate.visible = false
		get_tree().create_timer(1.5).timeout.connect(_reset)
	else:
		get_tree().create_timer(0.12).timeout.connect(func() -> void:
			material.albedo_color = Color(0.15, 0.55, 0.7)
		)


func _reset() -> void:
	health = max_health
	resetting = false
	$Health.text = "%d / %d" % [int(health), int(max_health)]
	$Plate.visible = true
	material.albedo_color = Color(0.15, 0.55, 0.7)
	$CollisionShape3D.set_deferred("disabled", false)
