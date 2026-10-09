extends Control
## Main Menu — handles button interactions, shader-driven hover animations,
## and scene transitions for Campaign, Creative, Setting, and Credits.

# Scene paths — update these when the target scenes are created.
const CAMPAIGN_SCENE := "res://scenes/main.tscn"
const CREATIVE_SCENE := "" # TODO: create creative mode scene
const SETTING_SCENE := "" # TODO: create settings scene
const CREDITS_SCENE := "" # TODO: create credits scene

@onready var campaign_slot: Control = %CampaignSlot
@onready var creative_slot: Control = %CreativeSlot
@onready var setting_slot: Control = %SettingSlot
# @onready var credit_slot: Control = %CreditSlot

@onready var campaign_frame: ColorRect = %CampaignFrame
@onready var creative_frame: ColorRect = %CreativeFrame
@onready var setting_frame: ColorRect = %SettingFrame
# @onready var credit_frame: ColorRect = %CreditFrame

@onready var campaign_button: Button = %CampaignButton
@onready var creative_button: Button = %CreativeButton
@onready var setting_button: Button = %SettingButton
# @onready var credit_button: Button = %CreditButton

# Sound effects
const SFX_HOVER := preload("res://assets/audio/ui/hover-button.mp3")
const SFX_CLICK := preload("res://assets/audio/ui/select-button2.mp3")

var _sfx_hover_player: AudioStreamPlayer
var _sfx_click_player: AudioStreamPlayer


func _ready() -> void:
	_init_sfx()

	# Connect hover signals for shader animation & sfx
	_connect_hover(campaign_button, campaign_frame)
	_connect_hover(creative_button, creative_frame)
	_connect_hover(setting_button, setting_frame)
	# _connect_hover(credit_button, credit_frame)

	# Fade-in animation on menu load
	modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_OUT)

	# Animasi kemunculan tombol yang diatur secara bertahap
	var slots: Array[Control] = [campaign_slot, creative_slot, setting_slot]
	for i in slots.size():
		var slot := slots[i]
		slot.modulate.a = 0.0
		slot.position.x -= 40.0
		var t := create_tween().set_parallel(true)
		t.tween_property(slot, "modulate:a", 1.0, 0.4) \
			.set_delay(0.3 + i * 0.12).set_ease(Tween.EASE_OUT)
		t.tween_property(slot, "position:x", slot.position.x + 40.0, 0.4) \
			.set_delay(0.3 + i * 0.12).set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_BACK)


# Tracks active hover tweens per frame to avoid conflicts
var _hover_tweens: Dictionary = {}


func _init_sfx() -> void:
	_sfx_hover_player = AudioStreamPlayer.new()
	_sfx_hover_player.stream = SFX_HOVER
	add_child(_sfx_hover_player)

	_sfx_click_player = AudioStreamPlayer.new()
	_sfx_click_player.stream = SFX_CLICK
	add_child(_sfx_click_player)


# ---------- Hover Animation (Shader-driven) & SFX ----------

func _connect_hover(btn: Button, frame: ColorRect) -> void:
	btn.mouse_entered.connect(func():
		_sfx_hover_player.play()
		_animate_hover(frame, 1.0)
	)
	btn.mouse_exited.connect(_animate_hover.bind(frame, 0.0))


func _animate_hover(frame: ColorRect, target: float) -> void:
	# Kill any running tween for this frame
	if _hover_tweens.has(frame) and _hover_tweens[frame].is_running():
		_hover_tweens[frame].kill()
	var mat := frame.material as ShaderMaterial
	if mat == null:
		return
	var current := float(mat.get_shader_parameter("hover"))
	var duration := 0.15 if target > 0.5 else 0.25
	var ease_type := Tween.EASE_OUT if target > 0.5 else Tween.EASE_IN
	var t := create_tween()
	t.tween_method(
		func(v: float): mat.set_shader_parameter("hover", v),
		current, target, duration
	).set_ease(ease_type)
	_hover_tweens[frame] = t


# ---------- Button Callbacks ----------

func _on_campaign_pressed() -> void:
	_sfx_click_player.play()
	_transition_to_scene(CAMPAIGN_SCENE)

func _on_creative_pressed() -> void:
	_sfx_click_player.play()
	if CREATIVE_SCENE.is_empty():
		push_warning("Creative scene not yet assigned.")
		return
	_transition_to_scene(CREATIVE_SCENE)

func _on_setting_pressed() -> void:
	_sfx_click_player.play()
	if SETTING_SCENE.is_empty():
		push_warning("Setting scene not yet assigned.")
		return
	_transition_to_scene(SETTING_SCENE)

func _on_credit_pressed() -> void:
	_sfx_click_player.play()
	if CREDITS_SCENE.is_empty():
		push_warning("Credits scene not yet assigned.")
		return
	_transition_to_scene(CREDITS_SCENE)

# ---------- Scene Transition ----------

func _transition_to_scene(scene_path: String) -> void:
	# Prevent double-clicks
	set_process_input(false)
	# Fade out then switch scene
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN)
	t.tween_callback(func(): get_tree().change_scene_to_file(scene_path))
