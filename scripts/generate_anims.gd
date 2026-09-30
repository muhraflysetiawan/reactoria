@tool
extends SceneTree

func _init():
	var idle_anim: Animation = load("res://assets/3dassets/character/anim_idle.res")
	
	# Helper to get idle base rotation
	var base_rots = {}
	var base_poss = {}
	for t in range(idle_anim.get_track_count()):
		var path = String(idle_anim.track_get_path(t))
		var bname = path.split(":")[-1]
		if idle_anim.track_get_type(t) == Animation.TYPE_ROTATION_3D:
			base_rots[bname] = idle_anim.track_get_key_value(t, 0)
		elif idle_anim.track_get_type(t) == Animation.TYPE_POSITION_3D:
			base_poss[bname] = idle_anim.track_get_key_value(t, 0)

	print("Found base rots for: ", base_rots.keys())
	
	_create_attack_1(base_rots, base_poss)
	_create_attack_2(base_rots, base_poss)
	_create_attack_3(base_rots, base_poss)
	
	print("Attack animations generated successfully!")
	quit()

func _create_attack_1(base_rots: Dictionary, base_poss: Dictionary) -> void:
	var anim = Animation.new()
	anim.length = 0.42
	anim.step = 0.0166

	# Hips position
	var t_hip_p = anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(t_hip_p, "Armature/Skeleton3D:Hips")
	var hip_p = base_poss.get("Hips", Vector3(-0.578, 77.18, 9.7))
	anim.position_track_insert_key(t_hip_p, 0.0, hip_p)
	anim.position_track_insert_key(t_hip_p, 0.12, hip_p + Vector3(0, -2.0, -1.0))
	anim.position_track_insert_key(t_hip_p, 0.22, hip_p + Vector3(0, -3.0, 4.0)) # lunge forward
	anim.position_track_insert_key(t_hip_p, 0.42, hip_p)

	# Spine02 (Torso twist)
	var t_spine = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_spine, "Armature/Skeleton3D:Spine02")
	var sp_idle = base_rots.get("Spine02", Quaternion.IDENTITY)
	# Twist right for windup, twist left for slash
	var sp_windup = sp_idle * Quaternion(Vector3.UP, deg_to_rad(-35.0)) * Quaternion(Vector3.RIGHT, deg_to_rad(10.0))
	var sp_slash = sp_idle * Quaternion(Vector3.UP, deg_to_rad(40.0)) * Quaternion(Vector3.RIGHT, deg_to_rad(-15.0))
	var sp_follow = sp_idle * Quaternion(Vector3.UP, deg_to_rad(20.0))
	anim.rotation_track_insert_key(t_spine, 0.0, sp_idle)
	anim.rotation_track_insert_key(t_spine, 0.12, sp_windup)
	anim.rotation_track_insert_key(t_spine, 0.22, sp_slash)
	anim.rotation_track_insert_key(t_spine, 0.32, sp_follow)
	anim.rotation_track_insert_key(t_spine, 0.42, sp_idle)

	# RightShoulder
	var t_rsh = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_rsh, "Armature/Skeleton3D:RightShoulder")
	var rsh_idle = base_rots.get("RightShoulder", Quaternion.IDENTITY)
	anim.rotation_track_insert_key(t_rsh, 0.0, rsh_idle)
	anim.rotation_track_insert_key(t_rsh, 0.12, rsh_idle * Quaternion(Vector3.BACK, deg_to_rad(20.0)))
	anim.rotation_track_insert_key(t_rsh, 0.22, rsh_idle * Quaternion(Vector3.FORWARD, deg_to_rad(25.0)))
	anim.rotation_track_insert_key(t_rsh, 0.42, rsh_idle)

	# RightArm (Main swing)
	var t_rarm = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_rarm, "Armature/Skeleton3D:RightArm")
	var rarm_idle = base_rots.get("RightArm", Quaternion.IDENTITY)
	# Windup: raised back and right. Slash: swung down-left across
	var rarm_windup = rarm_idle * Quaternion(Vector3.RIGHT, deg_to_rad(-60.0)) * Quaternion(Vector3.UP, deg_to_rad(-45.0)) * Quaternion(Vector3.FORWARD, deg_to_rad(-30.0))
	var rarm_slash = rarm_idle * Quaternion(Vector3.RIGHT, deg_to_rad(70.0)) * Quaternion(Vector3.UP, deg_to_rad(65.0)) * Quaternion(Vector3.FORWARD, deg_to_rad(40.0))
	var rarm_follow = rarm_idle * Quaternion(Vector3.RIGHT, deg_to_rad(40.0)) * Quaternion(Vector3.UP, deg_to_rad(45.0))
	anim.rotation_track_insert_key(t_rarm, 0.0, rarm_idle)
	anim.rotation_track_insert_key(t_rarm, 0.12, rarm_windup)
	anim.rotation_track_insert_key(t_rarm, 0.22, rarm_slash)
	anim.rotation_track_insert_key(t_rarm, 0.32, rarm_follow)
	anim.rotation_track_insert_key(t_rarm, 0.42, rarm_idle)

	# RightForeArm
	var t_rfa = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_rfa, "Armature/Skeleton3D:RightForeArm")
	var rfa_idle = base_rots.get("RightForeArm", Quaternion.IDENTITY)
	var rfa_windup = rfa_idle * Quaternion(Vector3.RIGHT, deg_to_rad(60.0))
	var rfa_slash = rfa_idle * Quaternion(Vector3.RIGHT, deg_to_rad(15.0))
	anim.rotation_track_insert_key(t_rfa, 0.0, rfa_idle)
	anim.rotation_track_insert_key(t_rfa, 0.12, rfa_windup)
	anim.rotation_track_insert_key(t_rfa, 0.22, rfa_slash)
	anim.rotation_track_insert_key(t_rfa, 0.42, rfa_idle)

	# RightHand (Wrist snap)
	var t_rh = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_rh, "Armature/Skeleton3D:RightHand")
	var rh_idle = base_rots.get("RightHand", Quaternion.IDENTITY)
	var rh_windup = rh_idle * Quaternion(Vector3.FORWARD, deg_to_rad(-25.0))
	var rh_slash = rh_idle * Quaternion(Vector3.FORWARD, deg_to_rad(35.0))
	anim.rotation_track_insert_key(t_rh, 0.0, rh_idle)
	anim.rotation_track_insert_key(t_rh, 0.12, rh_windup)
	anim.rotation_track_insert_key(t_rh, 0.22, rh_slash)
	anim.rotation_track_insert_key(t_rh, 0.42, rh_idle)

	# LeftArm (Counter-balance)
	var t_larm = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_larm, "Armature/Skeleton3D:LeftArm")
	var larm_idle = base_rots.get("LeftArm", Quaternion.IDENTITY)
	anim.rotation_track_insert_key(t_larm, 0.0, larm_idle)
	anim.rotation_track_insert_key(t_larm, 0.12, larm_idle * Quaternion(Vector3.RIGHT, deg_to_rad(30.0)))
	anim.rotation_track_insert_key(t_larm, 0.22, larm_idle * Quaternion(Vector3.RIGHT, deg_to_rad(-40.0)))
	anim.rotation_track_insert_key(t_larm, 0.42, larm_idle)

	# Set cubic interpolation for fluid organic feel
	for i in range(anim.get_track_count()):
		anim.track_set_interpolation_type(i, Animation.INTERPOLATION_CUBIC)

	ResourceSaver.save(anim, "res://assets/3dassets/character/anim_attack1.res")

