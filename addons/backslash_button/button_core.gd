extends Node

# Reference to the custom button prefab
const CUSTOM_BUTTON_SCENE = preload("res://addons/backslash_button/custom_button.tscn")

## Creates and returns a new CustomButton instance with the specified text.
func create_button(text_val: String = "") -> TextureButton:
	var btn = CUSTOM_BUTTON_SCENE.instantiate()
	btn.text = text_val.strip_edges()
	Log.info("Created custom button: '%s'" % btn.text, "ButtonManager")
	return btn

## Prepares an existing TextureButton by slicing and assigning the blank_button atlas textures.
func prepare_button(button: TextureButton) -> void:
	var path = "res://graphics/blank_button.png"
	if not ResourceLoader.exists(path):
		Log.error("Texture blank_button.png not found at: %s" % path, "ButtonManager")
		return
		
	var tex = load(path)
	if not tex:
		Log.error("Failed to load blank_button.png", "ButtonManager")
		return
		
	var atlas_normal = AtlasTexture.new()
	atlas_normal.atlas = tex
	atlas_normal.region = Rect2(0, 0, 163, 40)
	
	var atlas_pressed = AtlasTexture.new()
	atlas_pressed.atlas = tex
	atlas_pressed.region = Rect2(163, 0, 163, 40)
	
	button.texture_normal = atlas_normal
	button.texture_pressed = atlas_pressed
	button.texture_hover = atlas_pressed
	button.texture_focused = atlas_pressed
	
	Log.info("Prepared button '%s' with blank_button textures." % button.name, "ButtonManager")
