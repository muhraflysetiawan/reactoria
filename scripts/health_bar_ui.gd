extends Control
class_name PlayerHealthUI

## UI Health Point Controller dengan Animasi Bar Mengecil, Trailing Ghost Bar, dan Shake Efek
## Dirancang khusus untuk asset Reactoria: Health Background, HP Bar, & Heart Icon

@export_group("Health Stats")
@export var max_health: float = 100.0
@export var current_health: float = 100.0

@export_group("Animation Durations")
@export var hp_bar_tween_duration: float = 0.28
@export var ghost_bar_delay: float = 0.16
@export var ghost_bar_duration: float = 0.48

@export_group("Shake Settings")
@export var shake_duration: float = 0.35
@export var max_shake_offset: float = 9.0
@export var heart_punch_scale: float = 1.32

# Node References
@onready var background_shake: Control = $ShakeContainer/BackgroundShake
@onready var health_background: TextureRect = $ShakeContainer/BackgroundShake/HealthBackground
@onready var ghost_bar: TextureRect = $ShakeContainer/BackgroundShake/GhostBar
@onready var hp_bar: TextureRect = $ShakeContainer/BackgroundShake/HPBar
@onready var hp_label: Label = $ShakeContainer/BackgroundShake/HPLabel
@onready var heart_shake: Control = $ShakeContainer/HeartShake
@onready var heart_icon: TextureRect = $ShakeContainer/HeartShake/HeartIcon

# Internal States
var displayed_hp_ratio: float = 1.0
var displayed_ghost_ratio: float = 1.0
var displayed_hp_number: float = 100.0

var hp_tween: Tween = null
var ghost_tween: Tween = null
var text_tween: Tween = null
var heart_tween: Tween = null

# Shake Variables
var current_shake_time: float = 0.0
var current_shake_trauma: float = 0.0
var heart_base_pos: Vector2 = Vector2.ZERO

# Materials for shaders
var hp_bar_mat: ShaderMaterial = null
var ghost_bar_mat: ShaderMaterial = null

func _ready() -> void:
	# Pastikan UI tidak memblokir input mouse sama sekali
	_set_ignore_mouse_filter(self)
	
	# Simpan posisi awal Heart Icon
	if heart_shake:
		heart_base_pos = heart_shake.position
		# Set pivot di tengah agar scale punch membesar dari titik tengah icon
		heart_shake.pivot_offset = heart_shake.size * 0.5
	
	# Pastikan bar dan label terlihat (scene menyimpan visible = false)
	if hp_bar:
		hp_bar.visible = true
	if hp_label:
		hp_label.visible = true
	
	# Inisialisasi Shader Material untuk HP Bar & Ghost Bar
	_setup_materials()
	
	# Sambungkan otomatis ke Player jika ada di scene tree
	_connect_to_player()
	
	# Set tampilan awal
	set_health(current_health, max_health, false)

