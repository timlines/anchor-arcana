extends Node

## Global Autoload Zoom Manager for managing aspect-aware camera zoom levels and transitions.
## Name: BackslashZoom
## Depends on: Backslash Logging (Log)

const DESIGN_ASPECT = 16.0 / 9.0

## Master configuration profile for centralized camera zooms.
@export var settings: ZoomSettings

var active_camera: Camera2D = null
var current_phase_index: int = 0
var map_mode_active: bool = false
var current_base_zoom: float = 1.5

var _zoom_tween: Tween = null

## Initializes the zoom manager, loads the configuration settings, and connects phase/viewport signals.
func _ready() -> void:
	if not settings:
		var settings_path = "res://addons/backslash_zoom/zoom_settings.tres"
		if ResourceLoader.exists(settings_path):
			settings = load(settings_path) as ZoomSettings
			if not settings:
				Log.error("Failed to load ZoomSettings from path: %s" % settings_path, "Zoom")
		else:
			Log.error("ZoomSettings file not found at path: %s" % settings_path, "Zoom")
		
		if not settings:
			settings = ZoomSettings.new()
			Log.warn("Fallback to default ZoomSettings created in memory.", "Zoom")
		
	Log.info("BackslashZoom manager initialized with centralized master settings.", "Zoom")

	if has_node("/root/PhaseManager"):
		PhaseManager.phase_changed.connect(_on_phase_changed)
		current_phase_index = PhaseManager.current_phase
		_update_current_base_zoom()
	else:
		Log.warn("PhaseManager autoload not found during ZoomManager initialization.", "Zoom")
	
	var viewport = get_viewport()
	if is_instance_valid(viewport):
		viewport.size_changed.connect(_on_viewport_size_changed)
	else:
		Log.error("Failed to retrieve viewport during ZoomManager initialization.", "Zoom")

## Registers a Camera2D to be controlled by the zoom manager.
func register_camera(camera: Camera2D) -> void:
	if not is_instance_valid(camera):
		Log.error("Attempted to register an invalid or null camera.", "Zoom")
		return
		
	active_camera = camera
	Log.info("Camera successfully registered with BackslashZoom.", "Zoom")
	_apply_zoom(true)

## Detects if the current display configuration fits a mobile/portrait layout profile.
func is_mobile_layout() -> bool:
	var is_mobile_os = OS.get_name() in ["Android", "iOS"]
	var viewport = get_viewport()
	if not is_instance_valid(viewport):
		Log.warn("Viewport is invalid when checking layout. Defaulting to false.", "Zoom")
		return false
		
	var viewport_size = viewport.get_visible_rect().size
	var is_portrait = viewport_size.x < viewport_size.y
	return is_mobile_os or is_portrait

## Updates current_base_zoom using the master configurations based on phase & layout.
func _update_current_base_zoom() -> void:
	if not settings:
		Log.warn("Cannot update base zoom: Settings profile is null.", "Zoom")
		return
		
	var mobile = is_mobile_layout()
	var map_target = settings.map_zoom_mobile if mobile else settings.map_zoom_landscape
	var gameplay_target = settings.gameplay_zoom_mobile if mobile else settings.gameplay_zoom_landscape
	
	if map_mode_active or current_phase_index == 0:
		current_base_zoom = map_target
	else:
		current_base_zoom = gameplay_target

## Sets the active phase index and triggers smooth camera transitions.
func set_phase(phase_index: int) -> void:
	if has_node("/root/PhaseManager"):
		var max_phases = PhaseManager.GamePhase.values().size()
		if phase_index < 0 or phase_index >= max_phases:
			Log.error("Invalid phase index received in set_phase: %d. Range: 0 to %d." % [phase_index, max_phases - 1], "Zoom")
			return
			
	if current_phase_index == phase_index:
		return
		
	current_phase_index = phase_index
	map_mode_active = false
	_update_current_base_zoom()
	
	Log.info("Phase zoom target updated. Phase: %d | Base Zoom: %.2f | Mobile Layout: %s" % [
		phase_index, current_base_zoom, str(is_mobile_layout())
	], "Zoom")
	
	_apply_zoom(false)

## Sets the tactical map mode zoom state.
func set_map_mode(active: bool) -> void:
	if map_mode_active == active:
		return
	map_mode_active = active
	_update_current_base_zoom()
	
	Log.info("Tactical Map Mode zoom state changed. Active: %s | Base Zoom: %.2f | Mobile Layout: %s" % [
		str(active), current_base_zoom, str(is_mobile_layout())
	], "Zoom")
		
	_apply_zoom(false)

