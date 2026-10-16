extends Area3D
class_name ArrowProjectile

## Projectile Arrow untuk Senjata Bow di Reactoria
## Menangani lintasan terbang, efek partikel meluncur (Trail VFX), tabrakan musuh/lingkungan, dan audio hook.

@export var speed: float = 42.0
@export var damage: float = 45.0
@export var knockback_force: float = 8.0
@export var max_lifetime: float = 4.0
@export var trail_color: Color = Color(0.85, 0.45, 1.0)

var direction: Vector3 = Vector3.FORWARD
var _alive_timer: float = 0.0
var _has_hit: bool = false

# SFX Streams (Akan aktif otomatis saat file audio telah diisi)
var fly_sfx: AudioStream = null
var hit_sfx: AudioStream = null

@onready var trail_particles: CPUParticles3D = get_node_or_null("TrailParticles")
@onready var fly_audio: AudioStreamPlayer3D = get_node_or_null("FlyAudio")
@onready var hit_audio: AudioStreamPlayer3D = get_node_or_null("HitAudio")

func _ready() -> void:
	top_level = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	if trail_particles:
		trail_particles.emitting = true
		
	if fly_sfx and fly_audio:
		fly_audio.stream = fly_sfx
		fly_audio.play()

## Inisialisasi posisi tembak, arah laju panah, dan parameter damage
func setup(spawn_pos: Vector3, shoot_dir: Vector3, dmg: float = 45.0, knockback: float = 8.0, col: Color = Color(0.85, 0.45, 1.0), sfx_fly: AudioStream = null, sfx_hit: AudioStream = null) -> void:
	global_position = spawn_pos
	direction = shoot_dir.normalized()
	damage = dmg
	knockback_force = knockback
	trail_color = col
	fly_sfx = sfx_fly
	hit_sfx = sfx_hit
	
	if not direction.is_zero_approx():
		var up_vec = Vector3.UP
		if abs(direction.dot(Vector3.UP)) > 0.99:
			up_vec = Vector3.FORWARD
		look_at(global_position + direction, up_vec)

func _physics_process(delta: float) -> void:
	if _has_hit:
		return
		
	_alive_timer += delta
	if _alive_timer >= max_lifetime:
		queue_free()
		return
		
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	_handle_collision(body)

func _on_area_entered(area: Area3D) -> void:
	_handle_collision(area)

func _handle_collision(target: Node) -> void:
	if _has_hit:
		return
	if target.is_in_group("player") or target is ArrowProjectile:
		return
		
	_has_hit = true
	
	var enemy = target
	if not enemy.has_method("take_damage") and enemy.get_parent() and enemy.get_parent().has_method("take_damage"):
		enemy = enemy.get_parent()
		
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		if "velocity" in enemy:
			var push = direction
			push.y = 0.25
			enemy.velocity += push.normalized() * knockback_force
			
	_spawn_impact_particles(global_position)
	
	if hit_sfx and hit_audio:
		hit_audio.stream = hit_sfx
		hit_audio.play()
		hide()
		set_physics_process(false)
		hit_audio.finished.connect(queue_free)
	else:
		queue_free()

func _spawn_impact_particles(pos: Vector3) -> void:
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
	spark.amount = 16
	spark.spread = 180.0
	spark.gravity = Vector3(0, -5.0, 0)
	spark.initial_velocity_min = 3.0
	spark.initial_velocity_max = 6.0
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = trail_color
	mat.emission_enabled = true
	mat.emission = trail_color
	mat.emission_energy_multiplier = 3.0
	
	var sphere = SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	sphere.material = mat
	spark.mesh = sphere
	
	get_tree().create_timer(0.4).timeout.connect(spark.queue_free)
