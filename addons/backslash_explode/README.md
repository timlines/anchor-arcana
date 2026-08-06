# Backslash Explode Addon

A high-performance 2D element explosion and particle sparkle manager for **Godot 4.6+** projects. This addon features an automatic memory-decoupled object pooling system to prevent runtime frame drops from repeated instantiation.

---

## Features

- **Element-Specific Effects**: Triggers unique particle/spritesheet feedback (animations, colors, styles) tailored to elemental types (`fire`, `wind`, `earth`, `water`).
- **Object Pooling**: Prepares and maintains an in-memory reusable pool of `ExplosionEffect` nodes to recycle resources without frequent allocations or garbage collection overhead.
- **Robust Key Translation**: Accepts both integer enums and case-insensitive string names for element keys (e.g. `"air"` is automatically mapped to `"wind"`).

---

## Directory Structure

```
addons/backslash_explode/
├── plugin.cfg           # Godot Editor addon metadata
├── plugin.gd            # EditorPlugin initializer registering autoload
├── explode_core.gd      # Core autoload singleton managing pool and API calls
└── explosion_effect.gd  # Sprite and CPUParticles2D wrapper logic
```

---

## Integration Guide

### 1. Enable the Autoload
Under **Project Settings > Globals**, add the Autoload mapping:
* **Name**: `BackslashExplode`
* **Path**: `res://addons/backslash_explode/explode_core.gd`

### 2. Standard API Usage

#### Spawn an Explosion
Play an explosion effect at a specific global position when an enemy is defeated or a projectile impacts:
```gdscript
# By String key (case-insensitive)
BackslashExplode.explode("fire", global_position)

# By Enum/Int key
BackslashExplode.explode(0, global_position)
```

#### Spawn a Sparkle
Play a lighter elemental sparkle effect:
```gdscript
BackslashExplode.sparkle("water", global_position)
```