func _set_ignore_mouse_filter(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_ignore_mouse_filter(child)

func _setup_materials() -> void:
	# Duplicate material agar instansiasi independen
	if hp_bar and hp_bar.material is ShaderMaterial:
		hp_bar_mat = hp_bar.material.duplicate()
		hp_bar.material = hp_bar_mat
	elif hp_bar:
		var shader_res = load("res://shaders/slanted_hp_bar.gdshader")
		if shader_res:
			hp_bar_mat = ShaderMaterial.new()
			hp_bar_mat.shader = shader_res
			hp_bar.material = hp_bar_mat
			
	if ghost_bar and ghost_bar.material is ShaderMaterial:
		ghost_bar_mat = ghost_bar.material.duplicate()
		ghost_bar.material = ghost_bar_mat
	elif ghost_bar:
		var shader_res = load("res://shaders/slanted_hp_bar.gdshader")
		if shader_res:
			ghost_bar_mat = ShaderMaterial.new()
			ghost_bar_mat.shader = shader_res
			# Berikan tint kuning-oranye untuk trailing damage lag bar
			ghost_bar_mat.set_shader_parameter("tint_color", Color(1.0, 0.88, 0.45, 0.95))
			ghost_bar.material = ghost_bar_mat

func _connect_to_player() -> void:
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_signal("health_changed") and not player.health_changed.is_connected(_on_player_health_changed):
			player.health_changed.connect(_on_player_health_changed)
		if player.has_signal("damaged") and not player.damaged.is_connected(_on_player_damaged):
			player.damaged.connect(_on_player_damaged)
		# Update nilai awal dari player
		if "current_health" in player and "max_health" in player:
			set_health(player.current_health, player.max_health, false)

func _process(delta: float) -> void:
	# Proses getaran (shake) pada Health Background & Heart Icon
	if current_shake_time > 0.0:
		current_shake_time = max(current_shake_time - delta, 0.0)
		var progress = current_shake_time / shake_duration
		# Damping kurva non-linear agar getaran terasa tajam di awal lalu melandai
		var intensity = pow(progress, 1.4) * max_shake_offset * current_shake_trauma
		
		# Getaran acak pada Background
		var bg_offset = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * intensity
		background_shake.position = bg_offset
		
		# Getaran acak independen dengan amplitudo sedikit lebih besar pada Heart Icon
		var heart_offset = Vector2(
			randf_range(-1.2, 1.2),
			randf_range(-1.2, 1.2)
		) * (intensity * 1.25)
		heart_shake.position = heart_base_pos + heart_offset
	else:
		if background_shake.position != Vector2.ZERO:
			background_shake.position = Vector2.ZERO
		if heart_shake.position != heart_base_pos:
			heart_shake.position = heart_base_pos
			
	# Update heartbeat santai saat HP kritis (< 30%)
	_update_low_hp_pulsation(delta)

## Memicu getaran pada Health Background & Heart Icon
func trigger_shake(damage_amount: float = 20.0) -> void:
	current_shake_time = shake_duration
	current_shake_trauma = clamp(damage_amount / 20.0, 0.5, 1.5)
	
	# Heart Icon Scale Punch & Red Flash Animation
	if heart_shake and heart_icon:
		if heart_tween and heart_tween.is_valid():
			heart_tween.kill()
		heart_tween = create_tween().set_parallel(true)
		
		# Scale membesar mendadak lalu membal (Elastic bounce)
		heart_shake.scale = Vector2(heart_punch_scale, heart_punch_scale)
		heart_tween.tween_property(heart_shake, "scale", Vector2.ONE, 0.4) \
			.set_trans(Tween.TRANS_ELASTIC) \
			.set_ease(Tween.EASE_OUT)
			
		# Flash warna merah terang pada icon hati
		heart_icon.modulate = Color(1.8, 0.4, 0.4, 1.0)
		heart_tween.tween_property(heart_icon, "modulate", Color.WHITE, 0.28) \
			.set_trans(Tween.TRANS_QUAD) \
			.set_ease(Tween.EASE_OUT)

## Mengatur nilai HP saat ini dan menjalankan animasi perubahan
func set_health(new_health: float, new_max_health: float = -1.0, animate: bool = true) -> void:
	if new_max_health > 0.0:
		max_health = new_max_health
	
	var prev_health = current_health
	current_health = clamp(new_health, 0.0, max_health)
	var target_ratio = current_health / max_health if max_health > 0.0 else 0.0
	var is_damage = current_health < prev_health
	var damage_amount = prev_health - current_health
	
	if not animate:
		# Update langsung tanpa transisi
		displayed_hp_ratio = target_ratio
		displayed_ghost_ratio = target_ratio
		displayed_hp_number = current_health
		_set_hp_fill(target_ratio)
		_set_ghost_fill(target_ratio)
		_set_hp_flash(0.0)
		_update_hp_text(current_health)
		return
		
	# 1. Animasi HP Bar Utama Mengecil
	if hp_tween and hp_tween.is_valid():
		hp_tween.kill()
	hp_tween = create_tween().set_parallel(true)
	hp_tween.tween_method(_set_hp_fill, displayed_hp_ratio, target_ratio, hp_bar_tween_duration) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
		
	if is_damage:
		# Flash putih/merah terang pada bar saat terkena hit
		_set_hp_flash(0.85)
		hp_tween.tween_method(_set_hp_flash, 0.85, 0.0, 0.22) \
			.set_trans(Tween.TRANS_QUAD) \
			.set_ease(Tween.EASE_OUT)
			
		# Trigger getaran pada Background & Heart Icon
		trigger_shake(damage_amount)
	else:
		_set_hp_flash(0.0)
		
	# 2. Animasi Trailing Ghost Bar (Damage Catch-Up Bar)
	if ghost_tween and ghost_tween.is_valid():
		ghost_tween.kill()
	ghost_tween = create_tween()
	
	if is_damage:
		# Jeda sesaat sebelum ghost bar menyusut mengejar HP Bar utama
		ghost_tween.tween_interval(ghost_bar_delay)
		ghost_tween.tween_method(_set_ghost_fill, displayed_ghost_ratio, target_ratio, ghost_bar_duration) \
			.set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
	else:
		# Jika heal / respawn, ghost bar langsung mengikuti
		ghost_tween.tween_method(_set_ghost_fill, displayed_ghost_ratio, target_ratio, 0.15)
		
	# 3. Animasi Angka Teks HP
	if text_tween and text_tween.is_valid():
		text_tween.kill()
	text_tween = create_tween()
	text_tween.tween_method(_update_text_tween_step, displayed_hp_number, current_health, hp_bar_tween_duration)

func _set_hp_fill(val: float) -> void:
	displayed_hp_ratio = val
	if hp_bar_mat:
		hp_bar_mat.set_shader_parameter("fill_amount", val)

func _set_ghost_fill(val: float) -> void:
	displayed_ghost_ratio = val
	if ghost_bar_mat:
		ghost_bar_mat.set_shader_parameter("fill_amount", val)

func _set_hp_flash(val: float) -> void:
	if hp_bar_mat:
		hp_bar_mat.set_shader_parameter("flash_amount", val)

func _update_text_tween_step(val: float) -> void:
	displayed_hp_number = val
	_update_hp_text(val)

func _update_hp_text(val: float) -> void:
	if not hp_label:
		return
	hp_label.text = "%d / %d" % [roundi(val), roundi(max_health)]
	
	var pct = (val / max_health) * 100.0 if max_health > 0.0 else 0.0
	if pct > 50.0:
		hp_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	elif pct > 25.0:
		hp_label.modulate = Color(1.0, 0.85, 0.3, 1.0)
	else:
		hp_label.modulate = Color(1.0, 0.35, 0.35, 1.0)

var low_hp_time: float = 0.0
func _update_low_hp_pulsation(delta: float) -> void:
	var pct = current_health / max_health if max_health > 0.0 else 0.0
	if pct <= 0.30 and current_health > 0.0:
		low_hp_time += delta * 6.5
		var pulse = (sin(low_hp_time) * 0.5 + 0.5)
		if hp_bar_mat:
			hp_bar_mat.set_shader_parameter("pulse_intensity", pulse)
		if current_shake_time <= 0.0 and heart_shake:
			# Denyut halus jantung saat darah merah kritis
			heart_shake.scale = Vector2.ONE * (1.0 + pulse * 0.12)
	else:
		if hp_bar_mat:
			hp_bar_mat.set_shader_parameter("pulse_intensity", 0.0)
		if current_shake_time <= 0.0 and heart_shake and heart_shake.scale != Vector2.ONE:
			heart_shake.scale = Vector2.ONE

# Callback sinyal player
func _on_player_health_changed(curr: float, max_val: float) -> void:
	set_health(curr, max_val, true)

func _on_player_damaged(_amount: float) -> void:
	# Dilayani otomatis oleh _on_player_health_changed
	pass
