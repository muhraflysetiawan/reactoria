extends Node3D
class_name SwordWeapon

## Controller Pengelola Senjata di Reactoria
## Menangani Efek Tebasan (Slash Trail VFX), Efek Suara (Audio Swing/Hit),
## dan Efek Partikel (Aura Particles) secara dinamis untuk semua senjata.

@export_group("Weapon Identification")
@export var weapon_id: String = "h2o_sword"

@export_group("Slash Trail Settings")
@export var trail_color: Color = Color(0.2, 0.85, 1.0)
@export var trail_duration: float = 0.22
@export var use_custom_trail_points: bool = false
@export var custom_trail_base: Vector3 = Vector3.ZERO
@export var custom_trail_tip: Vector3 = Vector3.ZERO

@export_group("Particle Settings")
@export var particle_color: Color = Color(0.3, 0.9, 1.0)
@export var particle_amount: int = 16

# Referensi Node (bisa ada di scene atau dibuat dinamis)
var sword_mesh: MeshInstance3D = null
var aura_particles: CPUParticles3D = null
var audio_swing: AudioStreamPlayer3D = null
var audio_hit: AudioStreamPlayer3D = null

# Data Suara Ayunan
var swing_sfx: Array[AudioStream] = []
var sound_speed_multipliers: Array[float] = []

# Status Animasi Tebasan & Trail
var is_slashing: bool = false
var slash_timer: float = 0.0
var trail_mesh_inst: MeshInstance3D = null
var trail_points: Array[Dictionary] = [] # Array dari {base: Vector3, tip: Vector3, time: float}
var trail_material: StandardMaterial3D = null

var _initialized: bool = false


func _ready() -> void:
	# Cari node di scene tree jika sudah ada
	sword_mesh = _find_mesh(self)
	aura_particles = get_node_or_null("AuraParticles") as CPUParticles3D
	audio_swing = get_node_or_null("AudioSwing") as AudioStreamPlayer3D
	audio_hit = get_node_or_null("AudioHit") as AudioStreamPlayer3D

	# Jika belum diinisialisasi dari luar, ambil data dari GameData
	if not _initialized:
		var config := {}
		var gd = get_node_or_null("/root/GameData")
		if gd and gd.has_method("get_weapon_data"):
			config = gd.get_weapon_data()
		setup_weapon_effects(config)


## -------------------------------------------------------------
## 1. FUNGSI UTAMA: Konfigurasi Semua Efek dari Data Senjata
## -------------------------------------------------------------
func setup_weapon_effects(config: Dictionary = {}) -> void:
	_initialized = true
	
	if config.has("id"):
		weapon_id = config["id"]

	# 1. Konfigurasi Efek Tebasan (Slash Trail)
	var t_col: Color = config.get("trail_color", config.get("color", trail_color))
	var t_dur: float = config.get("trail_duration", trail_duration)
	var t_base = config.get("trail_base", null)
	var t_tip = config.get("trail_tip", null)
	setup_slash_effect(t_col, t_dur, t_base, t_tip)

	# 2. Konfigurasi Efek Partikel (Aura Glow)
	var p_col: Color = config.get("particle_color", config.get("color", particle_color))
	var p_amount: int = config.get("particle_amount", particle_amount)
	setup_particle_effect(p_col, p_amount)

	# 3. Konfigurasi Efek Suara Ayunan (Audio Swing)
	var sounds: Array = config.get("sounds", [])
	var speeds: Array = config.get("sound_speeds", [])
	setup_sound_effect(sounds, speeds)

	# 4. Material Khusus (Untuk Aqua Saber / Water Sword)
	if weapon_id == "h2o_sword":
		_setup_water_sword_materials()


## -------------------------------------------------------------
## 2. FUNGSI EFEK TEBASAN (Slash Trail VFX)
## -------------------------------------------------------------
func setup_slash_effect(col: Color, duration: float = 0.22, base_pos = null, tip_pos = null) -> void:
	trail_color = col
	trail_duration = duration

	if base_pos != null and tip_pos != null and base_pos is Vector3 and tip_pos is Vector3:
		custom_trail_base = base_pos
		custom_trail_tip = tip_pos
		use_custom_trail_points = true
	else:
		use_custom_trail_points = false

	if not trail_mesh_inst:
		trail_mesh_inst = get_node_or_null("SwordTrail") as MeshInstance3D

	if not trail_mesh_inst:
		trail_mesh_inst = MeshInstance3D.new()
		trail_mesh_inst.name = "SwordTrail"
		trail_mesh_inst.top_level = true
		add_child(trail_mesh_inst)

	if not trail_material:
		trail_material = StandardMaterial3D.new()
		trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		trail_material.vertex_color_use_as_albedo = true
		trail_material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
		trail_material.emission_enabled = true

	trail_material.emission = col
	trail_material.emission_energy_multiplier = 3.0
	trail_mesh_inst.material_override = trail_material


