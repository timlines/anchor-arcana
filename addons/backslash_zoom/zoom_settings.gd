extends Resource
class_name ZoomSettings

## Centralized configuration profile for camera zoom metrics.
## Standardizes camera view states to exactly two zoom levels:
## 1. Map Zoom (0.4) - Used in PLAN phase and TACTICAL MAP mode.
## 2. Gameplay Zoom (1.2) - Used in all other scenes (PREPARE, DEFEND, VICTORY, DEFEAT).

@export_group("Landscape Zoom Levels (Desktop/Tablet)")
@export var map_zoom_landscape: float = 0.4
@export var gameplay_zoom_landscape: float = 1.2

@export_group("Mobile Zoom Levels (Portrait/Handheld)")
@export var map_zoom_mobile: float = 0.4
@export var gameplay_zoom_mobile: float = 1.2
