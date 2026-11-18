extends Control
class_name CrosshairUI

@export var dot_radius: float = 2.0
@export var line_length: float = 8.0
@export var line_gap: float = 6.0
@export var line_thickness: float = 2.0
@export var default_color: Color = Color(1.0, 1.0, 1.0, 0.9)
@export var target_color: Color = Color(1.0, 0.25, 0.25, 1.0)
@export var outline_color: Color = Color(0.0, 0.0, 0.0, 0.6)

var is_targeting_enemy: bool = false:
	set(val):
		if is_targeting_enemy != val:
			is_targeting_enemy = val
			queue_redraw()

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_CENTER)

func _draw() -> void:
	var c := Vector2.ZERO
	var active_color := target_color if is_targeting_enemy else default_color

	# Garis tepi hitam untuk kontras tinggi di semua latar
	_draw_reticle(c, line_thickness + 2.0, outline_color, dot_radius + 1.0)
	# Garis bidik utama
	_draw_reticle(c, line_thickness, active_color, dot_radius)

func _draw_reticle(c: Vector2, thick: float, col: Color, dot_r: float) -> void:
	draw_circle(c, dot_r, col)
	draw_line(c + Vector2(-line_gap - line_length, 0), c + Vector2(-line_gap, 0), col, thick)
	draw_line(c + Vector2(line_gap, 0), c + Vector2(line_gap + line_length, 0), col, thick)
	draw_line(c + Vector2(0, -line_gap - line_length), c + Vector2(0, -line_gap), col, thick)
	draw_line(c + Vector2(0, line_gap), c + Vector2(0, line_gap + line_length), col, thick)