## -------------------------------------------------------------
## 3. FUNGSI EFEK SUARA (Audio Swing & Hit)
## -------------------------------------------------------------
func setup_sound_effect(sound_paths: Array = [], speeds: Array = []) -> void:
	if not audio_swing:
		audio_swing = get_node_or_null("AudioSwing") as AudioStreamPlayer3D

	if not audio_swing:
		audio_swing = AudioStreamPlayer3D.new()
		audio_swing.name = "AudioSwing"
		audio_swing.unit_size = 8.0
		audio_swing.max_distance = 40.0
		add_child(audio_swing)

	if not audio_hit:
		audio_hit = get_node_or_null("AudioHit") as AudioStreamPlayer3D
	if not audio_hit:
		audio_hit = AudioStreamPlayer3D.new()
		audio_hit.name = "AudioHit"
		audio_hit.max_distance = 50.0
		add_child(audio_hit)

	swing_sfx.clear()
	sound_speed_multipliers.clear()

	for sp in sound_paths:
		if sp is String and ResourceLoader.exists(sp):
			var stream = load(sp)
			if stream is AudioStream:
				swing_sfx.append(stream)
		elif sp is AudioStream:
			swing_sfx.append(sp)

	# Fallback ke audio swing bawaan jika belum ada
	if swing_sfx.is_empty():
		var fallback_paths := [
			"res://assets/audio/sword_swing1.wav",
			"res://assets/audio/sword_swing2.wav",
			"res://assets/audio/sword_swing3.wav",
		]
		for fp in fallback_paths:
			if ResourceLoader.exists(fp):
				swing_sfx.append(load(fp))

	for s in speeds:
		sound_speed_multipliers.append(float(s))


