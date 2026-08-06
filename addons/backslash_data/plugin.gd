@tool
extends EditorPlugin

const AUTOLOAD_NAME = "backslash_data"
const AUTOLOAD_PATH = "res://addons/backslash_data/data_core.gd"

func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
