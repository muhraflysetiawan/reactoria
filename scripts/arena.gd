extends Node3D
class_name Arena

## Script pengelola Arena 3D
## Mengatur mesh arena dan membuat collision (bentuk pijakan) presisi sesuai model 3D (Trimesh / ConcavePolygonShape3D)

@export_group("Collision Settings")
@export var auto_generate_collisions: bool = true
@export var enable_ground_collision: bool = true
@export var enable_obstacle_collision: bool = true

var generated_collision_count: int = 0

func _ready() -> void:
	if auto_generate_collisions:
		setup_collisions()

## saya akan lawan
## Fungsi untuk membuat collision shape secara otomatis untuk setiap mesh
func setup_collisions() -> void:
	generated_collision_count = 0
	_process_node_recursive(self)
	print("[Arena] Berhasil membuat %d collision shapes presisi untuk arena!" % generated_collision_count)

func _process_node_recursive(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		_configure_mesh_collision(node)
	
	for child in node.get_children():
		# Jangan proses StaticBody yang sudah kita buat
		if child is StaticBody3D:
			continue
		_process_node_recursive(child)

func _configure_mesh_collision(mesh_node: MeshInstance3D) -> void:
	var node_name: String = mesh_node.name.to_lower()
	
	# Lewati objek yang tidak boleh memiliki tabrakan (awan di langit, rumput dekoratif, air)
	if _is_non_collidable(node_name):
		return
	
	# Periksa apakah node sudah memiliki StaticBody3D sebagai anak
	for child in mesh_node.get_children():
		if child is StaticBody3D:
			return
			
	var is_ground: bool = _is_ground_mesh(node_name)
	var is_obstacle: bool = _is_obstacle_mesh(node_name)
	
	if is_ground and not enable_ground_collision:
		return
	if is_obstacle and not enable_obstacle_collision:
		return
		
	# Buat Trimesh (ConcavePolygonShape3D) collision agar bentuk pijakan 100% presisi sesuai lekukan mesh
	mesh_node.create_trimesh_collision()
	generated_collision_count += 1

	var body = mesh_node.get_node_or_null(str(mesh_node.name) + "_col")
	if not body:
		for child in mesh_node.get_children():
			if child is StaticBody3D:
				body = child
				break
	if body:
		var surface = "grass"
		if "rock" in node_name or "cliff" in node_name:
			surface = "rock"
		elif "log" in node_name or "wood" in node_name or "bridge" in node_name:
			surface = "log"
		body.set_meta("surface_type", surface)

func _is_non_collidable(name_lower: String) -> bool:
	if "cloud" in name_lower:
		return true
	if "grass" in name_lower:
		return true
	if "bush" in name_lower:
		return true
	if "water_surface" in name_lower:
		return true
	if "banner" in name_lower:
		return true
	return false

func _is_ground_mesh(name_lower: String) -> bool:
	return "terrain" in name_lower \
		or "path" in name_lower \
		or "bridge" in name_lower \
		or "vantage" in name_lower \
		or "cliff" in name_lower \
		or "river_bank" in name_lower \
		or "river_canyon" in name_lower \
		or "river_main" in name_lower \
		or "spawn" in name_lower

func _is_obstacle_mesh(name_lower: String) -> bool:
	return "house" in name_lower \
		or "tower" in name_lower \
		or "workshop" in name_lower \
		or "fence" in name_lower \
		or "rock" in name_lower \
		or "tree" in name_lower \
		or "crate" in name_lower \
		or "barrel" in name_lower \
		or "tent" in name_lower \
		or "log" in name_lower \
		or "cart" in name_lower \
		or "ruin" in name_lower \
		or "campfire" in name_lower
