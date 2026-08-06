# Backslash Zoom Addon

An aspect-aware camera zoom manager for **Godot 4.6+** projects. Structured as a global autoload singleton, it standardizes camera view states across gameplay phases, responds to display resizing, and scales views dynamically for mobile/portrait screen layouts.

---

## Features

- **Centralized Zoom Configuration**: Utilizes a custom Godot `Resource` (`ZoomSettings`) defining distinct map-mode and gameplay-mode zoom ratios for landscape and portrait layouts.
- **Dynamic Orientation/Device Checking**: Automatically detects mobile operating systems or portrait window dimensions to switch between layouts.
- **Aspect Ratio Corrective Math**: Multiplies base zoom by an aspect-aware scale factor to fit the design aspect ratio (`16:9`) edge-to-edge on any custom display geometry.
- **Smooth Tweens**: Performs smooth, ease-out cubic transitions between zoom levels, automatically handling camera centering, top-level scene placement, and parent node tracking.
- **PhaseManager & Node Visibility Integration**: Hooks directly into `PhaseManager` signals to transition zoom levels when phases change. Automatically controls the visibility of players and totems in Map mode.

---

## Directory Structure

```
addons/backslash_zoom/
├── plugin.cfg          # Godot Editor addon metadata
├── plugin.gd           # EditorPlugin initializer registering autoload
├── zoom_manager.gd     # Core autoload singleton managing camera zoom and tweens
├── zoom_settings.gd    # Custom Resource script defining configuration properties
├── zoom_settings.tres  # Centralized master settings resource file
└── README.md           # Technical documentation
```

---

## Integration Guide

### 1. Enable the Autoload
Under **Project Settings > Globals**, add the Autoload mapping:
* **Name**: `BackslashZoom`
* **Path**: `res://addons/backslash_zoom/zoom_manager.gd`

### 2. Standard API Usage

#### Camera Registration
Attach a standard `Camera2D` to your player or level scene, and register it with the zoom manager in code:
```gdscript
func _ready() -> void:
	BackslashZoom.register_camera($Camera2D)
```

#### Change Zoom Modes
The zoom manager automatically listens to the global `PhaseManager` autoload, but you can also control zoom levels manually:
```gdscript
# Enable tactical map mode zoom (usually zooms out to map_zoom_landscape / 0.4)
BackslashZoom.set_map_mode(true)

# Return to standard active gameplay zoom (gameplay_zoom_landscape / 1.2)
BackslashZoom.set_map_mode(false)
```

### 3. Customizing Zoom Values
Edit `res://addons/backslash_zoom/zoom_settings.tres` in the Godot inspector to adjust the base zoom values for landscape/mobile views.
