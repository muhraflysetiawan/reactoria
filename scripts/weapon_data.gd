extends Node
## Autoload singleton — menyimpan pilihan senjata pemain dan konfigurasi efek masing-masing senjata.

# ID Senjata yang dipilih dari Combine Screen
var selected_weapon_id: String = "h2o_sword"

# Daftar lengkap senjata, formula kimia, resep combine, dan konfigurasi efeknya:
# - trail_color: warna efek tebasan (Slash Trail VFX)
# - particle_color: warna efek partikel aura (Aura Glow Particles)
# - sounds: daftar efek suara ayunan (Audio Swing SFX)
# - sound_speeds: variasi kecepatan/pitch suara sesuai combo
# - trail_base & trail_tip: titik anchor khusus (opsional, jika tidak ada otomatis dihitung dari AABB mesh)
const WEAPONS: Array[Dictionary] = [
	{
		"id": "h2o_sword",
		"name": "Aqua Saber",
		"formula": "H₂O",
		"elements": ["H", "O"],
		"description": "Pedang air yang membelah musuh dengan gelombang tajam.",
		"scene_path": "res://scenes/weapons/sword_h2o.tscn",
		"color": Color(0.2, 0.7, 1.0),
		"trail_color": Color(0.2, 0.85, 1.0),
		"particle_color": Color(0.3, 0.9, 1.0),
		"trail_base": Vector3(0.08, 0.15, 0.0),
		"trail_tip": Vector3(-0.39, 1.02, 0.0),
		"sounds": [
			"res://assets/audio/water_sword/thrust-slash.MP3",
			"res://assets/audio/water_sword/sword-slash.MP3",
			"res://assets/audio/water_sword/charged-slash.MP3",
			"res://assets/audio/water_sword/charged-up-sword-slash.MP3",
		],
		"sound_speeds": [2.0, 1.0, 1.0, 1.0],
	},
	{
		"id": "koh_bow",
		"name": "Crystal Bow",
		"formula": "KOH",
		"elements": ["K", "O", "H"],
		"description": "Busur kristal basa yang menembakkan energi tajam berkecepatan tinggi.",
		"scene_path": "res://scenes/weapons/bow_koh.tscn",
		"color": Color(0.8, 0.5, 1.0),
		"trail_color": Color(0.85, 0.45, 1.0),
		"particle_color": Color(0.9, 0.55, 1.0),
		"sounds": [
			"res://assets/audio/sword_swing1.wav",
			"res://assets/audio/sword_swing2.wav",
			"res://assets/audio/sword_swing1.wav",
			"res://assets/audio/sword_swing2.wav",
		],
		"sound_speeds": [1.5, 1.6, 1.4, 1.7],
	},
	{
		"id": "hcl_gun",
		"name": "Acid Mist Musket",
		"formula": "HCl",
		"elements": ["H", "Cl"],
		"description": "Senapan kabut asam yang menyemburkan korosi beracun.",
		"scene_path": "res://scenes/weapons/gun_hcl.tscn",
		"color": Color(0.2, 1.0, 0.4),
		"trail_color": Color(0.25, 1.0, 0.35),
		"particle_color": Color(0.35, 1.0, 0.45),
		"sounds": [
			"res://assets/audio/water_sword/thrust-slash.MP3",
			"res://assets/audio/sword_swing2.wav",
			"res://assets/audio/water_sword/charged-slash.MP3",
			"res://assets/audio/sword_swing3.wav",
		],
		"sound_speeds": [2.2, 1.5, 1.3, 1.4],
	},
	{
		"id": "mgo_hammer",
		"name": "Magnesium Warhammer",
		"formula": "MgO",
		"elements": ["Mg", "O"],
		"description": "Palu berat magnesium oksida dengan daya hantam destruktif.",
		"scene_path": "res://scenes/weapons/hammer_mgo.tscn",
		"color": Color(1.0, 0.6, 0.2),
		"trail_color": Color(1.0, 0.6, 0.15),
		"particle_color": Color(1.0, 0.75, 0.2),
		"sounds": [
			"res://assets/audio/sword_swing3.wav",
			"res://assets/audio/water_sword/charged-up-sword-slash.MP3",
			"res://assets/audio/sword_swing3.wav",
			"res://assets/audio/water_sword/charged-slash.MP3",
		],
		"sound_speeds": [0.75, 0.8, 0.7, 0.85],
	},
	{
		"id": "naoh_spear",
		"name": "Caustic Spear",
		"formula": "NaOH",
		"elements": ["Na", "O", "H"],
		"description": "Tombak kaustik natrium hidroksida dengan tusukan cepat mematikan.",
		"scene_path": "res://scenes/weapons/spear_naoh.tscn",
		"color": Color(1.0, 0.85, 0.3),
		"trail_color": Color(1.0, 0.88, 0.25),
		"particle_color": Color(1.0, 0.95, 0.4),
		"sounds": [
			"res://assets/audio/water_sword/thrust-slash.MP3",
			"res://assets/audio/water_sword/thrust-slash.MP3",
			"res://assets/audio/water_sword/sword-slash.MP3",
			"res://assets/audio/water_sword/charged-slash.MP3",
		],
		"sound_speeds": [2.2, 2.4, 1.5, 1.3],
	},
	{
		"id": "c10h8_sword",
		"name": "Naphtha Blade",
		"formula": "C₁₀H₈",
		"elements": ["C", "H"],
		"description": "Pedang naftalena yang membara dengan kobaran api tebasan membakar.",
		"scene_path": "res://scenes/weapons/sword_c10h8.tscn",
		"color": Color(1.0, 0.3, 0.3),
		"trail_color": Color(1.0, 0.25, 0.2),
		"particle_color": Color(1.0, 0.4, 0.15),
		"sounds": [
			"res://assets/audio/water_sword/sword-slash.MP3",
			"res://assets/audio/water_sword/charged-slash.MP3",
			"res://assets/audio/sword_swing3.wav",
			"res://assets/audio/water_sword/charged-up-sword-slash.MP3",
		],
		"sound_speeds": [1.2, 1.1, 1.15, 1.0],
	},
	{
		"id": "c3h8_hammer",
		"name": "Combustion Warhammer",
		"formula": "C₃H₈",
		"elements": ["C", "H"],
		"description": "Palu propana pembakaran berkekuatan ledakan kinetik hebat.",
		"scene_path": "res://scenes/weapons/hammer_c3h8.tscn",
		"color": Color(1.0, 0.45, 0.1),
		"trail_color": Color(1.0, 0.45, 0.1),
		"particle_color": Color(1.0, 0.55, 0.15),
		"sounds": [
			"res://assets/audio/sword_swing3.wav",
			"res://assets/audio/water_sword/charged-slash.MP3",
			"res://assets/audio/sword_swing3.wav",
			"res://assets/audio/water_sword/charged-up-sword-slash.MP3",
		],
		"sound_speeds": [0.7, 0.75, 0.7, 0.8],
	},
	{
		"id": "cif3_spear",
		"name": "Fluorine Spear",
		"formula": "ClF₃",
		"elements": ["Cl", "F"],
		"description": "Tombak klorin trifluorida hiper-reaktif dengan daya tembus ekstrem.",
		"scene_path": "res://scenes/weapons/spear_cif3.tscn",
		"color": Color(0.2, 0.9, 0.8),
		"trail_color": Color(0.15, 0.95, 0.85),
		"particle_color": Color(0.25, 1.0, 0.9),
		"sounds": [
			"res://assets/audio/water_sword/thrust-slash.MP3",
			"res://assets/audio/sword_swing1.wav",
			"res://assets/audio/water_sword/thrust-slash.MP3",
			"res://assets/audio/water_sword/charged-slash.MP3",
		],
		"sound_speeds": [2.3, 1.6, 2.4, 1.4],
	},
]

func get_weapon_data() -> Dictionary:
	for w in WEAPONS:
		if w["id"] == selected_weapon_id:
			return w
	return WEAPONS[0]
