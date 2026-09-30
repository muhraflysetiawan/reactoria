extends CharacterBody3D
class_name PlayerController

signal health_changed(current_hp: float, max_hp: float)
signal damaged(amount: float)

## Controller Karakter 3D untuk Battle Arena Reactoria
## Dilengkapi animasi Run asli, Idle, Jump, serta Sistem Pedang (Aqua Saber) & Animasi Serangan Combo 3-Hit

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.5
@export var jump_velocity: float = 6.2
@export var acceleration: float = 14.0
@export var friction: float = 15.0

@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -75.0
@export var max_pitch: float = 60.0
@export var default_zoom: float = 4.5
@export var min_zoom: float = 1.5
@export var max_zoom: float = 10.0

@export_group("Combat")
@export var max_health: float = 100.0
@export var base_attack_power: float = 45.0
@export var attack_reach: float = 2

@export_group("Sword Grip Offset")
## Geser posisi pedang di tangan (X: Kiri/Kanan, Y: Dari pergelangan ke telapak, Z: Maju/Mundur)
@export var sword_position: Vector3 = Vector3(55.0, 5, 2.0):
	set(val):
		sword_position = val
		_update_sword_transform()

## Sudut rotasi kemiringan pedang di tangan (Pitch, Yaw, Roll)
@export var sword_rotation: Vector3 = Vector3(-80.0, -180.0, 20.0):
	set(val):
		sword_rotation = val
		_update_sword_transform()

## Skala ukuran pedang
@export var sword_scale: Vector3 = Vector3(100.0, 100.0, 100.0):
	set(val):
		sword_scale = val
		_update_sword_transform()

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var visuals: Node3D = $Visuals

const SwordWeaponScript = preload("res://scripts/sword.gd")

var current_health: float = 100.0
var anim_player: AnimationPlayer = null
var skeleton: Skeleton3D = null
var sword: Node3D = null
var sword_attachment: BoneAttachment3D = null
var sword_holder: Node3D = null

var gravity: float = 15.0
var spawn_position: Vector3 = Vector3(0, 0.4, -5.0)
var mouse_captured: bool = true
var run_anim_name: String = "Armature|Run_02|baselayer"

# Combo Attack System
var combo_index: int = 1
var is_attacking: bool = false
var attack_timer: float = 0.0
var combo_reset_timer: float = 0.0
var attack_cooldown_timer: float = 0.2

# Camera shake
var shake_intensity: float = 0.0

func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	current_health = max_health
	health_changed.emit(current_health, max_health)
	# _update_hud_hp()
	capture_mouse()
	
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(50.0)
	floor_constant_speed = true
	floor_stop_on_slope = true

	anim_player = _find_node_of_type(self, AnimationPlayer)
	skeleton = _find_node_of_type(self, Skeleton3D)
	
	if anim_player:
		_setup_animations()
	
	_setup_sword_weapon()

func _find_node_of_type(node: Node, target_type) -> Node:
	if is_instance_of(node, target_type):
		return node
	for child in node.get_children():
		var found = _find_node_of_type(child, target_type)
		if found:
			return found
	return null

