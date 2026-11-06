extends CharacterBody3D
class_name GolemEnemy

## Script AI Musuh Golem Berbasis Fisik
## Mendukung 5 Varian Elemen: Earth, Ice, Lava, Lightning, Wind
## Dilengkapi sistem State Machine, Navigasi Fisik, Animasi Realistis, Serangan Hantam Tanah, dan Health System

enum Element {EARTH, ICE, LAVA, LIGHTNING, WIND}
enum State {IDLE, PATROL, CHASE, ATTACK, HIT, DEAD}

const SPECIAL_ATTACK_SCENES = {
	Element.WIND: preload("res://assets/3dassets/golem/wind/shinra_tensei.glb"),
	Element.EARTH: preload("res://assets/3dassets/golem/earth/doton_doryuheki.glb"),
	Element.ICE: preload("res://assets/3dassets/golem/ice/ice-spike.glb")
}

@export_group("Golem Identity")
@export var element_type: Element = Element.EARTH
@export var golem_title: String = "Stone Colossus"
@export var element_color: Color = Color(0.4, 0.85, 0.4)

@export_group("Combat Stats")
@export var max_health: float = 250.0
@export var attack_damage: float = 30.0
@export var attack_cooldown: float = 0.5
@export var attack_range: float = 1
@export var detection_range: float = 10.0
@export var patrol_range: float = 5.0

@export_group("Special Attack")
@export var special_attack_scene: PackedScene = null
@export var special_attack_cooldown: float = 7.0
@export var special_attack_damage: float = 48.0
@export var special_attack_range: float = 4.5

@export_group("Movement")
@export var walk_speed: float = 2.4
@export var chase_speed: float = 3
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
var special_attack_timer: float = 0.0
var current_attack_variant: String = ""
var current_attack_duration: float = 1.0
var current_attack_hit_time: float = 0.35
var has_dealt_damage_this_attack: bool = false
var label_title: Label3D = null
var label_hp: Label3D = null
var model_node: Node3D = null
var collision_shape: CollisionShape3D = null

func _ready() -> void:
	add_to_group("enemies")
	spawn_point = global_position
	current_health = max_health
	
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(50.0)
	floor_stop_on_slope = true
	
	model_node = get_node_or_null("Model")
	collision_shape = get_node_or_null("CollisionShape3D")
	
	_find_anim_player(self)
	_setup_overhead_ui()
	_apply_elemental_identity()
	
	if not special_attack_scene and SPECIAL_ATTACK_SCENES.has(element_type):
		special_attack_scene = SPECIAL_ATTACK_SCENES[element_type]
	
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
			element_color = Color(0.45, 0.30, 0.16)
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
	var head_y: float = 2.65
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var cap = collision_shape.shape as CapsuleShape3D
		head_y = collision_shape.position.y + (cap.height * collision_shape.scale.y) * 0.5 + 0.35
	elif model_node:
		head_y = 1.65 * abs(model_node.scale.y) + 0.35

	# Nama Golem Billboard di atas kepala
	label_title = Label3D.new()
	label_title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_title.position = Vector3(0, head_y + 0.25, 0)
	label_title.font_size = 28
	label_title.outline_size = 6
	label_title.outline_modulate = Color.BLACK
	label_title.text = golem_title
	label_title.modulate = element_color
	add_child(label_title)
	
	# Bar HP Text
	label_hp = Label3D.new()
	label_hp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_hp.position = Vector3(0, head_y, 0)
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
		if not is_on_floor() or velocity.length_squared() > 0.001:
			move_and_slide()
		if model_node:
			model_node.position.y = lerp(model_node.position.y, 0.35, 3.0 * delta)
		return

	if attack_timer > 0.0:
		attack_timer -= delta
	if special_attack_timer > 0.0:
		special_attack_timer -= delta
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
			elif attack_timer <= 0.0 and (dist_to_player <= attack_range or (dist_to_player <= special_attack_range and special_attack_timer <= 0.0)):
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

			# Frame hentakan serangan
			if state_timer >= current_attack_hit_time and not has_dealt_damage_this_attack:
				has_dealt_damage_this_attack = true
				if current_attack_variant == "Spesial Attack":
					_execute_special_attack()
				else:
					_execute_ground_slam()

			# Selesai animasi serangan
			if state_timer >= current_attack_duration:
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
			if anim_player.has_animation("Walking"):
				anim_player.play("Walking", 0.25)
		State.CHASE:
			anim_player.speed_scale = 1
			if anim_player.has_animation("Running"):
				anim_player.play("Running", 0.2)
		State.ATTACK:
			anim_player.speed_scale = 1.0
			has_dealt_damage_this_attack = false
			
			var can_special = special_attack_timer <= 0.0 and (special_attack_scene != null or anim_player.has_animation("Spesial Attack"))
			if can_special:
				current_attack_variant = "Spesial Attack"
				special_attack_timer = special_attack_cooldown
				current_attack_duration = 1.0
				current_attack_hit_time = 0.35
			else:
				var normals: Array[String] = []
				if anim_player.has_animation("Attack1"):
					normals.append("Attack1")
				if anim_player.has_animation("Attack2"):
					normals.append("Attack2")
				if anim_player.has_animation("Attack 1"):
					normals.append("Attack 1")
				if anim_player.has_animation("Attack 2"):
					normals.append("Attack 2")
				if normals.is_empty() and anim_player.has_animation("Attack"):
					normals.append("Attack")
				
				current_attack_variant = normals.pick_random() if not normals.is_empty() else "Attack1"
				current_attack_duration = 0.67
				current_attack_hit_time = 0.32
			
			if anim_player.has_animation(current_attack_variant):
				anim_player.play(current_attack_variant, 0.15)
			elif anim_player.has_animation("Attack"):
				anim_player.play("Attack", 0.15)
		State.HIT:
			anim_player.speed_scale = 1.0
			if anim_player.has_animation("Hit"):
				anim_player.play("Hit", 0.1)
		State.DEAD:
			remove_from_group("enemies")
			collision_layer = 0
			collision_mask = 1
			if anim_player:
				anim_player.speed_scale = 1.0
				if anim_player.has_animation("Dead"):
					anim_player.play("Dead", 0.1)
					await anim_player.animation_finished
				elif anim_player.has_animation("Die"):
					anim_player.play("Die", 0.1)
					await anim_player.animation_finished

			_spawn_death_particles()

			if model_node:
				model_node.hide()
			if label_title:
				label_title.hide()
			if label_hp:
				label_hp.hide()
			if collision_shape:
				collision_shape.set_deferred("disabled", true)
			set_physics_process(false)

