# Backslash Controls

A highly modular, unified, drop-in input component for **Godot 4.x** projects. It follows the **Component Pattern**, bundling mobile touchscreen overlays (virtual joystick and action buttons), hardware keyboards, and gamepads into a single, isolated module.

---

## Features

* **Drop-In Component**: Drag and drop `backslash_input.tscn` directly into your Player or Level scene tree. Zero configuration needed.
* **Unified API**: The player script queries a single simple method (`get_movement_vector()`) and listens to standard signals, ignoring the complexity of multiple input devices.
* **Smart Device Detection**: 
  * Automatically fades and hides the mobile touchscreen controls when keyboard or game controller inputs are active.
  * Seamlessly fades them back in when touch inputs are detected.
  * Prevents hidden nodes from capturing mouse or touch events during active desktop/gamepad play.
* **Smooth Transitions**: Built-in high-fidelity Tween animations handle responsive fading of control pads.
* **Adaptive Anchoring & Auto-Scaling**: Controls are anchored securely to bottom corners (bottom-left for joystick, bottom-right for action buttons). It automatically monitors viewport changes and dynamically scales the controls using custom pivot points, handling any display resolution or aspect ratio perfectly.
* **Pixel-Perfect Scaling Math**: Employs local coordinate transforms (`make_input_local(event)`) in the joystick, guaranteeing 100% accurate touch/drag tracking under any dynamic scale factor.
* **Ergonomic Circular Hitboxes**: Uses centered circular shapes (`CircleShape2D`) for all action buttons that are 10% smaller than the textures, paired with a slightly shrunk layout for tighter, more accurate touch registration.

---

## Structure & Naming

```
addons/backslash_controls/
├── joystick_base.png        # Outer joystick texture
├── joystick_knob.png        # Inner joystick knob texture
├── button_normal.png        # Action button default texture
├── button_pressed.png       # Action button pressed state texture
├── backslash_input.tscn     # Combined CanvasLayer scene
├── backslash_input.gd       # Root script (API & Show/Hide manager)
└── virtual_joystick.gd      # Touch dragging & math script
```

### Node Hierarchy

* **`CanvasLayer`** (`backslash_input.gd` — Layer 100 ensures overlay rendering)
  * **`VirtualJoystick`** (`virtual_joystick.gd` — Bottom-left anchored Control node)
	* `base` (TextureRect)
	* `knob` (TextureRect)
  * **`ActionPad`** (Control node — Bottom-right anchored Control node)
	* `action1` (TouchScreenButton mapped to `"action1"`)
	* `action2` (TouchScreenButton mapped to `"action2"`)
	* `menu` (TouchScreenButton mapped to `"menu"`)

---

## API Reference

### Signals

* `signal action1_triggered` — Emitted when `action1` (Space/J/Touch) is pressed.
* `signal action2_triggered` — Emitted when `action2` (Shift/K/Touch) is pressed.
* `signal menu_toggled` — Emitted when `menu` (Escape/Touch) is pressed.

### Methods

#### `get_movement_vector() -> Vector2`
Returns a normalized 2D vector (`Vector2.ZERO` to a clamped magnitude of `1.0`). If the mobile joystick is active, it returns the touchscreen direction. Otherwise, it defaults to the keyboard/gamepad vector.

---

## How to Use It in Your Game

### 1. Instantiate the Scene
Instantiate `backslash_input.tscn` as a child of your player:
```
Player (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
└── BackslashInput (backslash_input.tscn)
```

### 2. Connect Your Player Script
Update your Player script to poll movement and bind actions:

```gdscript
extends CharacterBody2D

@export var speed: float = 300.0
@onready var input: BackslashInput = $BackslashInput

func _ready() -> void:
	# Hook up action triggers
	input.action1_triggered.connect(_on_jump)
	input.action2_triggered.connect(_on_attack)
	input.menu_toggled.connect(_on_menu)

func _physics_process(_delta: float) -> void:
	# Poll unified Vector2 direction
	var move_dir = input.get_movement_vector()
	velocity = move_dir * speed
	move_and_slide()

func _on_jump() -> void:
	# Trigger jump mechanics
	pass

func _on_attack() -> void:
	# Trigger attack mechanics
	pass

func _on_menu() -> void:
	# Toggle menu UI
	pass
```

---

## Customization

* **Opacity Fade Duration**: Change `@export var fade_duration` in `backslash_input.gd`'s inspector to adjust animation speed.
* **Joystick Drag Radius**: Edit `@export var max_radius` in `virtual_joystick.gd`'s inspector to change how far the knob can be dragged from the center.
* **Dynamic Auto-Scaling**: Controls automatically scale relative to a baseline `648px` viewport height. The scale factor is safely clamped between `0.65` and `1.35`. Both controls utilize custom pivots (`pivot_offset` of `(0, 300)` for the joystick and `(300, 300)` for the action pad) to ensure scaling keeps elements locked to their respective bottom corners without drifting.
