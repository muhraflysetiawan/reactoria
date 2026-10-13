class_name ElementData
extends RefCounted

const DEFAULT_ICON := "res://assets/ui/campaign/elements/hydrogen.svg"

# Metadata mapping unsur/senyawa ke icon SVG dan warna representatif
const ELEMENT_INFO: Dictionary = {
	"H": {
		"name": "Hidrogen (H)",
		"icon": "res://assets/ui/campaign/elements/hydrogen.svg",
		"color": Color(0.35, 0.75, 1.0),
	},
	"O": {
		"name": "Oksigen (O)",
		"icon": "res://assets/ui/campaign/elements/oxygen.svg",
		"color": Color(0.45, 0.85, 0.95),
	},
	"K": {
		"name": "Kalium (K)",
		"icon": "res://assets/ui/campaign/elements/kalium.svg",
		"color": Color(0.85, 0.6, 1.0),
	},
	"OH": {
		"name": "Hidroksida (OH)",
		"icon": "res://assets/ui/campaign/elements/oxygen.svg",
		"color": Color(0.5, 0.9, 0.9),
	},
	"Cl": {
		"name": "Klorin (Cl)",
		"icon": "res://assets/ui/campaign/elements/chlorine.svg",
		"color": Color(0.4, 0.9, 0.35),
	},
	"Mg": {
		"name": "Magnesium (Mg)",
		"icon": "res://assets/ui/campaign/elements/magnesium.svg",
		"color": Color(0.9, 0.7, 0.35),
	},
	"Na": {
		"name": "Natrium (Na)",
		"icon": "res://assets/ui/campaign/elements/natrium.svg",
		"color": Color(0.95, 0.82, 0.45),
	},
	"C": {
		"name": "Karbon (C)",
		"icon": "res://assets/ui/campaign/elements/carbon.svg",
		"color": Color(1.0, 0.45, 0.2),
	},
	"F": {
		"name": "Fluorin (F)",
		"icon": "res://assets/ui/campaign/elements/fluoin.svg",
		"color": Color(0.3, 0.95, 0.85),
	},
}

static func get_info(el: String) -> Dictionary:
	if ELEMENT_INFO.has(el):
		return ELEMENT_INFO[el]
	return {
		"name": el,
		"icon": DEFAULT_ICON,
		"color": Color(0.8, 0.85, 0.9),
	}