func _spawn_death_particles() -> void:
	var parent_node = get_parent()
	if not parent_node:
		parent_node = self

	# Partikel cahaya elemen terbang ke atas
	var p = CPUParticles3D.new()
	parent_node.add_child(p)
	p.global_position = global_position + Vector3(0, 0.4, 0)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.2
	p.lifetime = 1.8
	p.amount = 32
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.8, 0.3, 0.8)
	p.direction = Vector3.UP
	p.spread = 25.0
	p.gravity = Vector3(0, 3.5, 0)
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.5
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = element_color
	mat.emission_enabled = true
	mat.emission = element_color
	mat.emission_energy_multiplier = 4.5
	
	var sphere = SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	sphere.material = mat
	p.mesh = sphere
	var tree = get_tree()
	if tree:
		tree.create_timer(2.0).timeout.connect(p.queue_free)
	else:
		p.queue_free()

	# Efek cahaya OmniLight3D mengikuti warna elemen
	var light = OmniLight3D.new()
	parent_node.add_child(light)
	light.global_position = global_position + Vector3(0, 0.8, 0)
	light.light_color = element_color
	light.light_energy = 4.0
	light.omni_range = 8.0
	
	if tree:
		var tw = tree.create_tween()
		tw.tween_property(light, "global_position:y", light.global_position.y + 3.0, 1.8)
		tw.parallel().tween_property(light, "light_energy", 0.0, 1.8)
		tw.tween_callback(light.queue_free)
	else:
		light.queue_free()

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

func _execute_special_attack() -> void:
	var parent_scene = get_parent()
	if not parent_scene:
		parent_scene = self
	
	match element_type:
		Element.WIND:
			_execute_shinra_tensei(parent_scene)
		Element.EARTH:
			_execute_doton_doryuheki(parent_scene)
		Element.ICE:
			_execute_ice_spike(parent_scene)
		_:
			_execute_fallback_special(parent_scene)