func _setup_animations() -> void:
	# Cari nama animasi lari asli di dalam glb
	for anim_name in anim_player.get_animation_list():
		if "run" in anim_name.to_lower():
			run_anim_name = anim_name
			var run_anim = anim_player.get_animation(run_anim_name)
			if run_anim:
				run_anim.loop_mode = Animation.LOOP_LINEAR
			break

	var lib = anim_player.get_animation_library("")
	if not lib:
		return

	# 1. Load animasi Idle
	if not lib.has_animation("Idle"):
		var idle_loaded: Animation = null
		if ResourceLoader.exists("res://assets/3dassets/character/anim_idle.res"):
			idle_loaded = load("res://assets/3dassets/character/anim_idle.res")
		elif ResourceLoader.exists("res://assets/3dassets/character/mc_character.glb"):
			var mc = load("res://assets/3dassets/character/mc_character.glb").instantiate()
			var ap = _find_node_of_type(mc, AnimationPlayer)
			if ap and ap.has_animation("Idle"):
				idle_loaded = ap.get_animation("Idle").duplicate()
		if idle_loaded:
			idle_loaded.loop_mode = Animation.LOOP_LINEAR
			lib.add_animation("Idle", idle_loaded)

	# 2. Load animasi Jump
	if not lib.has_animation("Jump"):
		var jump_loaded: Animation = null
		if ResourceLoader.exists("res://assets/3dassets/character/anim_jump.res"):
			jump_loaded = load("res://assets/3dassets/character/anim_jump.res")
		elif ResourceLoader.exists("res://assets/3dassets/character/mc_character.glb"):
			var mc = load("res://assets/3dassets/character/mc_character.glb").instantiate()
			var ap = _find_node_of_type(mc, AnimationPlayer)
			if ap and ap.has_animation("Jump"):
				jump_loaded = ap.get_animation("Jump").duplicate()
		if jump_loaded:
			jump_loaded.loop_mode = Animation.LOOP_NONE
			lib.add_animation("Jump", jump_loaded)

	# 3. Load animasi Attack Combos (Attack1, Attack2, Attack3)
	for i in range(1, 4):
		var anim_id = "Attack" + str(i)
		var res_path = "res://assets/3dassets/character/anim_attack" + str(i) + ".res"
		if not lib.has_animation(anim_id) and ResourceLoader.exists(res_path):
			var atk_anim: Animation = load(res_path)
			if atk_anim:
				atk_anim.loop_mode = Animation.LOOP_NONE
				lib.add_animation(anim_id, atk_anim)

	print("[Player] Animasi siap: ", anim_player.get_animation_list())
	anim_player.play("Idle")

## Memasang pedang Aqua Saber (Weapon_Sword2) ke tangan kanan (RightHand bone)
func _setup_sword_weapon() -> void:
	if not skeleton:
		print("[Player] Warning: Skeleton3D tidak ditemukan untuk memasang pedang!")
		return
		
	var hand_idx = skeleton.find_bone("RightHand")
	if hand_idx == -1:
		print("[Player] Warning: Bone RightHand tidak ditemukan!")
		return

	# Buat BoneAttachment3D ke tangan kanan
	sword_attachment = BoneAttachment3D.new()
	sword_attachment.name = "RightHandSwordAttachment"
	sword_attachment.bone_name = "RightHand"
	skeleton.add_child(sword_attachment)

	# Container pemegang pedang
	sword_holder = Node3D.new()
	sword_holder.name = "SwordHolder"
	sword_attachment.add_child(sword_holder)
	_update_sword_transform()

	# Load scene pedang
	var sword_scene = load("res://scenes/sword.tscn")
	if sword_scene:
		sword = sword_scene.instantiate()
		sword_holder.add_child(sword)
		print("[Player] Pedang Aqua Saber berhasil dipasang di RightHand!")

func _update_sword_transform() -> void:
	if sword_holder and is_instance_valid(sword_holder):
		sword_holder.position = sword_position
		sword_holder.rotation_degrees = sword_rotation
		sword_holder.scale = sword_scale

func _input(event: InputEvent) -> void:
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
			if not mouse_captured:
				capture_mouse()
			perform_attack()

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			toggle_mouse_capture()
		elif event.keycode == KEY_R:
			respawn()
		elif event.keycode == KEY_F:
			perform_attack()
		elif event.keycode == KEY_H:
			take_damage(20.0) # Debug test damage
		elif event.keycode == KEY_J:
			heal(25.0) # Debug test heal