## -------------------------------------------------------------
## 4. FUNGSI EFEK PARTIKEL (Aura Particles)
## -------------------------------------------------------------
func setup_particle_effect(col: Color, amount: int = 16) -> void:
	particle_color = col
	particle_amount = amount

	if not aura_particles:
		aura_particles = get_node_or_null("AuraParticles") as CPUParticles3D

	if not aura_particles:
		aura_particles = CPUParticles3D.new()
		aura_particles.name = "AuraParticles"
		add_child(aura_particles)

	aura_particles.amount = particle_amount
	aura_particles.lifetime = 0.8
	aura_particles.direction = Vector3(0, 1, 0)
	aura_particles.spread = 35.0
	aura_particles.gravity = Vector3(0, 0.4, 0)
	aura_particles.initial_velocity_min = 0.2
	aura_particles.initial_velocity_max = 0.5
	aura_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX

	# Sesuaikan dimensi emisi partikel dengan ukuran senjata
	if sword_mesh:
		var aabb: AABB = sword_mesh.get_aabb()
		var longest: float = aabb.get_longest_axis_size()
		aura_particles.emission_box_extents = Vector3(longest * 0.12, longest * 0.45, longest * 0.12)
		aura_particles.position = aabb.get_center()
	else:
		aura_particles.emission_box_extents = Vector3(0.08, 0.5, 0.04)
		aura_particles.position = Vector3(0, 0.5, 0)

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 2.5

	var sphere = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	sphere.material = mat
	aura_particles.mesh = sphere

	var curve = Curve.new()
	curve.add_point(Vector2(0, 0.2))
	curve.add_point(Vector2(0.5, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	aura_particles.scale_amount_curve = curve

	var grad = Gradient.new()
	grad.set_color(0, Color(col.r, col.g, col.b, 0.9))
	grad.set_color(1, Color(col.r * 0.5, col.g * 0.5, col.b * 0.5, 0.0))
	aura_particles.color_ramp = grad

	aura_particles.emitting = true


## -------------------------------------------------------------
## 5. EKSEKUSI SERANGAN (Memicu Suara & Jejak Tebasan)
## -------------------------------------------------------------
func play_attack_effect(combo_index: int) -> void:
	# Putar audio ayunan
	if audio_swing and swing_sfx.size() > 0:
		var sfx_idx: int = (combo_index - 1) % swing_sfx.size()
		var speed: float = 1.0
		if sfx_idx < sound_speed_multipliers.size():
			speed = sound_speed_multipliers[sfx_idx]
		audio_swing.stream = swing_sfx[sfx_idx]
		audio_swing.pitch_scale = randf_range(0.95, 1.1) * speed
		audio_swing.play()

	# Aktifkan jejak tebasan pedang
	is_slashing = true
	var slash_durations := [0.7, 0.42, 0.48, 1.0]
	slash_timer = slash_durations[(combo_index - 1) % slash_durations.size()]


## -------------------------------------------------------------
## 6. PROSES FRAME: Perekaman Titik & Rendering Trail Tebasan
## -------------------------------------------------------------
func _process(delta: float) -> void:
	if is_slashing:
		slash_timer -= delta
		if slash_timer <= 0.0:
			is_slashing = false

	if is_slashing:
		var current_base: Vector3 = Vector3.ZERO
		var current_tip: Vector3 = Vector3.ZERO

		if use_custom_trail_points:
			current_base = to_global(custom_trail_base)
			current_tip = to_global(custom_trail_tip)
		elif sword_mesh:
			var aabb: AABB = sword_mesh.get_aabb()
			var center: Vector3 = aabb.get_center()
			var longest_index: int = aabb.get_longest_axis_index()
			var offset: Vector3 = Vector3.ZERO
			match longest_index:
				Vector3.AXIS_X:
					offset = Vector3(aabb.size.x * 0.45, 0, 0)
				Vector3.AXIS_Y:
					offset = Vector3(0, aabb.size.y * 0.45, 0)
				Vector3.AXIS_Z:
					offset = Vector3(0, 0, aabb.size.z * 0.45)
			current_base = sword_mesh.to_global(center - offset)
			current_tip = sword_mesh.to_global(center + offset)
		else:
			current_base = to_global(Vector3.ZERO)
			current_tip = to_global(Vector3(0, 1.0, 0))

		trail_points.push_front({
			"base": current_base,
			"tip": current_tip,
			"time": trail_duration
		})

	# Hapus titik yang sudah kedaluwarsa
	var i = 0
	while i < trail_points.size():
		trail_points[i]["time"] -= delta
		if trail_points[i]["time"] <= 0.0:
			trail_points.remove_at(i)
		else:
			i += 1

	_render_trail()


func _render_trail() -> void:
	if not trail_mesh_inst:
		return
	if trail_points.size() < 2:
		trail_mesh_inst.mesh = null
		return

	var imm_mesh = ImmediateMesh.new()
	imm_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	var total = trail_points.size()
	for idx in range(total):
		var p = trail_points[idx]
		var life_ratio = clamp(p["time"] / trail_duration, 0.0, 1.0)
		var t = float(idx) / float(total - 1)

		var alpha = sin(life_ratio * PI * 0.5) * (1.0 - t * 0.7)
		var vert_color = Color(trail_color.r, trail_color.g, trail_color.b, alpha * 0.85)

		imm_mesh.surface_set_color(vert_color)
		imm_mesh.surface_set_uv(Vector2(t, 0.0))
		imm_mesh.surface_add_vertex(p["base"])

		imm_mesh.surface_set_color(vert_color)
		imm_mesh.surface_set_uv(Vector2(t, 1.0))
		imm_mesh.surface_add_vertex(p["tip"])

	imm_mesh.surface_end()
	trail_mesh_inst.mesh = imm_mesh


## Helper pencarian mesh dalam hierarki node
func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and node.name != "SwordTrail":
		return node
	for child in node.get_children():
		var found = _find_mesh(child)
		if found:
			return found
	return null


## Material bawaan khusus Aqua Saber (H2O)
func _setup_water_sword_materials() -> void:
	if not sword_mesh or not sword_mesh.mesh:
		return

	# Material 0: Blade - Silvery cyan sharp blade with glowing edge
	var mat_blade = StandardMaterial3D.new()
	mat_blade.albedo_color = Color(0.85, 0.95, 1.0)
	mat_blade.metallic = 0.92
	mat_blade.roughness = 0.18
	mat_blade.emission_enabled = true
	mat_blade.emission = Color(0.12, 0.45, 0.85)
	mat_blade.emission_energy_multiplier = 0.8
	sword_mesh.set_surface_override_material(0, mat_blade)

	# Material 1: Wave Trim - Glowing cyan wave patterns
	var mat_trim = StandardMaterial3D.new()
	mat_trim.albedo_color = Color(0.1, 0.75, 1.0)
	mat_trim.metallic = 0.6
	mat_trim.roughness = 0.25
	mat_trim.emission_enabled = true
	mat_trim.emission = Color(0.2, 0.85, 1.0)
	mat_trim.emission_energy_multiplier = 1.8
	sword_mesh.set_surface_override_material(1, mat_trim)

	# Material 2: Gem - Brilliant glowing sapphire
	var mat_gem = StandardMaterial3D.new()
	mat_gem.albedo_color = Color(0.05, 0.5, 1.0)
	mat_gem.metallic = 0.3
	mat_gem.roughness = 0.1
	mat_gem.emission_enabled = true
	mat_gem.emission = Color(0.1, 0.9, 1.0)
	mat_gem.emission_energy_multiplier = 2.5
	sword_mesh.set_surface_override_material(2, mat_gem)

	# Material 3 & 6: Dark Guard
	var mat_guard = StandardMaterial3D.new()
	mat_guard.albedo_color = Color(0.08, 0.15, 0.25)
	mat_guard.metallic = 0.85
	mat_guard.roughness = 0.35
	sword_mesh.set_surface_override_material(3, mat_guard)
	sword_mesh.set_surface_override_material(6, mat_guard)

	# Material 4: Grip
	var mat_grip = StandardMaterial3D.new()
	mat_grip.albedo_color = Color(0.04, 0.08, 0.14)
	mat_grip.metallic = 0.1
	mat_grip.roughness = 0.8
	sword_mesh.set_surface_override_material(4, mat_grip)

	# Material 5: Strap
	var mat_strap = StandardMaterial3D.new()
	mat_strap.albedo_color = Color(0.1, 0.6, 0.95)
	mat_strap.metallic = 0.2
	mat_strap.roughness = 0.5
	sword_mesh.set_surface_override_material(5, mat_strap)
