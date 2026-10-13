extends Control
## Combine Element UI — Pemain meracik dua unsur/senyawa di atas meja alchemy untuk menempa senjata.

const ARENA_SCENE := "res://scenes/main.tscn"

const SFX_HOVER := preload("res://assets/audio/ui/hover-button.mp3")
const SFX_CLICK := preload("res://assets/audio/ui/select-button2.mp3")

@onready var bg: TextureRect = %Background
@onready var back_button: Button = %BackButton
@onready var element_grid: GridContainer = %ElementGrid

# Tengah - Meja Racik
@onready var slot_a_panel: PanelContainer = %SlotAPanel
@onready var slot_a_icon: TextureRect = %SlotAIcon
@onready var slot_a_label: Label = %SlotALabel
@onready var slot_a_name: Label = %SlotAName

@onready var slot_b_panel: PanelContainer = %SlotBPanel
@onready var slot_b_icon: TextureRect = %SlotBIcon
@onready var slot_b_label: Label = %SlotBLabel
@onready var slot_b_name: Label = %SlotBName

@onready var combine_button: Button = %CombineButton
@onready var reset_button: Button = %ResetButton

# Kanan - Hasil Gabungan
@onready var result_panel: PanelContainer = %ResultPanel
@onready var rune_circle_bg: TextureRect = %RuneCircleBg
@onready var result_icon: TextureRect = %ResultIcon
@onready var result_question: Label = %ResultQuestion
@onready var result_name: Label = %ResultName
@onready var result_formula: Label = %ResultFormula
@onready var result_desc: Label = %ResultDesc

var _sfx_hover: AudioStreamPlayer
var _sfx_click: AudioStreamPlayer

# State racik
var slot_a: String = ""
var count_a: int = 0
var slot_b: String = ""
var count_b: int = 0
var matched_weapon: Dictionary = {}

var all_elements: Array[String] = []
var _element_buttons: Dictionary = {}

var slot_a_count: Label
var slot_b_count: Label

func _ready() -> void:
	_init_sfx()
	_setup_count_badges()
	_gather_elements()
	_build_element_buttons()
	_connect_slot_clicks()
	_update_display()

	# Fade in
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)

func _setup_count_badges() -> void:
	slot_a_count = _create_count_badge(slot_a_panel)
	slot_b_count = _create_count_badge(slot_b_panel)

func _create_count_badge(parent: PanelContainer) -> Label:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)

	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_SHRINK_END
	lbl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.add_theme_constant_override("shadow_outline_size", 2)
	lbl.visible = false

	margin.add_child(lbl)
	parent.add_child(margin)
	return lbl

func _get_max_element_count(el: String) -> int:
	var m := 1
	for w in GameData.WEAPONS:
		if w["element_a"] == el:
			m = max(m, w.get("count_a", 1))
		if w["element_b"] == el:
			m = max(m, w.get("count_b", 1))
	return m

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

func _connect_slot_clicks() -> void:
	slot_a_panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not slot_a.is_empty():
				_sfx_click.play()
				slot_a = ""
				count_a = 0
				_check_recipe()
				_update_display()
	)
	slot_b_panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not slot_b.is_empty():
				_sfx_click.play()
				slot_b = ""
				count_b = 0
				_check_recipe()
				_update_display()
	)

func _on_element_pressed(el: String) -> void:
	_sfx_click.play()
	if slot_a == el:
		if count_a < _get_max_element_count(el):
			count_a += 1
		else:
			slot_a = ""
			count_a = 0
	elif slot_b == el:
		if count_b < _get_max_element_count(el):
			count_b += 1
		else:
			slot_b = ""
			count_b = 0
	elif slot_a.is_empty():
		slot_a = el
		count_a = 1
	elif slot_b.is_empty():
		slot_b = el
		count_b = 1
	else:
		slot_a = el
		count_a = 1
		slot_b = ""
		count_b = 0

	_check_recipe()
	_update_display()

func _check_recipe() -> void:
	matched_weapon = {}
	if slot_a.is_empty() or slot_b.is_empty():
		return
	for w in GameData.WEAPONS:
		var req_a: String = w["element_a"]
		var req_b: String = w["element_b"]
		var req_ca: int = w.get("count_a", 1)
		var req_cb: int = w.get("count_b", 1)
		if (slot_a == req_a and count_a == req_ca and slot_b == req_b and count_b == req_cb) \
			or (slot_a == req_b and count_a == req_cb and slot_b == req_a and count_b == req_ca):
			matched_weapon = w
			return

func _update_display() -> void:
	_update_slot(slot_a, count_a, slot_a_panel, slot_a_icon, slot_a_label, slot_a_name, slot_a_count)
	_update_slot(slot_b, count_b, slot_b_panel, slot_b_icon, slot_b_label, slot_b_name, slot_b_count)
	_update_element_button_highlights()

	if not matched_weapon.is_empty():
		result_question.visible = false
		result_icon.visible = true
		var elem_info: Dictionary = _get_element_info(slot_a)
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
	else:
		result_question.visible = true
		result_icon.visible = false
		result_formula.visible = false
		result_name.text = "???"
		result_name.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
		rune_circle_bg.modulate = Color(0.5, 0.55, 0.6, 0.45)
		combine_button.disabled = true

		if slot_a.is_empty() and slot_b.is_empty():
			result_desc.text = "Gabungkan dua unsur untuk menemukan unsur baru!"
			bg.texture = load("res://assets/ui/campaign/combine-element-2.jpeg")
		elif not slot_b.is_empty():
			result_desc.text = "Kombinasi tidak valid! Coba padukan unsur lain."
			bg.texture = load("res://assets/ui/campaign/combine-element-2.jpeg")
		else:
			result_desc.text = "Pilih unsur kedua dari daftar di sebelah kiri..."
			bg.texture = load("res://assets/ui/campaign/combine-element.jpeg")
		result_desc.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))

func _update_slot(
	el: String,
	count: int,
	panel: PanelContainer,
	icon_node: TextureRect,
	lbl_node: Label,
	name_node: Label,
	count_node: Label
) -> void:
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if el.is_empty():
		icon_node.visible = false
		lbl_node.visible = true
		lbl_node.text = "?"
		lbl_node.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		name_node.text = "Pilih Unsur"
		name_node.add_theme_color_override("font_color", Color(0.65, 0.6, 0.52))
		if count_node:
			count_node.visible = false
		if style:
			style.border_color = Color(0.42, 0.35, 0.25, 0.75)
	else:
		var info: Dictionary = _get_element_info(el)
		icon_node.visible = true
		icon_node.texture = load(info["icon"])
		lbl_node.visible = false
		name_node.text = el
		name_node.add_theme_color_override("font_color", info["color"])
		if count_node:
			count_node.text = str(count)
			count_node.visible = (count > 1)
		if style:
			style.border_color = info["color"]

func _update_element_button_highlights() -> void:
	for el: String in _element_buttons:
		var btn: Button = _element_buttons[el]
		var is_selected: bool = (el == slot_a or el == slot_b)
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
	slot_a = ""
	count_a = 0
	slot_b = ""
	count_b = 0
	matched_weapon = {}
	_update_display()
