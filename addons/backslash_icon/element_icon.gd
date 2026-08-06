@tool
extends TextureRect
class_name ElementIcon

## The type of element icon to display (FIRE, AIR, EARTH, WATER).
@export_enum("FIRE", "AIR", "EARTH", "WATER") var element_type: int = 0:
	set(val):
		element_type = val
		_update_icon()

func _ready() -> void:
	_update_icon()

func _update_icon() -> void:
	var path = ""
	match element_type:
		0: path = "res://graphics/Arcane Icon Fire.png"
		1: path = "res://graphics/Arcane Icon Wind.png"
		2: path = "res://graphics/Arcane Icon Earth.png"
		3: path = "res://graphics/Arcane Icon Water.png"
		
	if path != "" and ResourceLoader.exists(path):
		texture = load(path)
	else:
		texture = null
