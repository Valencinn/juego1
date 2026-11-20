extends "res://addons/proto_controller/proto_controller.gd"


func _ready() -> void:
	super._ready()
	capture_mouse()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		release_mouse()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			capture_mouse()
			get_viewport().set_input_as_handled()
		return
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		release_mouse()
