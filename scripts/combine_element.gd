extends Control
## Combine Element UI — Pemain meracik unsur di atas meja alchemy untuk menempa senjata.

const ARENA_SCENE := "res://scenes/main.tscn"

const SFX_HOVER := preload("res://assets/audio/ui/hover-button.mp3")
const SFX_CLICK := preload("res://assets/audio/ui/select-button2.mp3")

@onready var bg: TextureRect = %Background
@onready var back_button: Button = %BackButton
@onready var element_grid: GridContainer = %ElementGrid

# Tengah - Meja Racik
@onready var slots_row: HBoxContainer = %SlotsRow
@onready var combine_button: Button = %CombineButton
@onready var reset_button: Button = %ResetButton

# Kanan - Hasil Gabungan
@onready var result_panel: PanelContainer = %ResultPanel
@onready var rune_circle_bg: TextureRect = %RuneCircleBg
@onready var result_icon: TextureRect = %ResultIcon
@onready var result_question: Label = %ResultQuestion
@onready var result_name: Label = %ResultName
@onready var result_formula: Label = %ResultFormula
@onready var candidate_row: HBoxContainer = %CandidateRow
@onready var result_desc: Label = %ResultDesc

var _sfx_hover: AudioStreamPlayer
var _sfx_click: AudioStreamPlayer

# State racik
var selected_elements: Array[String] = []
var matched_weapons: Array[Dictionary] = []
var selected_match_index: int = 0
var matched_weapon: Dictionary = {}

var all_elements: Array[String] = []
var _element_buttons: Dictionary = {}

func _ready() -> void:
	_init_sfx()
	_gather_elements()
	_build_element_buttons()
	_update_display()

	# Fade in
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)

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
		for el: String in w.get("elements", []):
			if not seen.has(el):
				seen[el] = true
				all_elements.append(el)

func _get_element_info(el: String) -> Dictionary:
	return ElementData.get_info(el)

func _build_element_buttons() -> void:
	for child in element_grid.get_children():
		child.queue_free()
	_element_buttons.clear()

	for el in all_elements:
		var info: Dictionary = _get_element_info(el)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(88, 88)
		btn.tooltip_text = info["name"]
		btn.focus_mode = Control.FOCUS_NONE

		var icon_rect := TextureRect.new()
		icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_rect.texture = load(info["icon"])
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon_rect)

		var empty_style := StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal", empty_style)
		btn.add_theme_stylebox_override("pressed", empty_style)
		btn.add_theme_stylebox_override("focus", empty_style)

		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0, 0, 0, 0)
		hover_style.border_color = Color(0.85, 0.9, 1.0, 0.6)
		hover_style.set_border_width_all(2)
		hover_style.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("hover", hover_style)

		btn.pressed.connect(_on_element_pressed.bind(el))
		btn.mouse_entered.connect(func(): _sfx_hover.play())

		element_grid.add_child(btn)
		_element_buttons[el] = btn

func _on_element_pressed(el: String) -> void:
	_sfx_click.play()
	if selected_elements.has(el):
		selected_elements.erase(el)
	else:
		selected_elements.append(el)
	_check_recipe()
	_update_display()

func _remove_element(el: String) -> void:
	_sfx_click.play()
	selected_elements.erase(el)
	_check_recipe()
	_update_display()

func _check_recipe() -> void:
	matched_weapons.clear()
	selected_match_index = 0
	matched_weapon = {}
	if selected_elements.is_empty():
		return
	for w in GameData.WEAPONS:
		var req: Array = w.get("elements", [])
		if _elements_match(req, selected_elements):
			matched_weapons.append(w)
	if not matched_weapons.is_empty():
		matched_weapon = matched_weapons[0]

func _elements_match(req: Array, selected: Array[String]) -> bool:
	if req.size() != selected.size():
		return false
	for el in req:
		if not selected.has(el):
			return false
	return true

func _select_candidate(idx: int) -> void:
	if idx >= 0 and idx < matched_weapons.size():
		_sfx_click.play()
		selected_match_index = idx
		matched_weapon = matched_weapons[idx]
		_update_display()

