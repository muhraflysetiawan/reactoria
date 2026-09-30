extends CharacterBody3D
class_name PlayerController

## Controller Karakter 3D untuk menguji dan menjelajahi Arena
## Menjalankan animasi lari asli (Run_02), serta animasi Idle (tanpa T-pose) dan Jump

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 6.0
@export var acceleration: float = 12.0
@export var friction: float = 14.0

@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -75.0
@export var max_pitch: float = 60.0
@export var default_zoom: float = 4.5
@export var min_zoom: float = 1.5
@export var max_zoom: float = 10.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var mesh: Node3D = $Visuals

@export_group("Combat")
@export var max_health: float = 100.0
@export var attack_power: float = 50.0
@export var attack_reach: float = 3.8

var current_health: float = 100.0
var attack_cooldown_timer: float = 0.0

var anim_player: AnimationPlayer = null
var gravity: float = 15.0
var spawn_position: Vector3 = Vector3(0, 0.4, -5.0)
var mouse_captured: bool = true
var run_anim_name: String = "Armature|Run_02|baselayer"

func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	current_health = max_health
	capture_mouse()
	
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(50.0)
	floor_constant_speed = true
	floor_stop_on_slope = true

	anim_player = _find_animation_player(self)
	if anim_player:
		_setup_animations()

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found = _find_animation_player(child)
		if found:
			return found
	return null

