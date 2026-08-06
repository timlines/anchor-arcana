extends Node

## Autoload singleton coordinating the pooling and spawning of 2D element explosions and sparkles.
## Depends on: Backslash Logging (Log)

const ExplosionEffectScript = preload("res://addons/backslash_explode/explosion_effect.gd")

var _pool: Array = []


func _ready() -> void:
	if has_node("/root/Log"):
		Log.info("BackslashExplode addon initialized successfully.", "Explode")
	else:
		print("[INFO] [Explode] BackslashExplode initialized.")


func explode(key, global_pos: Vector2) -> Node2D:
	var element = _get_element_name(key)
	
	if has_node("/root/Log"):
		Log.info("Triggered explode for element '%s' at position %s" % [element, str(global_pos)], "Explode")
	
	var effect = _get_effect_node()
	
	var parent = get_tree().current_scene
	if not parent:
		parent = self
		
	if effect.get_parent() != parent:
		if effect.get_parent() != null:
			effect.get_parent().remove_child(effect)
		parent.add_child(effect)
		
	effect.global_position = global_pos
	effect.play_explode(element)
	return effect


func sparkle(key, global_pos: Vector2) -> Node2D:
	var element = _get_element_name(key)
	
	if has_node("/root/Log"):
		Log.info("Triggered sparkle for element '%s' at position %s" % [element, str(global_pos)], "Explode")
		
	var effect = _get_effect_node()
	
	var parent = get_tree().current_scene
	if not parent:
		parent = self
		
	if effect.get_parent() != parent:
		if effect.get_parent() != null:
			effect.get_parent().remove_child(effect)
		parent.add_child(effect)
		
	effect.global_position = global_pos
	effect.play_sparkle(element)
	return effect


func _get_effect_node() -> Node2D:
	var valid_pool = []
	for node in _pool:
		if is_instance_valid(node):
			valid_pool.append(node)
	_pool = valid_pool
	
	for node in _pool:
		if not node.is_active:
			return node
			
	var effect = ExplosionEffectScript.new()
	_pool.append(effect)
	
	if has_node("/root/Log"):
		Log.debug("Created new ExplosionEffect instance for pool. Size: %d" % _pool.size(), "Explode")
		
	return effect


func _get_element_name(key) -> String:
	if key is String:
		var s = key.to_lower().strip_edges()
		if s == "air":
			return "wind"
		elif s == "fire" or s == "water" or s == "earth" or s == "wind":
			return s
	elif key is int:
		match key:
			0: return "fire"
			1: return "wind"
			2: return "earth"
			3: return "water"
	
	if has_node("/root/Log"):
		Log.warn("Invalid element key '%s' passed. Defaulting to fire." % str(key), "Explode")
	return "fire"