func _update_display() -> void:
	_render_slots()
	_update_element_button_highlights()

	# Bersihkan tombol kandidat lama
	for child in candidate_row.get_children():
		child.queue_free()

	if not matched_weapon.is_empty():
		result_question.visible = false
		result_icon.visible = true
		var elem_info: Dictionary = _get_element_info(selected_elements[0])
		result_icon.texture = load(elem_info["icon"])
		result_name.text = matched_weapon["name"]
		result_name.add_theme_color_override("font_color", matched_weapon["color"])
		result_formula.text = "(%s)" % matched_weapon["formula"]
		result_formula.visible = true
		result_formula.add_theme_color_override("font_color", matched_weapon["color"])
		result_desc.text = matched_weapon["description"]
		result_desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.88))
		rune_circle_bg.modulate = matched_weapon["color"]
		combine_button.disabled = false
		bg.texture = load("res://assets/ui/campaign/combine-element.jpeg")

		if matched_weapons.size() > 1:
			candidate_row.visible = true
			for i in matched_weapons.size():
				var cand: Dictionary = matched_weapons[i]
				var btn := Button.new()
				btn.text = cand["formula"]
				btn.tooltip_text = cand["name"]
				btn.focus_mode = Control.FOCUS_NONE
				btn.custom_minimum_size = Vector2(72, 32)
				var btn_style := StyleBoxFlat.new()
				btn_style.set_corner_radius_all(6)
				btn_style.set_content_margin_all(4)
				if i == selected_match_index:
					btn_style.bg_color = cand["color"] * Color(0.4, 0.4, 0.4, 0.8)
					btn_style.border_color = cand["color"]
					btn_style.set_border_width_all(2)
					btn.add_theme_color_override("font_color", Color.WHITE)
				else:
					btn_style.bg_color = Color(0.12, 0.12, 0.15, 0.8)
					btn_style.border_color = Color(0.3, 0.3, 0.35, 0.5)
					btn_style.set_border_width_all(1)
					btn.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
				btn.add_theme_stylebox_override("normal", btn_style)
				btn.add_theme_stylebox_override("hover", btn_style)
				btn.pressed.connect(_select_candidate.bind(i))
				candidate_row.add_child(btn)
		else:
			candidate_row.visible = false
	else:
		candidate_row.visible = false
		result_question.visible = true
		result_icon.visible = false
		result_formula.visible = false
		result_name.text = "???"
		result_name.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
		rune_circle_bg.modulate = Color(0.5, 0.55, 0.6, 0.45)
		combine_button.disabled = true

		if selected_elements.is_empty():
			result_desc.text = "Gabungkan beberapa unsur untuk menemukan senyawa baru!"
			bg.texture = load("res://assets/ui/campaign/combine-element-2.jpeg")
		else:
			result_desc.text = "Kombinasi tidak valid! Coba padukan unsur lain."
			bg.texture = load("res://assets/ui/campaign/combine-element-2.jpeg")
		result_desc.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))

func _render_slots() -> void:
	for child in slots_row.get_children():
		child.queue_free()

	if selected_elements.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Pilih unsur dari daftar di sebelah kiri..."
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, 0.8))
		empty_label.add_theme_font_size_override("font_size", 15)
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slots_row.add_child(empty_label)
		return

	for i in selected_elements.size():
		var el: String = selected_elements[i]
		var info: Dictionary = _get_element_info(el)

		if i > 0:
			var plus := Label.new()
			plus.text = "+"
			plus.custom_minimum_size = Vector2(30, 96)
			plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			plus.add_theme_font_size_override("font_size", 28)
			plus.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
			slots_row.add_child(plus)

		var slot_box := VBoxContainer.new()
		slot_box.alignment = BoxContainer.ALIGNMENT_CENTER

		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(72, 72)
		panel.mouse_filter = Control.MOUSE_FILTER_PASS
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.tooltip_text = "Klik untuk menghapus %s" % info["name"]

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.07, 0.1, 0.92)
		style.set_border_width_all(2)
		style.border_color = info["color"]
		style.set_corner_radius_all(10)
		panel.add_theme_stylebox_override("panel", style)

		var center := CenterContainer.new()
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon_rect := TextureRect.new()
		icon_rect.texture = load(info["icon"])
		icon_rect.custom_minimum_size = Vector2(48, 48)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(icon_rect)
		panel.add_child(center)

		# if i > 4:
		# 	var child_panel := HBoxContainer.new()
		# 	child_panel.add_child(panel)
		# 	slots_row.add_child(child_panel)
		# 	child_panel.move_child(panel, 1)
		# else:
		# 	slots_row.add_child(panel)

		var name_lbl := Label.new()
		name_lbl.text = el
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", info["color"])

		panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_remove_element(el)
		)

		slot_box.add_child(panel)
		slot_box.add_child(name_lbl)
		slots_row.add_child(slot_box)

func _update_element_button_highlights() -> void:
	for el: String in _element_buttons:
		var btn: Button = _element_buttons[el]
		var is_selected: bool = selected_elements.has(el)
		if is_selected:
			var info: Dictionary = _get_element_info(el)
			var sel_style := StyleBoxFlat.new()
			sel_style.bg_color = Color(0, 0, 0, 0)
			sel_style.border_color = info["color"]
			sel_style.set_border_width_all(3)
			sel_style.set_corner_radius_all(6)
			btn.add_theme_stylebox_override("normal", sel_style)
			btn.modulate = Color(1.2, 1.2, 1.2)
		else:
			btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
			btn.modulate = Color(0.9, 0.9, 0.9)

func _on_combine_pressed() -> void:
	if matched_weapon.is_empty():
		return
	_sfx_click.play()
	GameData.selected_weapon_id = matched_weapon["id"]
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
	selected_elements.clear()
	matched_weapons.clear()
	selected_match_index = 0
	matched_weapon = {}
	_update_display()
