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

func _ready() -> void:
	_setup_materials()
	_load_sounds()
	_setup_particles()

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
	# if ResourceLoader.exists("res://assets/audio/water_sword/hit.wav"):
	# 	hit_sfx = load("res://assets/audio/water_sword/hit.wav")

func _setup_particles() -> void:
	if aura_particles:
		aura_particles.emitting = true

## Memicu efek tebasan (Slash Arc Mesh VFX) & suara ayunan pedang
func play_attack_effect(combo_index: int) -> void:
	# Mainkan SFX ayunan
	if audio_swing and swing_sfx.size() > 0:
		var sfx_idx = (combo_index - 1) % swing_sfx.size()
		var speeds = [speed_thrust_slash, speed_sword_slash, speed_charged_slash, speed_charged_up_slash]
		var sfx_speed = speeds[sfx_idx] if sfx_idx < speeds.size() else 1.0
		audio_swing.stream = swing_sfx[sfx_idx]
		audio_swing.pitch_scale = randf_range(0.95, 1.1) * sfx_speed
		audio_swing.play()
	
	# Buat Slash Arc VFX dinamis
	_spawn_slash_arc(combo_index)


## Membuat mesh lengkungan tebasan bercahaya (Slash Arc Mesh)
func _spawn_slash_arc(combo_index: int) -> void:
	var arc_mesh_inst = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	
	# Buat busur tebasan berbentuk pita sabit berkilau
	var segments = 16
	var arc_radius_inner = 0.8
	var arc_radius_outer = 1.6
	var angle_start = - deg_to_rad(65.0)
	var angle_end = deg_to_rad(75.0)
	
	if combo_index == 2:
		# Tebasan vertikal diagonal
		angle_start = - deg_to_rad(80.0)
		angle_end = deg_to_rad(60.0)
	elif combo_index == 3:
		# Tebasan putaran 360 derajat penuh
		angle_start = - deg_to_rad(170.0)
		angle_end = deg_to_rad(170.0)
		arc_radius_outer = 1.9

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var angle = lerp(angle_start, angle_end, t)
		var width_factor = sin(t * PI) # Ujung sabit runcing, tengah tebal
		var r_in = arc_radius_inner + (1.0 - width_factor) * 0.2
		var r_out = arc_radius_outer * (0.6 + width_factor * 0.4)
		
		var cos_a = cos(angle)
		var sin_a = sin(angle)
		
		var p_in = Vector3(sin_a * r_in, 0.0, -cos_a * r_in)
		var p_out = Vector3(sin_a * r_out, 0.0, -cos_a * r_out)
		
		immediate_mesh.surface_set_uv(Vector2(t, 0.0))
		immediate_mesh.surface_add_vertex(p_in)
		immediate_mesh.surface_set_uv(Vector2(t, 1.0))
		immediate_mesh.surface_add_vertex(p_out)
	immediate_mesh.surface_end()
	
	arc_mesh_inst.mesh = immediate_mesh
	
	# Material sabit tebasan: Glowing Cyan / Aqua Gradient
	var slash_mat = StandardMaterial3D.new()
	slash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	slash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	slash_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	slash_mat.albedo_color = Color(0.4, 0.9, 1.0, 0.85)
	slash_mat.emission_enabled = true
	slash_mat.emission = Color(0.2, 0.85, 1.0)
	slash_mat.emission_energy_multiplier = 2.5
	arc_mesh_inst.material_override = slash_mat
	
	# Rotasi efek sesuai jenis kombo tebasan
	if combo_index == 1:
		arc_mesh_inst.rotation_degrees = Vector3(15.0, 0.0, 10.0)
		arc_mesh_inst.position = Vector3(-2.0, 0.6, 3.3)
	elif combo_index == 2:
		arc_mesh_inst.rotation_degrees = Vector3(45.0, 30.0, -50.0)
		arc_mesh_inst.position = Vector3(-2.0, 0.8, 0.2)
	elif combo_index == 3:
		arc_mesh_inst.rotation_degrees = Vector3(0.0, 0.0, 0.0)
		arc_mesh_inst.position = Vector3(-2.0, 0.5, 0.0)
	
	slash_container.add_child(arc_mesh_inst)
	
	# Animasi Tween untuk memudarkan dan memperbesar efek tebasan
	var tween = create_tween().set_parallel(true)
	tween.tween_property(slash_mat, "albedo_color:a", 0.0, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(arc_mesh_inst, "scale", Vector3(1.25, 1.25, 1.25), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(arc_mesh_inst.queue_free)