## Calculates the aspect-aware zoom scale factor to fit edge-to-edge on any display.
func get_aspect_scale() -> float:
	var viewport = get_viewport()
	if not is_instance_valid(viewport):
		Log.warn("Viewport is invalid when calculating aspect scale. Defaulting to 1.0.", "Zoom")
		return 1.0
		
	var viewport_size = viewport.get_visible_rect().size
	if viewport_size.y <= 0 or viewport_size.x <= 0:
		Log.warn("Invalid viewport size (width: %.1f, height: %.1f). Defaulting aspect scale to 1.0." % [viewport_size.x, viewport_size.y], "Zoom")
		return 1.0
		
	var current_aspect = viewport_size.x / viewport_size.y
	
	if current_aspect < DESIGN_ASPECT:
		return current_aspect / DESIGN_ASPECT
		
	return 1.0

## Applies the calculated dynamic zoom to the active camera.
func _apply_zoom(instant: bool = false) -> void:
	_update_path_flashing()

	if not is_instance_valid(active_camera):
		Log.warn("Attempted to apply zoom but active camera is invalid or null.", "Zoom")
		return
		
	var map_mode = map_mode_active or current_phase_index == 0
	_update_node_visibilities(map_mode)
		
	var aspect_scale = get_aspect_scale()
	var final_zoom_val = current_base_zoom * aspect_scale
	var target_zoom = Vector2(final_zoom_val, final_zoom_val)
	
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()
		
	if not is_inside_tree():
		Log.warn("Cannot apply zoom or tween: ZoomManager is not in the scene tree.", "Zoom")
		return
		
	if instant:
		active_camera.zoom = target_zoom
		if map_mode:
			active_camera.top_level = true
			active_camera.global_position = Vector2.ZERO
		else:
			active_camera.top_level = false
			active_camera.position = Vector2.ZERO
		Log.debug("Zoom applied instantly: %s (Scale Factor: %.3f)" % [str(target_zoom), aspect_scale], "Zoom")
	else:
		_zoom_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		_zoom_tween.tween_property(active_camera, "zoom", target_zoom, 0.8)
		
		if map_mode:
			active_camera.top_level = true
			_zoom_tween.tween_property(active_camera, "global_position", Vector2.ZERO, 0.8)
		else:
			active_camera.top_level = true
			var parent = active_camera.get_parent()
			if is_instance_valid(parent) and parent is Node2D:
				var target_pos = parent.global_position
				_zoom_tween.tween_property(active_camera, "global_position", target_pos, 0.8)
			else:
				Log.error("Active camera has no valid Node2D parent to follow.", "Zoom")
			
			_zoom_tween.set_parallel(false).tween_callback(func():
				if is_instance_valid(active_camera) and not (map_mode_active or current_phase_index == 0):
					active_camera.top_level = false
					active_camera.position = Vector2.ZERO
			)
			
		Log.debug("Zoom tween initiated. Target: %s | Duration: 0.8s" % str(target_zoom), "Zoom")

## Handler for phase changes in PhaseManager.
func _on_phase_changed(new_phase: int) -> void:
	set_phase(new_phase)

## Handler for viewport changes, ensuring instant recalculation of aspect scaling and orientation updates.
func _on_viewport_size_changed() -> void:
	_update_current_base_zoom()
	_apply_zoom(true)

## Triggers path line flashing dynamically based on phase or map mode active status.
func _update_path_flashing() -> void:
	if not is_inside_tree():
		return
	var tree = get_tree()
	if not is_instance_valid(tree):
		return
	var level = tree.current_scene
	if is_instance_valid(level):
		var conductor = level.find_child("WaveConductor", true, false)
		if is_instance_valid(conductor) and conductor.has_method("set_flash_path"):
			var should_flash = map_mode_active or current_phase_index == 0
			conductor.set_flash_path(should_flash)

## Dynamically updates player and totem visibilities based on current Map Mode state.
func _update_node_visibilities(map_mode_active_state: bool) -> void:
	if not is_inside_tree():
		return
	var tree = get_tree()
	if not is_instance_valid(tree):
		return
		
	var player = tree.get_first_node_in_group("player")
	if is_instance_valid(player):
		player.visible = not map_mode_active_state
		
	var totems = tree.get_nodes_in_group("totems")
	for totem in totems:
		if is_instance_valid(totem):
			totem.visible = not map_mode_active_state
