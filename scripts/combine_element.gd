extends Control
## Combine Element UI — player picks two elements to forge a weapon, then enters arena.

const ARENA_SCENE := "res://scenes/main.tscn"

const SFX_HOVER := preload("res://assets/audio/ui/hover-button.mp3")
const SFX_CLICK := preload("res://assets/audio/ui/select-button2.mp3")

@onready var bg: TextureRect = %Background
@onready var element_grid: GridContainer = %ElementGrid
@onready var slot_a_label: Label = %SlotALabel
@onready var slot_b_label: Label = %SlotBLabel
@onready var result_label: Label = %ResultLabel
@onready var result_desc: Label = %ResultDesc
@onready var combine_button: Button = %CombineButton
@onready var back_button: Button = %BackButton
@onready var slot_a_panel: PanelContainer = %SlotAPanel
@onready var slot_b_panel: PanelContainer = %SlotBPanel
@onready var result_panel: PanelContainer = %ResultPanel

var _sfx_hover: AudioStreamPlayer
var _sfx_click: AudioStreamPlayer

# Current combine state
var slot_a: String = ""
var slot_b: String = ""
var matched_weapon: Dictionary = {}

# All unique elements extracted from weapon recipes
var all_elements: Array[String] = []

func _ready() -> void:
	_init_sfx()
	_gather_elements()
	_build_element_buttons()
	_update_display()

	# Fade in
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)

func _init_sfx() -> void:
	_sfx_hover = AudioStreamPlayer.new()
	_sfx_hover.stream = SFX_HOVER
	add_child(_sfx_hover)
	_sfx_click = AudioStreamPlayer.new()
	_sfx_click.stream = SFX_CLICK
	add_child(_sfx_click)

func _gather_elements() -> void:
	var seen := {}
	for w in GameData.WEAPONS:
		for key in ["element_a", "element_b"]:
			var el: String = w[key]
			if not seen.has(el):
				seen[el] = true
				all_elements.append(el)

func _build_element_buttons() -> void:
	for el in all_elements:
		var btn := Button.new()
		btn.text = el
		btn.custom_minimum_size = Vector2(100, 60)
		btn.add_theme_font_size_override("font_size", 22)
		btn.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(0.4, 1.0, 0.8))

		# Style: semi-transparent dark box
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.1, 0.15, 0.85)
		style.border_color = Color(0.4, 0.55, 0.5, 0.7)
		style.set_border_width_all(2)
		style.set_corner_radius_all(6)
		style.set_content_margin_all(8)
		btn.add_theme_stylebox_override("normal", style)

		var hover_style := style.duplicate()
		hover_style.bg_color = Color(0.12, 0.2, 0.25, 0.95)
		hover_style.border_color = Color(0.4, 0.9, 0.7, 1.0)
		btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style := style.duplicate()
		pressed_style.bg_color = Color(0.05, 0.15, 0.2, 0.95)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		btn.pressed.connect(_on_element_pressed.bind(el))
		btn.mouse_entered.connect(func(): _sfx_hover.play())
		element_grid.add_child(btn)

func _on_element_pressed(el: String) -> void:
	_sfx_click.play()
	if slot_a.is_empty():
		slot_a = el
	elif slot_b.is_empty():
		slot_b = el
	else:
		# Reset and start over
		slot_a = el
		slot_b = ""
	_check_recipe()
	_update_display()

func _check_recipe() -> void:
	matched_weapon = {}
	if slot_a.is_empty() or slot_b.is_empty():
		return
	for w in GameData.WEAPONS:
		if (w["element_a"] == slot_a and w["element_b"] == slot_b) \
			or (w["element_a"] == slot_b and w["element_b"] == slot_a):
			matched_weapon = w
			return

func _update_display() -> void:
	slot_a_label.text = slot_a if not slot_a.is_empty() else "?"
	slot_b_label.text = slot_b if not slot_b.is_empty() else "?"

	if not matched_weapon.is_empty():
		result_label.text = "%s  (%s)" % [matched_weapon["name"], matched_weapon["formula"]]
		result_desc.text = matched_weapon["description"]
		result_label.add_theme_color_override("font_color", matched_weapon["color"])
		combine_button.disabled = false
		# Glow the result panel
		var panel_style := result_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if panel_style:
			panel_style.border_color = matched_weapon["color"]
	else:
		if slot_a.is_empty() and slot_b.is_empty():
			result_label.text = "Pilih 2 elemen untuk combine"
		elif not slot_b.is_empty():
			result_label.text = "Kombinasi tidak valid!"
		else:
			result_label.text = "Pilih elemen kedua..."
		result_desc.text = ""
		result_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		combine_button.disabled = true

func _on_combine_pressed() -> void:
	if matched_weapon.is_empty():
		return
	_sfx_click.play()
	GameData.selected_weapon_id = matched_weapon["id"]
	# Transition to arena
	set_process_input(false)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN)
	t.tween_callback(func(): get_tree().change_scene_to_file(ARENA_SCENE))

func _on_back_pressed() -> void:
	_sfx_click.play()
	set_process_input(false)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN)
	t.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

func _on_reset_pressed() -> void:
	_sfx_click.play()
	slot_a = ""
	slot_b = ""
	matched_weapon = {}
	_update_display()
