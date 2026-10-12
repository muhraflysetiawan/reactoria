extends Control
## Combine Element UI — Pemain meracik dua unsur/senyawa di atas meja alchemy untuk menempa senjata.

const ARENA_SCENE := "res://scenes/main.tscn"

const SFX_HOVER := preload("res://assets/audio/ui/hover-button.mp3")
const SFX_CLICK := preload("res://assets/audio/ui/select-button2.mp3")

# Metadata mapping untuk 12 unsur/senyawa ke icon SVG dan warna representatif
const ELEMENT_INFO: Dictionary = {
	"H₂": {
		"name": "Hidrogen (H₂)",
		"icon": "res://assets/ui/campaign/elements/water.svg",
		"color": Color(0.35, 0.75, 1.0),
	},
	"O": {
		"name": "Oksigen (O)",
		"icon": "res://assets/ui/campaign/elements/wind.svg",
		"color": Color(0.45, 0.85, 0.95),
	},
	"K": {
		"name": "Kalium (K)",
		"icon": "res://assets/ui/campaign/elements/lightning.svg",
		"color": Color(0.85, 0.6, 1.0),
	},
	"OH": {
		"name": "Hidroksida (OH)",
		"icon": "res://assets/ui/campaign/elements/ice.svg",
		"color": Color(0.5, 0.9, 0.9),
	},
	"H": {
		"name": "Hidrogen (H)",
		"icon": "res://assets/ui/campaign/elements/star.svg",
		"color": Color(0.95, 0.9, 0.5),
	},
	"Cl": {
		"name": "Klorin (Cl)",
		"icon": "res://assets/ui/campaign/elements/poison.svg",
		"color": Color(0.4, 0.9, 0.35),
	},
	"Mg": {
		"name": "Magnesium (Mg)",
		"icon": "res://assets/ui/campaign/elements/metal.svg",
		"color": Color(0.9, 0.7, 0.35),
	},
	"Na": {
		"name": "Natrium (Na)",
		"icon": "res://assets/ui/campaign/elements/earth.svg",
		"color": Color(0.95, 0.82, 0.45),
	},
	"C₁₀": {
		"name": "Karbon (C₁₀)",
		"icon": "res://assets/ui/campaign/elements/fire.svg",
		"color": Color(1.0, 0.35, 0.2),
	},
	"H₈": {
		"name": "Hidrogen (H₈)",
		"icon": "res://assets/ui/campaign/elements/dark.svg",
		"color": Color(0.7, 0.45, 0.85),
	},
	"C₃": {
		"name": "Propana (C₃)",
		"icon": "res://assets/ui/campaign/elements/leaf.svg",
		"color": Color(1.0, 0.55, 0.2),
	},
	"F₃": {
		"name": "Fluorin (F₃)",
		"icon": "res://assets/ui/campaign/elements/aether.svg",
		"color": Color(0.3, 0.95, 0.85),
	},
}

const DEFAULT_ICON := "res://assets/ui/campaign/elements/alchemy_flask.svg"

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
var slot_b: String = ""
var matched_weapon: Dictionary = {}

var all_elements: Array[String] = []
var _element_buttons: Dictionary = {}

func _ready() -> void:
	_init_sfx()
	_gather_elements()
	_build_element_buttons()
	_connect_slot_clicks()
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
		for key in ["element_a", "element_b"]:
			var el: String = w[key]
			if not seen.has(el):
				seen[el] = true
				all_elements.append(el)

func _get_element_info(el: String) -> Dictionary:
	if ELEMENT_INFO.has(el):
		return ELEMENT_INFO[el]
	return {
		"name": el,
		"icon": DEFAULT_ICON,
		"color": Color(0.8, 0.85, 0.9),
	}

func _build_element_buttons() -> void:
	for child in element_grid.get_children():
		child.queue_free()
	_element_buttons.clear()

	for el in all_elements:
		var info: Dictionary = _get_element_info(el)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(88, 86)
		btn.tooltip_text = info["name"]
		btn.focus_mode = Control.FOCUS_NONE

		var vbox := VBoxContainer.new()
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_theme_constant_override("separation", 4)

		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(38, 38)
		icon_rect.texture = load(info["icon"])
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(icon_rect)

		var lbl := Label.new()
		lbl.text = el
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(lbl)

		btn.add_child(vbox)

		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0.10, 0.11, 0.15, 0.88)
		normal_style.border_color = Color(0.35, 0.32, 0.28, 0.75)
		normal_style.set_border_width_all(2)
		normal_style.set_corner_radius_all(8)
		normal_style.set_content_margin_all(6)
		btn.add_theme_stylebox_override("normal", normal_style)

		var hover_style := normal_style.duplicate()
		hover_style.bg_color = Color(0.18, 0.22, 0.28, 0.95)
		hover_style.border_color = Color(0.45, 0.75, 0.85, 1.0)
		btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style := normal_style.duplicate()
		pressed_style.bg_color = Color(0.08, 0.15, 0.2, 1.0)
		pressed_style.border_color = Color(0.3, 0.9, 0.7, 1.0)
		btn.add_theme_stylebox_override("pressed", pressed_style)

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
				_check_recipe()
				_update_display()
	)
	slot_b_panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not slot_b.is_empty():
				_sfx_click.play()
				slot_b = ""
				_check_recipe()
				_update_display()
	)

func _on_element_pressed(el: String) -> void:
	_sfx_click.play()
	if slot_a == el:
		slot_a = ""
	elif slot_b == el:
		slot_b = ""
	elif slot_a.is_empty():
		slot_a = el
	elif slot_b.is_empty():
		slot_b = el
	else:
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
	_update_slot(slot_a, slot_a_panel, slot_a_icon, slot_a_label, slot_a_name)
	_update_slot(slot_b, slot_b_panel, slot_b_icon, slot_b_label, slot_b_name)
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
		elif not slot_b.is_empty():
			result_desc.text = "Kombinasi tidak valid! Coba padukan unsur lain."
		else:
			result_desc.text = "Pilih unsur kedua dari daftar di sebelah kiri..."
		result_desc.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))

func _update_slot(
	el: String,
	panel: PanelContainer,
	icon_node: TextureRect,
	lbl_node: Label,
	name_node: Label
) -> void:
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if el.is_empty():
		icon_node.visible = false
		lbl_node.visible = true
		lbl_node.text = "?"
		lbl_node.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		name_node.text = "Pilih Unsur"
		name_node.add_theme_color_override("font_color", Color(0.65, 0.6, 0.52))
		if style:
			style.border_color = Color(0.42, 0.35, 0.25, 0.75)
	else:
		var info: Dictionary = _get_element_info(el)
		icon_node.visible = true
		icon_node.texture = load(info["icon"])
		lbl_node.visible = false
		name_node.text = el
		name_node.add_theme_color_override("font_color", info["color"])
		if style:
			style.border_color = info["color"]

func _update_element_button_highlights() -> void:
	for el: String in _element_buttons:
		var btn: Button = _element_buttons[el]
		var is_selected: bool = (el == slot_a or el == slot_b)
		var style := btn.get_theme_stylebox("normal") as StyleBoxFlat
		if style:
			if is_selected:
				var info: Dictionary = _get_element_info(el)
				style.bg_color = Color(0.15, 0.25, 0.25, 0.95)
				style.border_color = info["color"]
			else:
				style.bg_color = Color(0.10, 0.11, 0.15, 0.88)
				style.border_color = Color(0.35, 0.32, 0.28, 0.75)

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
	slot_b = ""
	matched_weapon = {}
	_update_display()
