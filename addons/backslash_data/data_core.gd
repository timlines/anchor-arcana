extends Node

## Unified JSON save state storage and delta adjustment API.
## Depends on the res://addons/backslash_logging/ modular logger.

const SAVE_PATH = "user://save_data.json"
var _save_data: Dictionary = {}

func _ready() -> void:
	_load_from_disk()

## Internal method to load JSON save data from disk.
func _load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_save_data = {}
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_raise_error("Failed to open save file for reading: " + SAVE_PATH, "ERR_FILE_IO")
		_save_data = {}
		return
		
	var content = file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(content)
	if parsed == null:
		_raise_error("Corrupted save data JSON format: " + content, "ERR_INVALID_JSON")
		_save_data = {}
		return
		
	if parsed is Dictionary:
		_save_data = parsed
	else:
		_raise_error("Save data JSON is not a Dictionary: " + content, "ERR_INVALID_TYPE")
		_save_data = {}

## Serializes the active in-memory save data state to disk.
func save_to_disk() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_raise_error("Failed to open save file for writing: " + SAVE_PATH, "ERR_FILE_IO")
		return
		
	var json_str = JSON.stringify(_save_data, "\t")
	file.store_string(json_str)
	file.close()

## Sets a key value in the save database.
func set_val(key: String, value: Variant) -> void:
	_save_data[key] = value
	save_to_disk()

func _set(property: StringName, value: Variant) -> bool:
	set_val(String(property), value)
	return true

func _get(property: StringName) -> Variant:
	var key = String(property)
	if _save_data.has(key):
		return _save_data[key]
	return null

## Retrieves a stored key value or default if not found.
func get_val(key: String, default: Variant = null) -> Variant:
	var val = _save_data.get(key, default)
	if key == "current_level_path" and val is String and "res://resources/levels/" in val:
		val = val.replace("res://resources/levels/", "res://data/")
		_save_data[key] = val
		save_to_disk()
	return val

## Adjusts a numerical key value by a given delta. Supports float/int and String representations.
func adjust(key: String, delta: Variant) -> void:
	var current_val = _save_data.get(key, 0.0)
	if not (current_val is int or current_val is float):
		_raise_error("Cannot adjust non-numerical save key: " + key, "ERR_INVALID_OPERATION")
		return
		
	var numeric_delta: float = 0.0
	if delta is int or delta is float:
		numeric_delta = float(delta)
	elif delta is String:
		# Parse optional leading signs from strings (e.g. "+10", "-5.5")
		var clean_str = delta.strip_edges()
		if clean_str.begins_with("+"):
			clean_str = clean_str.substr(1)
		if clean_str.is_valid_float():
			numeric_delta = clean_str.to_float()
		else:
			_raise_error("Invalid non-numerical delta string: " + delta, "ERR_INVALID_ARGUMENT")
			return
	else:
		_raise_error("Unsupported adjustment delta type: " + str(typeof(delta)), "ERR_INVALID_ARGUMENT")
		return
		
	_save_data[key] = current_val + numeric_delta
	save_to_disk()

## Clears stored state. Supports clearing keys, full wipe, and json string overrides.
func clear(key: String = "", data_as_string: String = "") -> void:
	if key != "" and data_as_string != "":
		# Overwrite a specific key value with a parsed JSON string
		var parsed = JSON.parse_string(data_as_string)
		if parsed == null:
			_raise_error("Failed to parse JSON string for key: " + key, "ERR_INVALID_JSON")
			return
		_save_data[key] = parsed
	elif key != "":
		# Clear a specific key
		_save_data.erase(key)
	elif data_as_string != "":
		# Overwrite entire save dictionary with a new JSON string representation
		var parsed = JSON.parse_string(data_as_string)
		if parsed is Dictionary:
			_save_data = parsed
		else:
			_raise_error("Save data override JSON string is not a Dictionary structure", "ERR_INVALID_TYPE")
			return
	else:
		# Complete save wipe
		_save_data.clear()
		
	save_to_disk()

## Unified method to read and parse local levels or configuration databases.
func read_file(resource_path: String) -> Variant:
	return _read_file_impl(resource_path)

## Casing alias method to ensure compatibility with camelCase calls.
func readFile(resource_path: String) -> Variant:
	return _read_file_impl(resource_path)

