# Backslash Scene Addon

A dedicated scene and pause management subsystem for **Godot 4.6+** projects. This addon provides a reliable API to manage scene transitions with smooth screen fades, handle game pausing state dynamically, and manage the system/pause menu globally.

---

## Features

- **Centralized Pause Control**: Toggle, pause, or resume the game state globally, triggering a glassmorphic system menu.
- **Smooth Scene Transitions**: Fullscreen black canvas fade transitions on scene loads.
- **State Telemetry**: Emits a `paused_state_changed` signal when pausing/resuming.
- **Built-in Navigation**: Restart levels (with database reset support) or quit to the main start menu.

---

## Integration Guide

### 1. Enable the Autoload
Under **Project Settings > Globals**, add the Autoload mapping:
* **Name**: `BackslashScene`
* **Path**: `res://addons/backslash_scene/scene_manager.gd`

### 2. Standard API Usage

```gdscript
# Toggle the game pause state (e.g. on keyboard menu key)
BackslashScene.toggle_pause()

# Manually pause or resume
BackslashScene.pause_game()
BackslashScene.resume_game()

# Safe transitions to other scenes with smooth fades
BackslashScene.transition_to_scene("res://scenes/main/level_player.tscn")
BackslashScene.transition_to_win()
BackslashScene.transition_to_lose()
```
