extends Node3D
class_name SwordWeapon

## Controller dan Visual Pedang Aqua Saber (Weapon_Sword2)
## Mengatur material glow, efek tebasan (Slash Arc VFX), partikel aura, dan audio

@onready var sword_mesh: MeshInstance3D = $SwordMesh
@onready var aura_particles: CPUParticles3D = $AuraParticles
@onready var slash_container: Node3D = $SlashContainer
@onready var audio_swing: AudioStreamPlayer3D = $AudioSwing
@onready var audio_hit: AudioStreamPlayer3D = $AudioHit

@export_group("Sound Speed")
@export var speed_thrust_slash: float = 2.0
@export var speed_sword_slash: float = 1.0
@export var speed_charged_slash: float = 1.0
@export var speed_charged_up_slash: float = 1.0

var swing_sfx: Array[AudioStream] = []
var hit_sfx: AudioStream = null

var is_slashing: bool = false
var slash_timer: float = 0.0

# Trail dynamic points & mesh
var trail_mesh_inst: MeshInstance3D = null
var trail_points: Array[Dictionary] = [] # Array of {base: Vector3, tip: Vector3, time: float}
var trail_duration: float = 0.22
var trail_material: StandardMaterial3D = null

func _ready() -> void:
	_setup_materials()
	_load_sounds()
	_setup_particles()
	_setup_trail_mesh()

func _setup_trail_mesh() -> void:
	trail_mesh_inst = MeshInstance3D.new()
	trail_mesh_inst.name = "SwordTrail"
	trail_mesh_inst.top_level = true # Rendernya di world space agar trail tertinggal di udara
	
	trail_material = StandardMaterial3D.new()
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	trail_material.vertex_color_use_as_albedo = true
	trail_material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	trail_material.emission_enabled = true
	trail_material.emission = Color(0.2, 0.85, 1.0)
	trail_material.emission_energy_multiplier = 3.0
	trail_mesh_inst.material_override = trail_material
	
	add_child(trail_mesh_inst)

func _setup_materials() -> void:
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

func _load_sounds() -> void:
	if ResourceLoader.exists("res://assets/audio/water_sword/thrust-slash.MP3"):
		swing_sfx.append(load("res://assets/audio/water_sword/thrust-slash.MP3"))
	if ResourceLoader.exists("res://assets/audio/water_sword/sword-slash.MP3"):
		swing_sfx.append(load("res://assets/audio/water_sword/sword-slash.MP3"))
	if ResourceLoader.exists("res://assets/audio/water_sword/charged-slash.MP3"):
		swing_sfx.append(load("res://assets/audio/water_sword/charged-slash.MP3"))
	if ResourceLoader.exists("res://assets/audio/water_sword/charged-up-sword-slash.MP3"):
		swing_sfx.append(load("res://assets/audio/water_sword/charged-up-sword-slash.MP3"))

func _setup_particles() -> void:
	if aura_particles:
		aura_particles.emitting = true

## Memicu efek tebasan & suara ayunan pedang
func play_attack_effect(combo_index: int) -> void:
	if audio_swing and swing_sfx.size() > 0:
		var sfx_idx = (combo_index - 1) % swing_sfx.size()
		var speeds = [speed_thrust_slash, speed_sword_slash, speed_charged_slash, speed_charged_up_slash]
		var sfx_speed = speeds[sfx_idx] if sfx_idx < speeds.size() else 1.0
		audio_swing.stream = swing_sfx[sfx_idx]
		audio_swing.pitch_scale = randf_range(0.95, 1.1) * sfx_speed
		audio_swing.play()
	
	# Aktifkan perekaman jejak tebasan pedang
	is_slashing = true
	var slash_durations = [0.6, 0.38, 0.48, 1]
	var dur_idx = (combo_index - 1) % slash_durations.size()
	slash_timer = slash_durations[dur_idx]

func _process(delta: float) -> void:
	if is_slashing:
		slash_timer -= delta
		if slash_timer <= 0.0:
			is_slashing = false

	# Posisi pangkal & ujung pedang di koordinat lokal pedang
	var local_base = Vector3(0.08, 0.15, 0.0)
	var local_tip = Vector3(-0.39, 1.02, 0.0)
	
	if is_slashing:
		var current_base = to_global(local_base)
		var current_tip = to_global(local_tip)
		trail_points.push_front({
			"base": current_base,
			"tip": current_tip,
			"time": trail_duration
		})

	# Update sisa masa hidup titik trail
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
		
		# Alpha memudar ke ekor trail dan saat waktu habis
		var alpha = sin(life_ratio * PI * 0.5) * (1.0 - t * 0.7)
		var vert_color = Color(0.3, 0.85, 1.0, alpha * 0.85)

		imm_mesh.surface_set_color(vert_color)
		imm_mesh.surface_set_uv(Vector2(t, 0.0))
		imm_mesh.surface_add_vertex(p["base"])

		imm_mesh.surface_set_color(vert_color)
		imm_mesh.surface_set_uv(Vector2(t, 1.0))
		imm_mesh.surface_add_vertex(p["tip"])

	imm_mesh.surface_end()
	trail_mesh_inst.mesh = imm_mesh