func _create_attack_2(base_rots: Dictionary, base_poss: Dictionary) -> void:
	var anim = Animation.new()
	anim.length = 0.46
	anim.step = 0.0166

	# Hips
	var t_hip_p = anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(t_hip_p, "Armature/Skeleton3D:Hips")
	var hip_p = base_poss.get("Hips", Vector3(-0.578, 77.18, 9.7))
	anim.position_track_insert_key(t_hip_p, 0.0, hip_p)
	anim.position_track_insert_key(t_hip_p, 0.14, hip_p + Vector3(0, 3.0, -1.0)) # reach high
	anim.position_track_insert_key(t_hip_p, 0.24, hip_p + Vector3(0, -6.0, 5.0)) # heavy downward cleave
	anim.position_track_insert_key(t_hip_p, 0.46, hip_p)

	# Spine02
	var t_spine = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_spine, "Armature/Skeleton3D:Spine02")
	var sp_idle = base_rots.get("Spine02", Quaternion.IDENTITY)
	var sp_high = sp_idle * Quaternion(Vector3.RIGHT, deg_to_rad(-25.0)) * Quaternion(Vector3.UP, deg_to_rad(-20.0))
	var sp_cleave = sp_idle * Quaternion(Vector3.RIGHT, deg_to_rad(35.0)) * Quaternion(Vector3.UP, deg_to_rad(25.0))
	anim.rotation_track_insert_key(t_spine, 0.0, sp_idle)
	anim.rotation_track_insert_key(t_spine, 0.14, sp_high)
	anim.rotation_track_insert_key(t_spine, 0.24, sp_cleave)
	anim.rotation_track_insert_key(t_spine, 0.35, sp_idle * Quaternion(Vector3.RIGHT, deg_to_rad(10.0)))
	anim.rotation_track_insert_key(t_spine, 0.46, sp_idle)

	# RightArm (Overhead slash)
	var t_rarm = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_rarm, "Armature/Skeleton3D:RightArm")
	var rarm_idle = base_rots.get("RightArm", Quaternion.IDENTITY)
	var rarm_high = rarm_idle * Quaternion(Vector3.RIGHT, deg_to_rad(-110.0)) * Quaternion(Vector3.FORWARD, deg_to_rad(-30.0))
	var rarm_cleave = rarm_idle * Quaternion(Vector3.RIGHT, deg_to_rad(85.0)) * Quaternion(Vector3.FORWARD, deg_to_rad(20.0)) * Quaternion(Vector3.UP, deg_to_rad(30.0))
	anim.rotation_track_insert_key(t_rarm, 0.0, rarm_idle)
	anim.rotation_track_insert_key(t_rarm, 0.14, rarm_high)
	anim.rotation_track_insert_key(t_rarm, 0.24, rarm_cleave)
	anim.rotation_track_insert_key(t_rarm, 0.35, rarm_idle * Quaternion(Vector3.RIGHT, deg_to_rad(30.0)))
	anim.rotation_track_insert_key(t_rarm, 0.46, rarm_idle)

	# RightForeArm
	var t_rfa = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_rfa, "Armature/Skeleton3D:RightForeArm")
	var rfa_idle = base_rots.get("RightForeArm", Quaternion.IDENTITY)
	anim.rotation_track_insert_key(t_rfa, 0.0, rfa_idle)
	anim.rotation_track_insert_key(t_rfa, 0.14, rfa_idle * Quaternion(Vector3.RIGHT, deg_to_rad(80.0)))
	anim.rotation_track_insert_key(t_rfa, 0.24, rfa_idle * Quaternion(Vector3.RIGHT, deg_to_rad(10.0)))
	anim.rotation_track_insert_key(t_rfa, 0.46, rfa_idle)

	# RightHand
	var t_rh = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_rh, "Armature/Skeleton3D:RightHand")
	var rh_idle = base_rots.get("RightHand", Quaternion.IDENTITY)
	anim.rotation_track_insert_key(t_rh, 0.0, rh_idle)
	anim.rotation_track_insert_key(t_rh, 0.14, rh_idle * Quaternion(Vector3.RIGHT, deg_to_rad(-30.0)))
	anim.rotation_track_insert_key(t_rh, 0.24, rh_idle * Quaternion(Vector3.RIGHT, deg_to_rad(45.0)))
	anim.rotation_track_insert_key(t_rh, 0.46, rh_idle)

	for i in range(anim.get_track_count()):
		anim.track_set_interpolation_type(i, Animation.INTERPOLATION_CUBIC)

	ResourceSaver.save(anim, "res://assets/3dassets/character/anim_attack2.res")

