# Backslash Audio Addon

A high-fidelity audio manager for **Godot 4.6+** projects. Structured as a global autoload singleton, it manages background music loops and exposes caching APIs to play sound effects concurrently using an `AudioStreamPlayer` voice pool.

---

## Features

- **Concurrent SFX Voices**: Dynamically allocates sound playback from a pre-configured voice pool (default 16 channels) to prevent newer sound effects from clipping active sounds.
- **Pre-Cache Audio Assets**: Pre-loads all required SFX and song WAV resources to eliminate disk read latency during active gameplay.
- **Robust Music Looping**: Programmatically loops WAV streams and connects fallback handlers to the `finished` signal to guarantee seamless music playback across scene transitions.
- **Centralized Volume & Persistence**: Provides clean decibel conversion for linear volume values (0.0 to 1.0) and automatically persists audio levels to the local JSON database via `backslash_data`.

---

## Directory Structure

```
addons/backslash_audio/
├── plugin.cfg          # Godot Editor addon metadata
├── plugin.gd           # EditorPlugin initializer registering autoload
├── audio_manager.gd     # Core autoload singleton managing music and SFX voices
└── README.md           # Technical documentation
```

---

## Integration Guide

### 1. Enable the Autoload
Under **Project Settings > Globals**, add the Autoload mapping:
* **Name**: `BackslashAudio`
* **Path**: `res://addons/backslash_audio/audio_manager.gd`

### 2. Standard API Usage

#### Playing Music
To start a looping music track (e.g., from `MUSIC_MAP` or a raw resource path):
```gdscript
BackslashAudio.play_music("drum") # Short name
BackslashAudio.play_music("res://audio/songs/drum.wav") # Direct path
```

#### Playing Sound Effects
To play a sound effect (e.g., from `SFX_MAP` or a raw resource path) dynamically:
```gdscript
BackslashAudio.play_sfx("PlayerOuch") # Short name
BackslashAudio.play_sfx("res://audio/sfx/EnemyOuch.wav") # Direct path
```

#### Adjusting Volume
Volume values are linear scales from `0.0` (mute) to `1.0` (maximum), which the manager converts to standard logarithmic decibel (dB) ranges:
```gdscript
# Set music volume to 50%
BackslashAudio.set_music_volume(0.5)

# Set SFX volume to 80%
BackslashAudio.set_sfx_volume(0.8)
```
Volume levels are automatically saved to disk via `backslash_data`.