func _setup_animations() -> void:
	# Cari nama animasi lari asli di dalam glb
	var run_anim: Animation = null
	for anim_name in anim_player.get_animation_list():
		if "run" in anim_name.to_lower():
			run_anim_name = anim_name
			run_anim = anim_player.get_animation(run_anim_name)
			if run_anim:
				run_anim.loop_mode = Animation.LOOP_LINEAR
			break

	var lib = anim_player.get_animation_library("")
	if not lib:
		return

	# Load animasi Idle otentik (berdiri tegak lurus sempurna, simetris, nafas halus)
	if not lib.has_animation("Idle"):
		var idle_loaded: Animation = null
		if ResourceLoader.exists("res://assets/3dassets/character/anim_idle.res"):
			idle_loaded = load("res://assets/3dassets/character/anim_idle.res")
		elif ResourceLoader.exists("res://assets/3dassets/character/mc_character.glb"):
			var mc = load("res://assets/3dassets/character/mc_character.glb").instantiate()
			var ap = _find_animation_player(mc)
			if ap and ap.has_animation("Idle"):
				idle_loaded = ap.get_animation("Idle").duplicate()
		if idle_loaded:
			idle_loaded.loop_mode = Animation.LOOP_LINEAR
			lib.add_animation("Idle", idle_loaded)

	# Load animasi Jump otentik
	if not lib.has_animation("Jump"):
		var jump_loaded: Animation = null
		if ResourceLoader.exists("res://assets/3dassets/character/anim_jump.res"):
			jump_loaded = load("res://assets/3dassets/character/anim_jump.res")
		elif ResourceLoader.exists("res://assets/3dassets/character/mc_character.glb"):
			var mc = load("res://assets/3dassets/character/mc_character.glb").instantiate()
			var ap = _find_animation_player(mc)
			if ap and ap.has_animation("Jump"):
				jump_loaded = ap.get_animation("Jump").duplicate()
		if jump_loaded:
			jump_loaded.loop_mode = Animation.LOOP_NONE
			lib.add_animation("Jump", jump_loaded)

	print("[Player] Animasi siap: ", anim_player.get_animation_list())
	anim_player.play("Idle")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clamp(spring_arm.spring_length - 0.4, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clamp(spring_arm.spring_length + 0.4, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_captured:
				perform_attack()
			else:
				capture_mouse()

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			toggle_mouse_capture()
		elif event.keycode == KEY_R:
			respawn()
		elif event.keycode == KEY_F:
			perform_attack()

func _physics_process(delta: float) -> void:
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var jump_pressed: bool = Input.is_key_pressed(KEY_SPACE)
	if InputMap.has_action("jump") and Input.is_action_just_pressed("jump"):
		jump_pressed = true
	elif InputMap.has_action("ui_accept") and Input.is_action_just_pressed("ui_accept"):
		jump_pressed = true
		
	if jump_pressed and is_on_floor():
		velocity.y = jump_velocity

	var is_sprinting: bool = Input.is_key_pressed(KEY_SHIFT) or (InputMap.has_action("sprint") and Input.is_action_pressed("sprint"))
	var current_speed: float = sprint_speed if is_sprinting else walk_speed

	var input_dir: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or (InputMap.has_action("move_forward") and Input.is_action_pressed("move_forward")):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or (InputMap.has_action("move_backward") and Input.is_action_pressed("move_backward")):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or (InputMap.has_action("move_left") and Input.is_action_pressed("move_left")):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or (InputMap.has_action("move_right") and Input.is_action_pressed("move_right")):
		input_dir.x += 1.0

	input_dir = input_dir.normalized()
	var move_direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if move_direction != Vector3.ZERO:
		velocity.x = lerp(velocity.x, move_direction.x * current_speed, acceleration * delta)
		velocity.z = lerp(velocity.z, move_direction.z * current_speed, acceleration * delta)
		if mesh:
			var target_rot: float = atan2(-move_direction.x, -move_direction.z) - rotation.y
			mesh.rotation.y = lerp_angle(mesh.rotation.y, target_rot, 15.0 * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.z = lerp(velocity.z, 0.0, friction * delta)

	move_and_slide()

	# Kontrol Animasi
	_update_animation(delta, move_direction != Vector3.ZERO, is_sprinting)

	if global_position.y < -15.0:
		respawn()

func _update_animation(delta: float, is_moving: bool, is_sprinting: bool) -> void:
	if not anim_player:
		return

	if not is_on_floor():
		# Melompat di udara
		if anim_player.has_animation("Jump") and anim_player.current_animation != "Jump":
			anim_player.play("Jump", 0.15)
	elif is_moving:
		# Berlari dengan animasi asli (kaki dan lengan berayun aktif)
		var target_speed: float = 1.35 if is_sprinting else 0.95
		anim_player.speed_scale = lerp(anim_player.speed_scale, target_speed, 10.0 * delta)
		if anim_player.has_animation(run_anim_name) and anim_player.current_animation != run_anim_name:
			anim_player.play(run_anim_name, 0.2)
	else:
		# Berdiri santai (lengan di samping, pernapasan dada)
		anim_player.speed_scale = 1.0
		if anim_player.has_animation("Idle") and anim_player.current_animation != "Idle":
			anim_player.play("Idle", 0.25)

func respawn() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	current_health = max_health
	_update_hud_hp()

func perform_attack() -> void:
	if attack_cooldown_timer > 0.0:
		return
	attack_cooldown_timer = 0.4
	
	# Cari musuh dalam jangkauan serangan
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_count = 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			var d = global_position.distance_to(enemy.global_position)
			if d <= attack_reach:
				enemy.take_damage(attack_power)
				hit_count += 1
				# Knockback kecil pada musuh
				var push_dir = (enemy.global_position - global_position).normalized()
				push_dir.y = 0.2
				if "velocity" in enemy:
					enemy.velocity += push_dir * 5.0
	
	if hit_count > 0:
		print("[Player] Menyerang %d musuh! Damage: %d" % [hit_count, attack_power])
	else:
		print("[Player] Ayunan serangan!")

func take_damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	print("[Player] Terkena serangan! HP tersisa: ", current_health)
	_update_hud_hp()
	if current_health <= 0.0:
		respawn()

func _update_hud_hp() -> void:
	var hud_hp = get_tree().root.find_child("PlayerHPLabel", true, false)
	if hud_hp and hud_hp is Label:
		hud_hp.text = "❤️ HP: %d / %d" % [int(current_health), int(max_health)]

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func toggle_mouse_capture() -> void:
	if mouse_captured:
		release_mouse()
	else:
		capture_mouse()
