extends Node

## Modular Audio Manager Autoload for background music looping and concurrent SFX playback.
## Name: BackslashAudio
## Depends on: Backslash Logging (Log), Backslash Data (backslash_data)

const SFX_MAP = {
	"EnemyOuch": "res://audio/sfx/EnemyOuch.wav",
	"Fire": "res://audio/sfx/Fire.wav",
	"FireBurn": "res://audio/sfx/FireBurn.wav",
	"Heal": "res://audio/sfx/Heal.wav",
	"PlayerOuch": "res://audio/sfx/PlayerOuch.wav",
	"Shield": "res://audio/sfx/Shield.wav"
}

const MUSIC_MAP = {
	"drum": "res://audio/songs/drum.mp3"
}

# Volume settings (0.0 to 1.0)
var music_volume: float = 0.7
var sfx_volume: float = 0.7

var music_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE = 16

# Cached AudioStream resources
var _cached_music: Dictionary = {}
var _cached_sfx: Dictionary = {}

var is_music_looping: bool = true
var current_music_path: String = ""
var _last_play_time: int = 0

func _ready() -> void:
	# Configure process mode to continue playing audio when paused
	process_mode = PROCESS_MODE_ALWAYS
	
	# Load volume preferences from backslash_data database
	_load_settings()
	
	# Initialize music player
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.process_mode = PROCESS_MODE_ALWAYS
	add_child(music_player)
	
	# Connect to finished signal for robust looping fallback
	music_player.finished.connect(_on_music_finished)
	
	# Initialize SFX player pool
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.process_mode = PROCESS_MODE_ALWAYS
		add_child(player)
		sfx_pool.append(player)
		
	# Pre-cache all SFX resources to prevent disk read stutters during gameplay
	for key in SFX_MAP:
		var path = SFX_MAP[key]
		var stream = load(path)
		if stream:
			_cached_sfx[key] = stream
			_cached_sfx[path] = stream
		else:
			Log.error("Failed to load SFX file: %s" % path, "Audio")
			
	# Pre-cache music resources
	for key in MUSIC_MAP:
		var path = MUSIC_MAP[key]
		var stream = load(path)
		if stream:
			_cached_music[key] = stream
			_cached_music[path] = stream
			print("[Audio Debug] Successfully pre-cached music: ", key, " -> ", path)
		else:
			print("[Audio Debug] Failed to pre-cache music: ", path)
			Log.error("Failed to load music file: %s" % path, "Audio")

	print("[Audio Debug] BackslashAudio manager successfully initialized. Default music: drum")
	Log.info("BackslashAudio manager successfully initialized with %d SFX channels." % SFX_POOL_SIZE, "Audio")
	
	# Automatically play default music loop on startup
	play_music("drum")

## Loads volume settings from backslash_data autoload database.
func _load_settings() -> void:
	if has_node("/root/backslash_data"):
		var bd = get_node("/root/backslash_data")
		music_volume = bd.get_val("music_volume", 0.7)
		sfx_volume = bd.get_val("sfx_volume", 0.7)
		Log.info("Loaded audio settings: Music=%.2f, SFX=%.2f" % [music_volume, sfx_volume], "Audio")
	else:
		Log.warn("backslash_data not found. Using default volumes.", "Audio")

## Saves volume settings to backslash_data autoload database.
func _save_settings() -> void:
	if has_node("/root/backslash_data"):
		var bd = get_node("/root/backslash_data")
		bd.set_val("music_volume", music_volume)
		bd.set_val("sfx_volume", sfx_volume)

## Plays background music by name (key in MUSIC_MAP) or direct path. Loops automatically.
func play_music(name_or_path: String, loop: bool = true) -> void:
	print("[Audio Debug] play_music called with name_or_path='%s', loop=%s" % [name_or_path, str(loop)])
	is_music_looping = loop
	
	var stream: AudioStream = null
	if _cached_music.has(name_or_path):
		stream = _cached_music[name_or_path]
		print("[Audio Debug] Found stream in _cached_music for '%s'" % name_or_path)
	elif MUSIC_MAP.has(name_or_path):
		var path = MUSIC_MAP[name_or_path]
		stream = _get_or_load_music(path)
		print("[Audio Debug] Resolved '%s' to MUSIC_MAP path '%s'" % [name_or_path, path])
	else:
		stream = _get_or_load_music(name_or_path)
		print("[Audio Debug] Direct path load attempt for '%s'" % name_or_path)
		
	if not stream:
		print("[Audio Debug] Cannot play music: stream not found or invalid: '%s'" % name_or_path)
		Log.error("Cannot play music: stream not found or invalid: %s" % name_or_path, "Audio")
		return
		
	# Skip if already playing this stream
	if music_player.playing and music_player.stream == stream:
		print("[Audio Debug] Music stream is already playing. Skipping replay.")
		return
		
	current_music_path = name_or_path
	music_player.stop()
	
	# Enable loop on WAV stream programmatically
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		if stream.loop_end == 0 or stream.loop_end == -1:
			var bytes_per_sample = 2 if stream.format == 1 else 1 # 1 is FORMAT_16_BITS
			var channels = 2 if stream.stereo else 1
			stream.loop_end = stream.data.size() / (bytes_per_sample * channels)
			print("[Audio Debug] Configured AudioStreamWAV looping mode. Calculated loop_end at runtime: %d samples." % stream.loop_end)
		else:
			print("[Audio Debug] Configured AudioStreamWAV looping mode (pre-baked loop_end: %d)." % stream.loop_end)
	elif "loop" in stream:
		stream.loop = true
		print("[Audio Debug] Configured generic AudioStream looping property.")
		
	music_player.stream = stream
	_apply_music_volume()
	_last_play_time = Time.get_ticks_msec()
	music_player.play()
	print("[Audio Debug] Started playing music player: playing=%s, volume_db=%f" % [str(music_player.playing), music_player.volume_db])
	Log.info("Now playing music track: %s" % name_or_path, "Audio")

