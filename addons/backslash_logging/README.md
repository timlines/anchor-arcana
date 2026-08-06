# Backslash Logging Addon

A modular, high-fidelity logging system for **Godot 4.6+** projects. This addon provides unified local and remote logging, utilizing a standalone Google Apps Script and AppSheet proxy middleware backend.

---

## Features

- **Logging Duality Clause**: Guarantees zero local visibility reduction. All logs are printed immediately and synchronously to local standard output (`print()`) and standard error (`printerr()`), while concurrently being queued for remote transmission.
- **Unified Log Router**: Call `Log.info()`, `Log.warn()`, `Log.error()`, or `Log.debug()` from anywhere in the codebase.
- **Persistent Player ID**: Generates a unique user ID hash (e.g. `usr_a1b2c3d4`) on the first game boot, persisting it locally at `user://backslash_logging.cfg`.
- **Automatic Version Collection**: Dynamically reads the game version from Godot's project configurations (`application/config/version`), removing manual version tracking overhead.
- **Schema Compliance**: Packages all telemetry data automatically into a standard dictionary schema matching your Google Sheet/AppSheet columns.
- **Sequential Network Queue (Anti-DDoS)**: Rather than launching concurrent network requests, all logged events are queued in memory and transmitted *one at a time* in a controlled queue, protecting server-side endpoints from flooding.
- **Automatic Interval Flush**: Automatically flushes queued logs every 10 seconds or instantly once the queue hits 50 items.

---

## Directory Structure

```
addons/backslash_logging/
├── plugin.cfg         # Godot Editor addon metadata
├── plugin.gd          # EditorPlugin initializer registering autoload
├── logger_core.gd     # Core singleton logic
└── README.md          # Technical documentation
```

---

## Logging Duality Clause

To guarantee maximum visibility during local execution, debugging, and terminal automation, the logger enforces a **Duality Clause**:

1. **Immediate Local Logging (Synchronous & Unfiltered)**: Every log message is formatted and immediately output locally. `INFO` and `DEBUG` levels print to standard output via `print()`. `WARN` and `ERROR` levels print to standard error via `printerr()` and register in Godot's editor debugger via `push_warning()` and `push_error()`. This ensures that logs are fully visible in all platforms, headless configurations, and console pipes without reduction in visibility.
2. **Asynchronous Remote Delivery (Queued & Buffered)**: Simultaneously, the logs are packaged and appended to an in-memory queue, which is flushed sequentially to the remote server to prevent flooding.

---

## Standard Payload Schema

Every remote payload matches this JSON specification:

```json
{
  "secret": "super_secret_string_123",
  "timestamp": "2026-05-30T20:00:00Z",
  "level": "INFO",
  "category": "Player",
  "message": "Player triggered jump event",
  "session_id": "usr_a1b2c3d4_293847294",
  "version": "1.0.0"
}
```

---

## Integration Guide

### 1. Enable the Autoload
Under **Project Settings > Globals**, add an Autoload mapping:
* **Name**: `Log`
* **Path**: `res://addons/backslash_logging/logger_core.gd`

### 2. Standard API Usage

```gdscript
# Log a simple message under general category
Log.info("Game started successfully")

# Log with a specific functional category
Log.warn("Connection dropped, retrying...", "Network")

# Log critical application errors
Log.error("Failed to load starting_cards.json file", "IO")

# Log debugging indicators
Log.debug("Button pivot recalculated", "UI")
```

---

## Version Management

The system automatically collects the version string specified in your Godot Project Settings. 

### Setting Version via Godot Editor
1. Go to **Project > Project Settings**.
2. Navigate to **Application > Config**.
3. Under the **Version** property, enter your desired version string (e.g., `1.0.0`).
4. Click **Close**.

### Setting Version via `project.godot`
Alternatively, you can define or edit it directly inside your `project.godot` file under the `[application]` section:

```ini
[application]

config/version="1.2.3"
```

If no version string is defined in the configuration, the system automatically falls back to `"1.0.0"`.
