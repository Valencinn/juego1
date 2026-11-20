extends Control

var shot_time: float = 0.0
var hit_time: float = 0.0


func show_shot(hit_target: bool) -> void:
	shot_time = 0.10
	if hit_target:
		hit_time = 0.18
	queue_redraw()


func _process(delta: float) -> void:
	if shot_time > 0.0 or hit_time > 0.0:
		shot_time = maxf(0.0, shot_time - delta)
		hit_time = maxf(0.0, hit_time - delta)
		queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var gap := 5.0 + shot_time * 35.0
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var start: Vector2 = center + direction * gap
		var end: Vector2 = center + direction * (gap + 6.0)
		draw_line(start, end, Color(0.0, 0.0, 0.0, 0.75), 4.0)
		draw_line(start, end, Color.WHITE, 2.0)
	draw_circle(center, 1.5, Color.WHITE)
	if hit_time > 0.0:
		for direction in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			draw_line(center + direction * 9.0, center + direction * 15.0, Color(1.0, 0.4, 0.15), 2.0)