func _get_or_load_music(path: String) -> AudioStream:
	if _cached_music.has(path):
		return _cached_music[path]
	var stream = load(path) as AudioStream
	if stream:
		_cached_music[path] = stream
		return stream
	return null

## Plays a sound effect by name (key in SFX_MAP) or direct path.
func play_sfx(name_or_path: String) -> void:
	var stream: AudioStream = null
	if _cached_sfx.has(name_or_path):
		stream = _cached_sfx[name_or_path]
	elif SFX_MAP.has(name_or_path):
		var path = SFX_MAP[name_or_path]
		stream = _get_or_load_sfx(path)
	else:
		stream = _get_or_load_sfx(name_or_path)
		
	if not stream:
		Log.error("Cannot play SFX: stream not found or invalid: %s" % name_or_path, "Audio")
		return
		
	var player = _get_available_sfx_player()
	if player:
		player.stream = stream
		_apply_player_sfx_volume(player)
		player.play()
	else:
		Log.warn("SFX pool exhausted! Dropping sound: %s" % name_or_path, "Audio")

func _get_or_load_sfx(path: String) -> AudioStream:
	if _cached_sfx.has(path):
		return _cached_sfx[path]
	var stream = load(path) as AudioStream
	if stream:
		_cached_sfx[path] = stream
		return stream
	return null

func _get_available_sfx_player() -> AudioStreamPlayer:
	# Find a player that isn't currently playing anything
	for player in sfx_pool:
		if not player.playing:
			return player
	# Fallback: steal the player that is furthest along in its playback
	var best_player = sfx_pool[0]
	var max_playback = 0.0
	for player in sfx_pool:
		var pos = player.get_playback_position()
		if pos > max_playback:
			max_playback = pos
			best_player = player
	return best_player

## Sets the music volume (0.0 = silent, 1.0 = maximum).
func set_music_volume(vol: float) -> void:
	music_volume = clamp(vol, 0.0, 1.0)
	_save_settings()
	_apply_music_volume()

## Sets the SFX volume (0.0 = silent, 1.0 = maximum).
func set_sfx_volume(vol: float) -> void:
	sfx_volume = clamp(vol, 0.0, 1.0)
	_save_settings()
	# Apply volume updates to all playing sound effect players
	for player in sfx_pool:
		if player.playing:
			_apply_player_sfx_volume(player)

## Gets the active music volume level (0.0 to 1.0).
func get_music_volume() -> float:
	return music_volume

## Gets the active SFX volume level (0.0 to 1.0).
func get_sfx_volume() -> float:
	return sfx_volume

func _apply_music_volume() -> void:
	if is_instance_valid(music_player):
		if music_volume > 0.0:
			music_player.volume_db = linear_to_db(music_volume)
		else:
			music_player.volume_db = -80.0

func _apply_player_sfx_volume(player: AudioStreamPlayer) -> void:
	if is_instance_valid(player):
		if sfx_volume > 0.0:
			player.volume_db = linear_to_db(sfx_volume)
		else:
			player.volume_db = -80.0

func _on_music_finished() -> void:
	print("[Audio Debug] _on_music_finished signal received. is_music_looping=%s" % str(is_music_looping))
	if is_music_looping and is_instance_valid(music_player) and music_player.stream:
		var now = Time.get_ticks_msec()
		if now - _last_play_time < 500:
			print("[Audio Debug] Loop blocked: stream finished too quickly (%d ms). Likely headless or null audio driver." % (now - _last_play_time))
			return
		_last_play_time = now
		music_player.play()
		print("[Audio Debug] Re-started finished music stream loop.")
