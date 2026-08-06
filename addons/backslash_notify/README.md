# Backslash Notify Addon

A standardized, responsive UI notification overlay system for **Godot 4.6+** projects. Structured as a clean `CanvasLayer` EditorPlugin autoload, it provides premium glassmorphism notification banners and interactive multiple-choice question overlays.

---

## Features

- **Programmatic Glassmorphism UI**: Draws beautiful translucent banners with glowing metallic borders, rounded corners, and dynamic layout scaling without the need for visual texture files.
- **Auto-Dismissal & Manual Dismissal**: Supports timer-based auto-dismissal and physical/virtual input dismissal (binds to the unified `action1` action key).
- **Riddle/Question Mode**: Displays multiple-choice questions with keyboard/joystick navigation. Dynamically instantiates custom action buttons via the `BackslashButtonManager` autoload.
- **Signals**:
  - `notification_completed` — Emitted when a notification completes or is dismissed.
  - `question_completed(is_correct: bool)` — Emitted after a player selects an answer.

---

## Directory Structure

```
addons/backslash_notify/
├── plugin.cfg         # Godot Editor addon metadata
├── plugin.gd          # EditorPlugin initializer registering autoload
├── notify_core.gd     # Core CanvasLayer autoload singleton containing UI generation and APIs
└── README.md          # Technical documentation
```

---

## Integration Guide

### 1. Enable the Autoload
Under **Project Settings > Globals**, add the Autoload mapping:
* **Name**: `BackslashNotify`
* **Path**: `res://addons/backslash_notify/notify_core.gd`

### 2. Standard API Usage

#### Presenting a Toast Notification
```gdscript
# Simple text toast with auto-dismiss in 3 seconds
BackslashNotify.notify("Level Cleared!")

# Toast with a custom icon texture and custom duration
var reward_icon = load("res://graphics/cards/fire_reward.png")
BackslashNotify.notify("New card unlocked!", reward_icon, 5.0)
```

#### Asking a Multiple-Choice Question
```gdscript
# Present a riddle in-game
BackslashNotify.ask_question(
	"What element extinguishes fire?",
	["Earth", "Air", "Water"],
	2 # Correct answer is option index 2 ("Water")
)

# Connect to the response signal
BackslashNotify.question_completed.connect(func(is_correct: bool):
	if is_correct:
		print("Player answered correctly!")
	else:
		print("Player answered incorrectly.")
)
```
