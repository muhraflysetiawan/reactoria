extends Node
## Autoload singleton — carries the player's weapon choice between scenes.

# Weapon ID chosen in the combine screen, e.g. "h2o_sword", "hcl_gun"
var selected_weapon_id: String = "h2o_sword"

# All available weapons and their combine recipes.
# element_a + element_b → weapon.
const WEAPONS: Array[Dictionary] = [
	{
		"id": "h2o_sword",
		"name": "Aqua Saber",
		"formula": "H₂O",
		"element_a": "H₂",
		"element_b": "O",
		"description": "Pedang air yang membelah musuh dengan gelombang.",
		"scene": "res://scenes/sword.tscn",
		"color": Color(0.2, 0.7, 1.0),
	},
	{
		"id": "koh_bow",
		"name": "Crystal Bow",
		"formula": "KOH",
		"element_a": "K",
		"element_b": "OH",
		"description": "Busur kristal basa yang menembak panah tajam.",
		"scene": "res://assets/3dassets/bow/koh-bow-lowpoly.glb",
		"color": Color(0.8, 0.5, 1.0),
	},
	{
		"id": "hcl_gun",
		"name": "Acid Mist Musket",
		"formula": "HCl",
		"element_a": "H",
		"element_b": "Cl",
		"description": "Senapan kabut asam yang merusak dari jarak jauh.",
		"scene": "res://assets/3dassets/gun/hcl-gun-lowpoly.glb",
		"color": Color(0.2, 1.0, 0.4),
	},
	{
		"id": "mgo_hammer",
		"name": "Magnesium Warhammer",
		"formula": "MgO",
		"element_a": "Mg",
		"element_b": "O",
		"description": "Palu berat magnesium oksida yang menghancurkan.",
		"scene": "res://assets/3dassets/hammer/mgo-hammer-lowpoly.glb",
		"color": Color(1.0, 0.6, 0.2),
	},
	{
		"id": "naoh_spear",
		"name": "Caustic Spear",
		"formula": "NaOH",
		"element_a": "Na",
		"element_b": "OH",
		"description": "Tombak kaustik natrium hidroksida.",
		"scene": "res://assets/3dassets/spear/naoh-spear-lowpoly.glb",
		"color": Color(1.0, 0.85, 0.3),
	},
	{
		"id": "c10h8_sword",
		"name": "Naphtha Blade",
		"formula": "C₁₀H₈",
		"element_a": "C₁₀",
		"element_b": "H₈",
		"description": "Pedang naftalena yang terbakar saat menyerang.",
		"scene": "res://assets/3dassets/sword/c10h8-sword-lowpoly.glb",
		"color": Color(1.0, 0.3, 0.3),
	},
]

func get_weapon_data() -> Dictionary:
	for w in WEAPONS:
		if w["id"] == selected_weapon_id:
			return w
	return WEAPONS[0]
