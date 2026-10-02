extends CharacterBody3D
class_name GolemEnemy

## Script AI Musuh Golem Berbasis Fisik
## Mendukung 5 Varian Elemen: Earth, Ice, Lava, Lightning, Wind
## Dilengkapi sistem State Machine, Navigasi Fisik, Animasi Realistis, Serangan Hantam Tanah, dan Health System

enum Element { EARTH, ICE, LAVA, LIGHTNING, WIND }
enum State { IDLE, PATROL, CHASE, ATTACK, HIT, DEAD }

@export_group("Golem Identity")
@export var element_type: Element = Element.EARTH
@export var golem_title: String = "Stone Colossus"
@export var element_color: Color = Color(0.4, 0.85, 0.4)

@export_group("Combat Stats")
@export var max_health: float = 250.0
@export var attack_damage: float = 30.0
@export var attack_cooldown: float = 0.5
@export var attack_range: float = 3.2
@export var detection_range: float = 10.0
@export var patrol_range: float = 5.0

@export_group("Movement")
@export var walk_speed: float = 2.4
@export var chase_speed: float = 4.2
@export var rotation_speed: float = 4.5
@export var gravity: float = 18.0

var current_health: float = 250.0
var current_state: State = State.IDLE
var player: CharacterBody3D = null
var spawn_point: Vector3 = Vector3.ZERO
var patrol_target: Vector3 = Vector3.ZERO

var anim_player: AnimationPlayer = null
var state_timer: float = 0.0
var attack_timer: float = 0.0
var has_dealt_damage_this_attack: bool = false
var label_title: Label3D = null
var label_hp: Label3D = null

func _ready() -> void:
	add_to_group("enemies")
	spawn_point = global_position
	current_health = max_health
	
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(50.0)
	floor_stop_on_slope = true
	
	_find_anim_player(self)
	_setup_overhead_ui()
	_apply_elemental_identity()
	
	# Cari player di tree
	player = get_tree().get_first_node_in_group("player")
	if not player:
		# Fallback cari berdasarkan nama
		var p = get_parent().find_child("Player", true, false)
		if p is CharacterBody3D:
			player = p

	_set_state(State.IDLE)

func _find_anim_player(node: Node) -> void:
	if node is AnimationPlayer:
		anim_player = node
		return
	for c in node.get_children():
		_find_anim_player(c)
		if anim_player:
			return

func _apply_elemental_identity() -> void:
	match element_type:
		Element.EARTH:
			golem_title = "Mossback Colossus [Earth]"
			element_color = Color(0.45, 0.85, 0.35)
		Element.ICE:
			golem_title = "Frostcrag Colossus [Ice]"
			element_color = Color(0.4, 0.85, 1.0)
		Element.LAVA:
			golem_title = "Molten Titan [Lava]"
			element_color = Color(1.0, 0.45, 0.15)
		Element.LIGHTNING:
			golem_title = "Stormheart Golem [Lightning]"
			element_color = Color(1.0, 0.9, 0.25)
		Element.WIND:
			golem_title = "Cyan Tempest [Wind]"
			element_color = Color(0.3, 0.95, 0.85)

	if label_title:
		label_title.text = golem_title
		label_title.modulate = element_color
	_update_hp_display()

func _setup_overhead_ui() -> void:
	# Nama Golem Billboard di atas kepala
	label_title = Label3D.new()
	label_title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_title.position = Vector3(0, 2.65, 0)
	label_title.font_size = 28
	label_title.outline_size = 6
	label_title.outline_modulate = Color.BLACK
	label_title.text = golem_title
	label_title.modulate = element_color
	add_child(label_title)
	
	# Bar HP Text
	label_hp = Label3D.new()
	label_hp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_hp.position = Vector3(0, 2.45, 0)
	label_hp.font_size = 22
	label_hp.outline_size = 4
	label_hp.outline_modulate = Color.BLACK
	add_child(label_hp)
	_update_hp_display()