func _physics_process(delta: float) -> void:
	# Update timers
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
	
	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0.0 and not is_attacking:
			combo_index = 1
			
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			is_attacking = false
			
	# Camera shake decay
	if shake_intensity > 0.0:
		shake_intensity = lerp(shake_intensity, 0.0, 10.0 * delta)
		if camera:
			camera.h_offset = randf_range(-shake_intensity, shake_intensity)
			camera.v_offset = randf_range(-shake_intensity, shake_intensity)
	elif camera:
		camera.h_offset = 0.0
		camera.v_offset = 0.0

	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var jump_pressed: bool = Input.is_key_pressed(KEY_SPACE)
	if InputMap.has_action("jump") and Input.is_action_just_pressed("jump"):
		jump_pressed = true
	elif InputMap.has_action("ui_accept") and Input.is_action_just_pressed("ui_accept"):
		jump_pressed = true
		
	if jump_pressed and is_on_floor() and not is_attacking:
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
		if not is_attacking:
			velocity.x = lerp(velocity.x, move_direction.x * current_speed, acceleration * delta)
			velocity.z = lerp(velocity.z, move_direction.z * current_speed, acceleration * delta)
			if visuals:
				var target_rot: float = atan2(-move_direction.x, -move_direction.z) - rotation.y
				visuals.rotation.y = lerp_angle(visuals.rotation.y, target_rot, 15.0 * delta)
		else:
			# Saat menyerang, tetap ada momentum pelan
			velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
			velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
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

	# Jangan override jika sedang memainkan animasi serangan
	if is_attacking:
		return

	if not is_on_floor():
		# Melompat di udara
		if anim_player.has_animation("Jump") and anim_player.current_animation != "Jump":
			anim_player.play("Jump", 0.15)
	elif is_moving:
		# Berlari dengan animasi asli
		var target_speed: float = 1.35 if is_sprinting else 0.95
		anim_player.speed_scale = lerp(anim_player.speed_scale, target_speed, 10.0 * delta)
		if anim_player.has_animation(run_anim_name) and anim_player.current_animation != run_anim_name:
			anim_player.play(run_anim_name, 0.2)
	else:
		# Berdiri santai (Idle)
		anim_player.speed_scale = 1.0
		if anim_player.has_animation("Idle") and anim_player.current_animation != "Idle":
			anim_player.play("Idle", 0.25)

## Eksekusi Serangan Pedang dengan Animasi Combo 3-Hit
func perform_attack() -> void:
	if attack_cooldown_timer > 0.0:
		return
	
	var current_combo = combo_index
	var anim_name = "Attack" + str(current_combo)
	var current_damage = base_attack_power
	var current_reach = attack_reach
	var lunge_force = 3.5
	var anim_speed = 1.2
	var duration = 0.36
	
	match current_combo:
		1:
			# Combo 1: Tebasan Horisontal Cepat
			current_damage = base_attack_power
			# current_reach = 3.8
			lunge_force = 4.0
			anim_speed = 1.25
			duration = 0.35
			attack_cooldown_timer = 0.8
		2:
			# Combo 2: Tebasan Diagonal Bawah Kuat
			current_damage = base_attack_power * 1.35 # ~60 dmg
			# current_reach = 4.0
			lunge_force = 5.0
			anim_speed = 1.2
			duration = 0.38
			attack_cooldown_timer = 0.8
		3:
			# Combo 3: Tebasan Putar 360 Whirlwind Finisher
			current_damage = base_attack_power * 2.1 # ~95 dmg
			# current_reach = 4.8
			lunge_force = 2.5
			anim_speed = 1.15
			duration = 0.48
			attack_cooldown_timer = 0.8

	is_attacking = true
	attack_timer = duration
	combo_reset_timer = 0.75 # Jendela waktu combo berikutnya

	# Hadapkan visual karakter ke arah pandang kamera/gerakan jika menyerang
	if visuals:
		var cam_forward = - global_transform.basis.z
		visuals.rotation.y = 0.0

	# Mainkan animasi serangan
	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name, 0.08, anim_speed)
	
	# Mainkan efek VFX & suara ayunan pedang
	if sword:
		sword.play_attack_effect(current_combo)

	# Berikan dorongan maju saat menebas (Combat Lunge)
	var forward_dir = - global_transform.basis.z
	velocity += forward_dir * lunge_force

	# Deteksi hantaman musuh (Area & Ray Hit Detection)
	_detect_sword_hits(current_damage, current_reach, current_combo)

	# Majukan indeks combo (1 -> 2 -> 3 -> 1)
	combo_index = (combo_index % 3) + 1