func _create_attack_3(base_rots: Dictionary, base_poss: Dictionary) -> void:
	var anim = Animation.new()
	anim.length = 0.58
	anim.step = 0.0166

	# Hips
	var t_hip_p = anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(t_hip_p, "Armature/Skeleton3D:Hips")
	var hip_p = base_poss.get("Hips", Vector3(-0.578, 77.18, 9.7))
	anim.position_track_insert_key(t_hip_p, 0.0, hip_p)
	anim.position_track_insert_key(t_hip_p, 0.12, hip_p + Vector3(0, -4.0, -2.0)) # crouch coil
	anim.position_track_insert_key(t_hip_p, 0.28, hip_p + Vector3(0, 2.0, 6.0)) # spin leap
	anim.position_track_insert_key(t_hip_p, 0.42, hip_p + Vector3(0, -3.0, 8.0)) # landing
	anim.position_track_insert_key(t_hip_p, 0.58, hip_p)

	# Spine02 (Full 360 spin rotation)
	var t_spine = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_spine, "Armature/Skeleton3D:Spine02")
	var sp_idle = base_rots.get("Spine02", Quaternion.IDENTITY)
	anim.rotation_track_insert_key(t_spine, 0.0, sp_idle)
	anim.rotation_track_insert_key(t_spine, 0.12, sp_idle * Quaternion(Vector3.UP, deg_to_rad(-60.0)))
	anim.rotation_track_insert_key(t_spine, 0.25, sp_idle * Quaternion(Vector3.UP, deg_to_rad(90.0)))
	anim.rotation_track_insert_key(t_spine, 0.35, sp_idle * Quaternion(Vector3.UP, deg_to_rad(180.0)))
	anim.rotation_track_insert_key(t_spine, 0.44, sp_idle * Quaternion(Vector3.UP, deg_to_rad(45.0)))
	anim.rotation_track_insert_key(t_spine, 0.58, sp_idle)

	# RightArm (Wide horizontal cleave)
	var t_rarm = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_rarm, "Armature/Skeleton3D:RightArm")
	var rarm_idle = base_rots.get("RightArm", Quaternion.IDENTITY)
	anim.rotation_track_insert_key(t_rarm, 0.0, rarm_idle)
	anim.rotation_track_insert_key(t_rarm, 0.12, rarm_idle * Quaternion(Vector3.RIGHT, deg_to_rad(-40.0)) * Quaternion(Vector3.UP, deg_to_rad(-60.0)))
	anim.rotation_track_insert_key(t_rarm, 0.25, rarm_idle * Quaternion(Vector3.RIGHT, deg_to_rad(60.0)) * Quaternion(Vector3.UP, deg_to_rad(80.0)))
	anim.rotation_track_insert_key(t_rarm, 0.38, rarm_idle * Quaternion(Vector3.RIGHT, deg_to_rad(50.0)) * Quaternion(Vector3.UP, deg_to_rad(40.0)))
	anim.rotation_track_insert_key(t_rarm, 0.58, rarm_idle)

	# LeftArm
	var t_larm = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_larm, "Armature/Skeleton3D:LeftArm")
	var larm_idle = base_rots.get("LeftArm", Quaternion.IDENTITY)
	anim.rotation_track_insert_key(t_larm, 0.0, larm_idle)
	anim.rotation_track_insert_key(t_larm, 0.12, larm_idle * Quaternion(Vector3.RIGHT, deg_to_rad(50.0)))
	anim.rotation_track_insert_key(t_larm, 0.28, larm_idle * Quaternion(Vector3.RIGHT, deg_to_rad(-70.0)))
	anim.rotation_track_insert_key(t_larm, 0.58, larm_idle)

	for i in range(anim.get_track_count()):
		anim.track_set_interpolation_type(i, Animation.INTERPOLATION_CUBIC)

	ResourceSaver.save(anim, "res://assets/3dassets/character/anim_attack3.res")