func _update_hp_display() -> void:
	if not label_hp:
		return
	var pct = max(0, int((current_health / max_health) * 100.0))
	var bar_filled = int(pct / 10.0)
	var bar_empty = 10 - bar_filled
	var bar_str = "█".repeat(bar_filled) + "░".repeat(bar_empty)
	label_hp.text = "[%s] %d / %d HP" % [bar_str, int(current_health), int(max_health)]
	if pct > 50:
		label_hp.modulate = Color(0.3, 0.95, 0.4)
	elif pct > 25:
		label_hp.modulate = Color(1.0, 0.8, 0.2)
	else:
		label_hp.modulate = Color(0.95, 0.25, 0.2)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if current_state == State.DEAD:
		velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)
		move_and_slide()
		return

	if attack_timer > 0.0:
		attack_timer -= delta
	state_timer += delta

	# Cari player jika belum terdeteksi
	if not is_instance_valid(player):
		var p = get_parent().find_child("Player", true, false)
		if p is CharacterBody3D:
			player = p

	var player_alive = _is_player_alive()
	var dist_to_player = 999.0
	if player_alive:
		dist_to_player = global_position.distance_to(player.global_position)

	# State Machine Logic
	match current_state:
		State.IDLE:
			velocity.x = lerp(velocity.x, 0.0, 8.0 * delta)
			velocity.z = lerp(velocity.z, 0.0, 8.0 * delta)
			
			if dist_to_player <= detection_range:
				_set_state(State.CHASE)
			elif state_timer >= 3.5:
				_pick_patrol_target()
				_set_state(State.PATROL)

		State.PATROL:
			if dist_to_player <= detection_range:
				_set_state(State.CHASE)
			else:
				var to_target = patrol_target - global_position
				to_target.y = 0.0
				var dist = to_target.length()
				if dist <= 1.2 or state_timer >= 8.0:
					_set_state(State.IDLE)
				else:
					var dir = to_target.normalized()
					velocity.x = dir.x * walk_speed
					velocity.z = dir.z * walk_speed
					_rotate_towards(dir, delta)

		State.CHASE:
			if not player_alive or dist_to_player > detection_range * 1.35:
				_set_state(State.IDLE)
			elif dist_to_player <= attack_range and attack_timer <= 0.0:
				_set_state(State.ATTACK)
			else:
				var to_player = player.global_position - global_position
				to_player.y = 0.0
				var dir = to_player.normalized()
				velocity.x = dir.x * chase_speed
				velocity.z = dir.z * chase_speed
				_rotate_towards(dir, delta)

		State.ATTACK:
			if not player_alive:
				_set_state(State.IDLE)
				return

			velocity.x = lerp(velocity.x, 0.0, 12.0 * delta)
			velocity.z = lerp(velocity.z, 0.0, 12.0 * delta)
			
			# Orientasikan badan ke player di awal serangan
			if state_timer < 0.4 and is_instance_valid(player):
				var to_p = player.global_position - global_position
				to_p.y = 0.0
				_rotate_towards(to_p.normalized(), delta * 2.0)

			# Frame hentakan hantam tanah (slam impact pada detik ~0.95)
			if state_timer >= 0.92 and not has_dealt_damage_this_attack:
				_execute_ground_slam()
				has_dealt_damage_this_attack = true

			# Selesai animasi serangan (panjang 1.5s)
			if state_timer >= 1.5:
				attack_timer = attack_cooldown
				if not player_alive or dist_to_player > attack_range:
					_set_state(State.CHASE if player_alive else State.IDLE)
				else:
					_set_state(State.IDLE)

		State.HIT:
			velocity.x = lerp(velocity.x, 0.0, 8.0 * delta)
			velocity.z = lerp(velocity.z, 0.0, 8.0 * delta)
			if state_timer >= 0.65:
				_set_state(State.CHASE)

	move_and_slide()

func _set_state(new_state: State) -> void:
	current_state = new_state
	state_timer = 0.0
	
	if not anim_player:
		return
		
	match new_state:
		State.IDLE:
			anim_player.speed_scale = 1.0
			if anim_player.has_animation("Idle"):
				anim_player.play("Idle", 0.3)
		State.PATROL:
			anim_player.speed_scale = 0.85
			if anim_player.has_animation("Walk"):
				anim_player.play("Walk", 0.25)
		State.CHASE:
			anim_player.speed_scale = 1.35
			if anim_player.has_animation("Walk"):
				anim_player.play("Walk", 0.2)
		State.ATTACK:
			anim_player.speed_scale = 1.0
			has_dealt_damage_this_attack = false
			if anim_player.has_animation("Attack"):
				anim_player.play("Attack", 0.15)
		State.HIT:
			anim_player.speed_scale = 1.0
			if anim_player.has_animation("Hit"):
				anim_player.play("Hit", 0.1)
		State.DEAD:
			anim_player.speed_scale = 1.0
			if anim_player.has_animation("Die"):
				anim_player.play("Die", 0.1)
			if label_title:
				label_title.text = "✝ " + golem_title + " (Defeated)"
				label_title.modulate = Color(0.6, 0.6, 0.6)
			if label_hp:
				label_hp.text = "0 / " + str(int(max_health)) + " HP"
				label_hp.modulate = Color(0.5, 0.5, 0.5)

func _rotate_towards(target_dir: Vector3, delta: float) -> void:
	if target_dir.length_squared() < 0.001:
		return
	var target_yaw = atan2(-target_dir.x, -target_dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed * delta)

func _pick_patrol_target() -> void:
	var angle = randf() * TAU
	var dist = randf_range(3.0, patrol_range)
	patrol_target = spawn_point + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

func _is_player_alive() -> bool:
	if not is_instance_valid(player):
		return false
	if "is_dead" in player and player.is_dead:
		return false
	if "current_health" in player and player.current_health <= 0.0:
		return false
	return true

func _execute_ground_slam() -> void:
	# Efek hantam tanah: cek jarak ke player
	if _is_player_alive():
		var d = global_position.distance_to(player.global_position)
		if d <= attack_range * 1.25:
			# Player terkena hantaman golem!
			var knock_dir = (player.global_position - global_position).normalized()
			knock_dir.y = 0.4
			if "velocity" in player:
				player.velocity += knock_dir * 12.0
			if player.has_method("take_damage"):
				player.take_damage(attack_damage)
			print("[Golem %s] Menghantam player dengan damage %d!" % [golem_title, attack_damage])

func take_damage(amount: float) -> void:
	if current_state == State.DEAD:
		return
		
	current_health = max(0.0, current_health - amount)
	_update_hp_display()
	
	if current_health <= 0.0:
		_set_state(State.DEAD)
	else:
		_set_state(State.HIT)
