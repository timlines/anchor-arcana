# Backslash Data Addon

A unified, persistent local storage and mathematical delta adjustment subsystem for **Godot 4.6+** projects. This addon provides a reliable API to manage save states, load level configurations, and update numeric properties safely, integrated directly with modular custom error logging.

---

## Features

- **Automated Local Serialization**: Save states are persisted automatically to `user://save_data.json` as JSON strings.
- **Dynamic Delta Adjustment**: Safely adjust numerical keys (e.g. coin counts, high scores) using floats, integers, or signed strings (e.g. `"+10"`, `"-5.5"`).
- **Standardized Configuration Reader**: Safely load and parse game databases, starting card decks, or level JSON specifications (`read_file()` / `readFile()`).
- **Self-Contained Error Tracing**: Catches and formats error tracebacks, reporting failed file operations, invalid calculations, or parsing errors directly to standard error output and the `Log` autoload.

---

## Integration Guide

### 1. Enable the Autoload
Under **Project Settings > Globals**, add the Autoload mapping:
* **Name**: `backslash_data`
* **Path**: `res://addons/backslash_data/data_core.gd`

### 2. Standard API Usage

```gdscript
# Set player score to start state
backslash_data.set("score", 0)

# Adjust numerical score on enemy kill
backslash_data.adjust("score", "+10")
backslash_data.adjust("score", -5)

# Read level configurations recursively from res://resources/
var level_data = backslash_data.read_file("data/level_1.json")

# Retrieve safe values from memory
var active_score = backslash_data.get_val("score", 0)

# Wipe key or overwrite save state with a parsed JSON string
backslash_data.clear("score")
backslash_data.clear("", '{"score": 500, "coins": 20}')
```
