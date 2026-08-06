@tool
extends TextureButton
class_name CustomButton

## Text label to display inside the button.
@export var text: String = "Button":
	set(val):
		text = val.strip_edges()
		_update_text()

func _ready() -> void:
	_setup_textures()
	_update_text()
	
	# Connect interaction signals for micro-animations
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	
	# Connect resized signal to dynamically scale font size
	resized.connect(_on_resized)
	_on_resized()

func _setup_textures() -> void:
	var path = "res://graphics/blank_button.png"
	if ResourceLoader.exists(path):
		var tex = load(path)
		if tex:
			var atlas_normal = AtlasTexture.new()
			atlas_normal.atlas = tex
			atlas_normal.region = Rect2(0, 0, 163, 40)
			
			var atlas_pressed = AtlasTexture.new()
			atlas_pressed.atlas = tex
			atlas_pressed.region = Rect2(163, 0, 163, 40)
			
			texture_normal = atlas_normal
			texture_pressed = atlas_pressed
			texture_hover = atlas_pressed
			texture_focused = atlas_pressed
		else:
			Log.error("Failed to load blank_button.png", "ButtonManager")
	else:
		Log.error("blank_button.png does not exist at: %s" % path, "ButtonManager")

func _update_text() -> void:
	var label = get_node_or_null("Label")
	if is_instance_valid(label):
		label.text = text

# Micro-animations: shift text downward by 2 pixels when button is depressed
func _on_button_down() -> void:
	var label = get_node_or_null("Label")
	if is_instance_valid(label):
		label.position.y = 2

func _on_button_up() -> void:
	var label = get_node_or_null("Label")
	if is_instance_valid(label):
		label.position.y = 0

# Hover / focus feedback color shifts
func _on_mouse_entered() -> void:
	var label = get_node_or_null("Label")
	if is_instance_valid(label):
		label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0)) # Premium cyan glow

func _on_mouse_exited() -> void:
	var label = get_node_or_null("Label")
	if is_instance_valid(label):
		label.remove_theme_color_override("font_color")

func _on_focus_entered() -> void:
	var label = get_node_or_null("Label")
	if is_instance_valid(label):
		label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))

func _on_focus_exited() -> void:
	var label = get_node_or_null("Label")
	if is_instance_valid(label):
		label.remove_theme_color_override("font_color")

## Dynamically scales the label's font size to keep it in visual ratio with the button's height.
func _on_resized() -> void:
	var label = get_node_or_null("Label")
	if is_instance_valid(label):
		# Default size of CustomButton is 80px height with 14px font.
		# Ratio: 14.0 / 80.0 = 0.175.
		var target_size = int(size.y * 0.175)
		target_size = clamp(target_size, 10, 36)
		label.add_theme_font_size_override("font_size", target_size)