func _execute_shinra_tensei(parent_scene: Node) -> void:
	if special_attack_scene:
		var effect = special_attack_scene.instantiate()
		parent_scene.add_child(effect)
		var center_y: float = collision_shape.position.y if collision_shape else 1.2
		effect.global_position = global_position + Vector3(0, center_y, 0)
		effect.global_rotation = global_rotation
		var eff_scale = 1.8 if (collision_shape and collision_shape.position.y > 1.3) else 1.8
		effect.scale = Vector3(eff_scale, eff_scale, eff_scale)
		
		# Putar animasi model Shinra Tensei
		var eff_anim: AnimationPlayer = null
		if effect is AnimationPlayer:
			eff_anim = effect
		else:
			eff_anim = effect.find_child("AnimationPlayer", true, false) as AnimationPlayer
		
		if eff_anim:
			if eff_anim.has_animation("Spesial Attack"):
				eff_anim.play("Spesial Attack")
			elif not eff_anim.get_animation_list().is_empty():
				eff_anim.play(eff_anim.get_animation_list()[0])
		
		var tree = get_tree()
		if tree:
			tree.create_timer(1.1).timeout.connect(effect.queue_free)
		else:
			effect.queue_free()

	# Efek tolak Shinra Tensei (Almighty Push) ke player
	if _is_player_alive():
		var dist = global_position.distance_to(player.global_position)
		if dist <= 7.0:
			var push_dir = (player.global_position - global_position).normalized()
			if push_dir.length_squared() < 0.001:
				push_dir = -global_transform.basis.z
			push_dir.y = 0.35
			
			if "velocity" in player:
				player.velocity += push_dir.normalized() * 22.0
			if player.has_method("take_damage"):
				player.take_damage(special_attack_damage)
			print("[Golem %s] Shinra Tensei menghempaskan player! Damage %d" % [golem_title, special_attack_damage])

func _execute_doton_doryuheki(parent_scene: Node) -> void:
	var forward = -global_transform.basis.z.normalized()
	if special_attack_scene:
		var wall = special_attack_scene.instantiate()
		parent_scene.add_child(wall)
		var forward_dist = 2.8 if (collision_shape and collision_shape.position.y > 1.3) else 2.2
		wall.global_position = global_position + forward * forward_dist
		wall.global_rotation = global_rotation
		if collision_shape and collision_shape.position.y > 1.3:
			wall.scale = Vector3(1.3, 1.3, 1.3)
		
		# Tambahkan StaticBody3D collision agar menjadi rintangan fisik nyata
		var static_body = StaticBody3D.new()
		var col_shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(2.4, 2.2, 1.0)
		col_shape.shape = box
		col_shape.position = Vector3(0, 1.0, 0)
		static_body.add_child(col_shape)
		wall.add_child(static_body)
		
		# Putar animasi model Doton Doryuheki (dinding bangkit dari tanah)
		var wall_anim: AnimationPlayer = null
		if wall is AnimationPlayer:
			wall_anim = wall
		else:
			wall_anim = wall.find_child("AnimationPlayer", true, false) as AnimationPlayer
		
		if wall_anim:
			if wall_anim.has_animation("Doton_Doryuheki"):
				wall_anim.play("Doton_Doryuheki")
			elif not wall_anim.get_animation_list().is_empty():
				wall_anim.play(wall_anim.get_animation_list()[0])
		
		# Dinding bertahan selama ~2.5s lalu tenggelam mulus ke tanah
		var tree = get_tree()
		if tree:
			var tw = tree.create_tween()
			tw.tween_interval(2.5)
			tw.tween_property(wall, "position:y", wall.position.y - 2.8, 0.6)
			tw.tween_callback(wall.queue_free)
		else:
			wall.queue_free()

	# Efek lontaran tanah Doton Doryuheki ke player jika berada di dekat area kemunculan dinding
	if _is_player_alive():
		var forward_dist = 2.8 if (collision_shape and collision_shape.position.y > 1.3) else 2.2
		var wall_spawn_pos = global_position + forward * forward_dist
		var dist_to_wall = wall_spawn_pos.distance_to(player.global_position)
		if dist_to_wall <= 3.6:
			var launch_dir = (player.global_position - global_position).normalized()
			if launch_dir.length_squared() < 0.001:
				launch_dir = forward
			launch_dir.y = 0.8
			
			if "velocity" in player:
				player.velocity += launch_dir.normalized() * 16.0
			if player.has_method("take_damage"):
				player.take_damage(special_attack_damage)
			print("[Golem %s] Doton Doryuheki menghantam player dari tanah! Damage %d" % [golem_title, special_attack_damage])

