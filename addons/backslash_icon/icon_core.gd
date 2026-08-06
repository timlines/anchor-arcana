extends Node

# Explicit path references to graphics assets
const ICON_PATH_FIRE = "res://graphics/Arcane Icon Fire.png"
const ICON_PATH_AIR = "res://graphics/Arcane Icon Wind.png"
const ICON_PATH_EARTH = "res://graphics/Arcane Icon Earth.png"
const ICON_PATH_WATER = "res://graphics/Arcane Icon Water.png"

# Cache dictionary to prevent reloading resources from disk
var _cache: Dictionary = {}

## Returns a Texture2D for the requested element.
## element can be an int (ElementType enum) or a case-insensitive String ("fire", "water", etc.).
func get_icon(element) -> Texture2D:
	var element_enum: int = -1
	
	if element is int:
		element_enum = element
	elif element is String:
		var normalized = element.to_lower().strip_edges()
		match normalized:
			"fire":
				element_enum = 0 # FIRE
			"air", "wind":
				element_enum = 1 # AIR
			"earth":
				element_enum = 2 # EARTH
			"water":
				element_enum = 3 # WATER
			_:
				Log.error("Invalid element string passed to BackslashIcon: %s" % element, "Icon")
				return null
	else:
		Log.error("Invalid type passed to BackslashIcon.get_icon: %s" % str(typeof(element)), "Icon")
		return null
		
	if _cache.has(element_enum):
		return _cache[element_enum]
		
	var path = ""
	match element_enum:
		0: path = ICON_PATH_FIRE
		1: path = ICON_PATH_AIR
		2: path = ICON_PATH_EARTH
		3: path = ICON_PATH_WATER
		_:
			Log.error("No icon path mapped for element enum: %d" % element_enum, "Icon")
			return null
			
	if ResourceLoader.exists(path):
		var tex = load(path)
		if tex:
			_cache[element_enum] = tex
			return tex
		else:
			Log.error("Failed to load icon texture from: %s" % path, "Icon")
	else:
		Log.error("Icon file not found: %s" % path, "Icon")
		
	return null
