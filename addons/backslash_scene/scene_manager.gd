extends Node

## Centralized Scene and Pause Manager.
## Provides APIs for scene transition, victory/defeat, and game pause handling.

signal paused_state_changed(is_paused: bool)

const PAUSE_MENU_SCRIPT = preload("res://src/UI/pause_menu/pause_menu_overlay.gd")
var pause_menu: CanvasLayer = null

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS # Run even when tree is paused!
	
	# Instantiate global pause menu
	pause_menu = PAUSE_MENU_SCRIPT.new()
	if is_instance_valid(pause_menu):
		add_child(pause_menu)
		pause_menu.resume_requested.connect(resume_game)
		pause_menu.restart_requested.connect(reset_level)
		pause_menu.quit_requested.connect(quit_to_main_menu)
	else:
		Log.error("Failed to instantiate global PauseMenuOverlay.", "BackslashScene")

## Toggles the pause state of the game
func toggle_pause() -> void:
	if not is_instance_valid(pause_menu):
		Log.error("Pause menu is not instanced.", "BackslashScene")
		return
		
	if is_game_paused():
		resume_game()
	else:
		pause_game()

## Pauses the game and displays system menu
func pause_game() -> void:
	if not is_instance_valid(pause_menu):
		return
	get_tree().paused = true
	pause_menu.show_menu()
	paused_state_changed.emit(true)
	Log.info("Game paused. System Menu opened.", "UI")

## Resumes the game and hides system menu
func resume_game() -> void:
	if not is_instance_valid(pause_menu):
		return
	pause_menu.hide_menu()
	get_tree().paused = false
	paused_state_changed.emit(false)
	Log.info("Game resumed. System Menu closed.", "UI")

## Checks if the game is currently paused
func is_game_paused() -> bool:
	if is_instance_valid(pause_menu) and is_instance_valid(pause_menu.root_control):
		return pause_menu.root_control.visible
	return false

## Resets the current level: unpauses, resets data, and reloads level scene
func reset_level() -> void:
	if is_instance_valid(pause_menu):
		pause_menu.hide_menu()
	get_tree().paused = false
	var bd = get_node_or_null("/root/backslash_data")
	if is_instance_valid(bd):
		if bd.has_method("reset_save_data"):
			bd.reset_save_data()
		bd.set_val("current_level_path", "res://data/level_1.tres")
	transition_to_scene("res://scenes/main/level_player.tscn")

## Quits to main menu: unpauses and transitions to start menu scene
func quit_to_main_menu() -> void:
	if is_instance_valid(pause_menu):
		pause_menu.hide_menu()
	get_tree().paused = false
	transition_to_scene("res://scenes/start_menu/menu.tscn")

## Transition to a scene with a fullscreen fading black CanvasLayer transition.
func transition_to_scene(scene_path: String) -> void:
	# Create a programmatic fullscreen black fading canvas layer
	var canvas = CanvasLayer.new()
	canvas.layer = 100 # Put it on top of everything
	
	var rect = ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	
	# Add to root viewport so it persists across scene changes
	get_tree().root.add_child(canvas)
	
	# Smooth fade-in
	var tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(rect, "color", Color(0, 0, 0, 1), 0.5)
	
	# Wait for fade-in to complete
	await tween.finished
	
	# Change scene
	get_tree().change_scene_to_file(scene_path)
	
	# Smooth fade-out
	var tween_out = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_out.tween_property(rect, "color", Color(0, 0, 0, 0), 0.5)
	
	# Clean up overlay
	await tween_out.finished
	canvas.queue_free()

## Helper method to transition to victory screen.
func transition_to_win() -> void:
	transition_to_scene("res://scenes/victory_screen/victory_screen.tscn")

## Helper method to transition to game over/lose screen.
func transition_to_lose() -> void:
	transition_to_scene("res://scenes/game_over/game_over.tscn")