func _execute_ice_spike(parent_scene: Node) -> void:
	if not special_attack_scene:
		_execute_fallback_special(parent_scene)
		return
	
	var spike_count: int = 5
	var spikes: Array[Node3D] = []
	var back = global_transform.basis.z.normalized()
	var right = global_transform.basis.x.normalized()
	
	# Phase 1: 5 Ice Spike muncul bersamaan secara vertikal di belakang golem
	for i in range(spike_count):
		var spike_root = Node3D.new()
		parent_scene.add_child(spike_root)
		
		var offset_x = (i - 2) * 1.15
		var offset_z = 2.0 + abs(i - 2) * 0.25
		spike_root.global_position = global_position + back * offset_z + right * offset_x + Vector3(0, 1.8, 0)
		
		# Putar model internal agar ujung lancip spike (+Y) searah dengan local -Z wrapper
		var model = special_attack_scene.instantiate()
		model.rotation.x = -PI * 0.5
		spike_root.add_child(model)
		
		# Orientasi awal berdiri tegak lurus secara vertikal
		spike_root.rotation.x = PI * 0.5
		
		var anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim and anim.has_animation("IceAppear"):
			anim.play("IceAppear")
		
		spikes.append(spike_root)
	
	var tree = get_tree()
	if not tree:
		return
	
	# Tunggu animasi kemunculan es selesai
	await tree.create_timer(0.65).timeout
	
	# Tentukan target bidikan ke arah tubuh player
	var target_pos: Vector3
	if _is_player_alive():
		target_pos = player.global_position + Vector3(0, 1.0, 0)
	else:
		target_pos = global_position - back * 15.0 + Vector3(0, 1.0, 0)
	
	# Phase 2: Berputar mengarah ke player serempak
	for spike in spikes:
		if not is_instance_valid(spike):
			continue
		var aim_dir = (target_pos - spike.global_position).normalized()
		if aim_dir.is_zero_approx():
			aim_dir = -back
		var look_t = Transform3D.IDENTITY.looking_at(aim_dir, Vector3.UP)
		var rot_tw = tree.create_tween()
		rot_tw.tween_property(spike, "quaternion", look_t.basis.get_rotation_quaternion(), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Tunggu proses bidik selesai
	await tree.create_timer(0.4).timeout
	
	# Phase 3: Menyerang maju bersamaan
	var spike_dmg = special_attack_damage * 0.35 # ~17 damage per spike
	for spike in spikes:
		if not is_instance_valid(spike):
			continue
		
		var shoot_dir = -spike.global_transform.basis.z.normalized()
		var fly_dist = 28.0
		var fly_target = spike.global_position + shoot_dir * fly_dist
		
		# Area3D untuk deteksi tabrakan
		var area = Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 1 | 2 # Environment & Player
		var col = CollisionShape3D.new()
		var sphere = SphereShape3D.new()
		sphere.radius = 0.65
		col.shape = sphere
		area.add_child(col)
		spike.add_child(area)
		
		var hit_callable = func(body: Node3D):
			if not is_instance_valid(spike):
				return
			if body.is_in_group("player") or body == player:
				if body.has_method("take_damage"):
					body.take_damage(spike_dmg)
				if "velocity" in body:
					body.velocity += shoot_dir * 8.0 + Vector3.UP * 2.5
				print("[Golem %s] Ice Spike mengenai player! Damage %d" % [golem_title, int(spike_dmg)])
			spike.queue_free()
		
		area.body_entered.connect(hit_callable)
		
		var fly_tw = tree.create_tween()
		fly_tw.tween_property(spike, "global_position", fly_target, 1.0)
		fly_tw.tween_callback(spike.queue_free)

func _execute_fallback_special(parent_scene: Node) -> void:
	if special_attack_scene:
		var eff = special_attack_scene.instantiate()
		parent_scene.add_child(eff)
		eff.global_position = global_position
		eff.global_rotation = global_rotation
		var anim = eff.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim and not anim.get_animation_list().is_empty():
			anim.play(anim.get_animation_list()[0])
		var tree = get_tree()
		if tree:
			tree.create_timer(1.5).timeout.connect(eff.queue_free)
	
	_execute_ground_slam()

func take_damage(amount: float) -> void:
	if current_state == State.DEAD:
		return
		
	current_health = max(0.0, current_health - amount)
	_update_hp_display()
	
	if current_health <= 0.0:
		_set_state(State.DEAD)
	else:
		_set_state(State.HIT)