func _detect_sword_hits(dmg: float, reach: float, combo_step: int) -> void:
	if not is_inside_tree() or not get_tree():
		return
		
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_count = 0
	var player_forward = - global_transform.basis.z
	
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
			
		var to_enemy = enemy.global_position - global_position
		to_enemy.y = 0.0
		var dist = to_enemy.length()
		
		if dist <= reach:
			var can_hit = false
			if combo_step == 3:
				# Kombo 3 adalah tebasan putar 360 derajat penuh, mengenai semua musuh di sekeliling
				can_hit = true
			else:
				# Kombo 1 & 2 memerlukan musuh berada di busur depan pemain (~120 derajat)
				var angle = rad_to_deg(player_forward.angle_to(to_enemy.normalized()))
				if angle <= 65.0:
					can_hit = true
			
			if can_hit:
				enemy.take_damage(dmg)
				hit_count += 1
				
				# Berikan efek knockback
				var push_dir = to_enemy.normalized()
				push_dir.y = 0.25
				var knockback_power = 6.0 if combo_step < 3 else 11.0
				if "velocity" in enemy:
					enemy.velocity += push_dir * knockback_power
					
				# Partikel kilat / percikan hantaman pada musuh
				_spawn_hit_spark(enemy.global_position + Vector3(0, 1.2, 0))

	if hit_count > 0:
		shake_intensity = 0.08 if combo_step < 3 else 0.15
		if sword:
			sword.play_hit_sound()
		print("[Player] Combo %d Berhasil! Menebas %d musuh dengan %d damage!" % [combo_step, hit_count, int(dmg)])
	else:
		print("[Player] Ayunan Combo %d!" % combo_step)

func _spawn_hit_spark(pos: Vector3) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
		
	var spark = CPUParticles3D.new()
	parent_node.add_child(spark)
	spark.global_position = pos
	spark.emitting = true
	spark.one_shot = true
	spark.explosiveness = 0.95
	spark.lifetime = 0.35
	spark.amount = 14
	spark.spread = 180.0
	spark.gravity = Vector3(0, -4.0, 0)
	spark.initial_velocity_min = 2.0
	spark.initial_velocity_max = 5.0
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.4, 0.9, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.85, 1.0)
	mat.emission_energy_multiplier = 3.0
	
	var sphere = SphereMesh.new()
	sphere.radius = 0.04
	sphere.height = 0.08
	sphere.material = mat
	spark.mesh = sphere
	
	# Auto free after particles
	get_tree().create_timer(0.4).timeout.connect(spark.queue_free)

func respawn() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	current_health = max_health
	is_attacking = false
	combo_index = 1
	health_changed.emit(current_health, max_health)
	# _update_hud_hp()

func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	print("[Player] Menyembuhkan HP! HP tersisa: ", current_health)
	health_changed.emit(current_health, max_health)
	# _update_hud_hp()

func take_damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	print("[Player] Terkena serangan! HP tersisa: ", current_health)
	shake_intensity = 0.12
	damaged.emit(amount)
	health_changed.emit(current_health, max_health)
	# _update_hud_hp()
	if current_health <= 0.0:
		respawn()

# func _update_hud_hp() -> void:
# 	var hud_hp = get_tree().root.find_child("PlayerHPLabel", true, false)
# 	if hud_hp and hud_hp is Label:
# 		hud_hp.text = "❤️ HP : %d / %d" % [int(current_health), int(max_health)]

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
