# Backslash Button Addon

A high-fidelity custom button generator and texture slicer for **Godot 4.6+** projects. This addon standardizes UI buttons, adding responsive micro-animations and style consistency.

---

## Features

- **Micro-Animations**:
  - Automatically shifts label text down by `2` pixels on press down (`button_down` / `button_up` signals) for tactile feedback.
  - Hover/focus states trigger an elegant premium cyan font color shift (`Color(0.3, 0.8, 1.0)`).
- **Atlas-Based Slicing**: Slices raw `blank_button.png` into standard normal and pressed states at runtime.
- **Dynamic Label Setup**: Automatically updates internal Label child text nodes when the `@export var text` property is modified.

---

## Directory Structure

```
addons/backslash_button/
├── plugin.cfg          # Godot Editor addon metadata
├── plugin.gd           # EditorPlugin initializer registering autoload
├── button_core.gd      # Core autoload singleton managing button creation/preparation
├── custom_button.tscn  # Reusable custom button prefab
└── custom_button.gd    # Text label and micro-animation controller script
```

---

## Integration Guide

### 1. Enable the Autoload
Under **Project Settings > Globals**, add the Autoload mapping:
* **Name**: `BackslashButtonManager`
* **Path**: `res://addons/backslash_button/button_core.gd`

### 2. Standard API Usage

#### Programmatically Create a Button
Instantiate the custom button scene with specific label text:
```gdscript
var play_btn = BackslashButtonManager.create_button("PLAY GAME")
add_child(play_btn)
```

#### Prepare an Existing TextureButton
Slice and apply standard textures to an existing `TextureButton` in the scene tree:
```gdscript
@onready var texture_btn = $MenuButtons/SettingsButton
func _ready() -> void:
	BackslashButtonManager.prepare_button(texture_btn)
```
