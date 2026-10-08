extends Control
## Main Menu script — handles button interactions, hover animations,
## and scene transitions for Campaign, Creative, Setting, and Credits.

# Scene paths — update these when the target scenes are created.
const CAMPAIGN_SCENE := "res://scenes/main.tscn"
const CREATIVE_SCENE := ""  # TODO: create creative mode scene
const SETTING_SCENE := ""   # TODO: create settings scene
const CREDITS_SCENE := ""   # TODO: create credits scene

@onready var campaign_button: Button = %CampaignButton
@onready var creative_button: Button = %CreativeButton
@onready var setting_button: Button = %SettingButton

var _tween: Tween


func _ready() -> void:
	# Fade-in animation on menu load
	modulate.a = 0.0
	var fade_tween := create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_OUT)

	# Stagger button entrance animations
	var buttons: Array[Button] = [campaign_button, creative_button, setting_button]
	for i in buttons.size():
		var btn := buttons[i]
		btn.modulate.a = 0.0
		btn.position.x -= 40.0
		var btn_tween := create_tween()
		btn_tween.set_parallel(true)
		btn_tween.tween_property(btn, "modulate:a", 1.0, 0.4).set_delay(0.3 + i * 0.12).set_ease(Tween.EASE_OUT)
		btn_tween.tween_property(btn, "position:x", btn.position.x + 40.0, 0.4).set_delay(0.3 + i * 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


# ---------- Button Callbacks ----------

func _on_campaign_pressed() -> void:
	_transition_to_scene(CAMPAIGN_SCENE)


func _on_creative_pressed() -> void:
	if CREATIVE_SCENE.is_empty():
		push_warning("Creative scene not yet assigned.")
		return
	_transition_to_scene(CREATIVE_SCENE)


func _on_setting_pressed() -> void:
	if SETTING_SCENE.is_empty():
		push_warning("Setting scene not yet assigned.")
		return
	_transition_to_scene(SETTING_SCENE)


func _on_credits_pressed() -> void:
	if CREDITS_SCENE.is_empty():
		push_warning("Credits scene not yet assigned.")
		return
	_transition_to_scene(CREDITS_SCENE)


# ---------- Hover Animation ----------

func _on_button_hover(button_name: String) -> void:
	var btn := get_node_or_null("MenuContainer/" + button_name) as Button
	if btn == null:
		return
	# Quick scale-pulse on hover
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	btn.pivot_offset = btn.size / 2.0
	_tween.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.1).set_ease(Tween.EASE_OUT)
	_tween.tween_property(btn, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_IN)


# ---------- Scene Transition ----------

func _transition_to_scene(scene_path: String) -> void:
	# Prevent double-clicks
	set_process_input(false)
	# Fade out then switch scene
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN)
	t.tween_callback(func(): get_tree().change_scene_to_file(scene_path))
