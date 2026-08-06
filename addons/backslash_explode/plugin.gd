@tool
extends EditorPlugin

## Lifecycle script for the Backslash Explode plugin.
## Registers the BackslashExplode autoload singleton on activation.

const AUTOLOAD_NAME = "BackslashExplode"
const AUTOLOAD_PATH = "res://addons/backslash_explode/explode_core.gd"


func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)


func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
