# Backslash Icon Addon

An elemental vector icon display manager for **Godot 4.6+** projects. This addon provides a centralized API to fetch element icons with smart caching and a custom `@tool` node for editing and displaying icons in the editor and at runtime.

---

## Features

- **Centralized Asset Mapping**: Automatically maps elemental types (`fire`, `air`/`wind`, `earth`, `water`) to their respective graphic file paths.
- **Resource Caching**: Prevents reloading textures from disk by keeping loaded `Texture2D` objects in a memory cache.
- **Custom Tool Node (`ElementIcon`)**: An inspector-integrated `TextureRect` node that dynamically previews selected element icons inside the editor.

---

## Directory Structure

```
addons/backslash_icon/
├── plugin.cfg        # Godot Editor addon metadata
├── plugin.gd         # EditorPlugin initializer registering autoload
├── icon_core.gd      # Core autoload singleton managing icon fetching and cache
└── element_icon.gd   # Custom tool-enabled TextureRect control node
```

---

## Integration Guide

### 1. Enable the Autoload
Under **Project Settings > Globals**, add the Autoload mapping:
* **Name**: `BackslashIcon`
* **Path**: `res://addons/backslash_icon/icon_core.gd`

### 2. Standard API Usage

#### Fetching Icons via Code
Retrieve a cached texture to assign to a sprite or UI component:
```gdscript
# By String key (case-insensitive)
var fire_tex = BackslashIcon.get_icon("fire")

# By Enum/Int key
var water_tex = BackslashIcon.get_icon(3)
```

#### Placing the Tool Node
Add `ElementIcon` to your scene trees:
1. Click **Add Node** and choose `ElementIcon` (or add a `TextureRect` and attach `res://addons/backslash_icon/element_icon.gd`).
2. In the inspector, set the **Element Type** enum property to switch between `FIRE`, `AIR`, `EARTH`, and `WATER`.