func _read_file_impl(resource_path: String) -> Variant:
	var final_path = resource_path.strip_edges()
	
	# If old resources/levels path is passed, map it to data/
	if "resources/levels/" in final_path:
		final_path = final_path.replace("resources/levels/", "data/")
	elif "levels/" in final_path:
		final_path = final_path.replace("levels/", "data/")
	
	# Automatically resolve relative paths under standard resources or data folder
	if not final_path.begins_with("res://") and not final_path.begins_with("user://"):
		var test_paths = [
			"res://data/" + final_path,
			"res://resources/" + final_path,
			"res://" + final_path
		]
		var resolved = false
		for path in test_paths:
			if FileAccess.file_exists(path):
				final_path = path
				resolved = true
				break
		if not resolved:
			# Fallback to direct resources relative path if not resolved
			final_path = "res://resources/" + final_path

	if not FileAccess.file_exists(final_path):
		_raise_error("Requested resource file does not exist: " + final_path, "ERR_FILE_NOT_FOUND")
		return null
		
	var file = FileAccess.open(final_path, FileAccess.READ)
	if file == null:
		_raise_error("Failed to open file for reading: " + final_path, "ERR_FILE_IO")
		return null
		
	var content = file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(content)
	if parsed == null:
		_raise_error("Failed to parse JSON file payload: " + final_path + " | Content: " + content, "ERR_INVALID_JSON")
		return null
		
	return parsed

## Internally captures standard call stack frame tracebacks and reports errors directly
## to standard output and the global modular Log autoload singleton.
func _raise_error(message: String, code: String = "ERR_GENERIC") -> void:
	var formatted_msg = "[%s] %s" % [code, message]
	
	var stack = get_stack()
	var trace_str = ""
	if stack != null and not stack.is_empty():
		trace_str = "\n--- Traceback (Most recent call first) ---"
		for i in range(stack.size()):
			var frame = stack[i]
			trace_str += "\n  Frame %d | File: %s:%d | Function: %s" % [
				i,
				frame.get("source", "unknown"),
				frame.get("line", 0),
				frame.get("function", "anonymous")
			]
		trace_str += "\n------------------------------------------"
		
	var final_msg = formatted_msg + trace_str
	
	# Route error output to standard error and push to editor debugger
	printerr(final_msg)
	push_error(final_msg)
	
	# Direct delivery to backslash logging autoload
	Log.error(final_msg, "Storage")

## Resets in-memory and disk save data, loading clean baseline cards from res://data/starting_cards.json.
func reset_save_data() -> void:
	clear() # Wipes save database and saves empty dict to user://save_data.json
	
	# Load starting cards configuration
	var starting_cards_file = "res://data/starting_cards.json"
	if FileAccess.file_exists(starting_cards_file):
		var file = FileAccess.open(starting_cards_file, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(content)
		if parsed is Array:
			set_val("player_deck", parsed)
			Log.info("Reset save data: successfully loaded starting cards deck baseline.", "Storage")
		else:
			Log.error("Reset save data: parsed starting cards JSON is not an Array format.", "Storage")
	else:
		Log.error("Reset save data: starting_cards.json not found.", "Storage")

## Transition to a scene with a fullscreen fading black CanvasLayer transition.
## @deprecated Use BackslashScene.transition_to_scene instead.
func transition_to_scene(scene_path: String) -> void:
	if has_node("/root/BackslashScene"):
		get_node("/root/BackslashScene").transition_to_scene(scene_path)
	else:
		get_tree().change_scene_to_file(scene_path)

## Helper method to transition to victory screen.
## @deprecated Use BackslashScene.transition_to_win instead.
func transition_to_win() -> void:
	if has_node("/root/BackslashScene"):
		get_node("/root/BackslashScene").transition_to_win()
	else:
		get_tree().change_scene_to_file("res://scenes/victory_screen/victory_screen.tscn")

## Helper method to transition to game over/lose screen.
## @deprecated Use BackslashScene.transition_to_lose instead.
func transition_to_lose() -> void:
	if has_node("/root/BackslashScene"):
		get_node("/root/BackslashScene").transition_to_lose()
	else:
		get_tree().change_scene_to_file("res://scenes/game_over/game_over.tscn")
