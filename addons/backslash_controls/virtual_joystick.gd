extends Control
class_name VirtualJoystick

@export var max_radius: float = 100.0
@export var return_speed: float = 20.0

@onready var base: TextureRect = $base
@onready var knob: TextureRect = $knob

var current_vector: Vector2 = Vector2.ZERO
var joystick_center: Vector2 = Vector2.ZERO
var touch_id: int = -1

## Suspends layout checks until the first rendering frame completes, then verifies child nodes
## and registers the default resting position and center coordinates for the radial boundaries.
func _ready() -> void:
	await get_tree().process_frame
	if base == null or knob == null:
		Log.error("Missing child base or knob TextureRect in VirtualJoystick", "Input")
		return
		
	joystick_center = base.position + (base.size / 2.0)
	_reset_knob()
	Log.info("VirtualJoystick initialized successfully. Center registered at: " + str(joystick_center), "Input")

## Receives screen touches, mapping positions to local space, allocating single-touch IDs,
## and triggering standard joystick drag sequences or resets.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var touch_pos = make_input_local(event).position
			if touch_id == -1 and touch_pos.distance_to(joystick_center) <= max_radius * 1.5:
				touch_id = event.index
				_update_joystick(touch_pos)
				Log.info("VirtualJoystick touch sequence initiated. touch_id allocated: " + str(touch_id), "Input")
		elif event.index == touch_id:
			_reset_joystick()
			Log.info("VirtualJoystick touch sequence released", "Input")
			
	elif event is InputEventScreenDrag:
		if event.index == touch_id:
			var touch_pos = make_input_local(event).position
			_update_joystick(touch_pos)

## Calculates offset distances from the center, clamping coordinates to the circular boundary max_radius,
## translating visual knob nodes, and normalizing vector results to [0, 1].
func _update_joystick(touch_pos: Vector2) -> void:
	var offset = touch_pos - joystick_center
	if offset.length() > max_radius:
		offset = offset.normalized() * max_radius
	
	if knob:
		knob.position = joystick_center + offset - (knob.size / 2.0)
		
	current_vector = offset / max_radius

## Resets active touch configurations, zeroes operational vectors, and centers the visual handle.
func _reset_joystick() -> void:
	touch_id = -1
	current_vector = Vector2.ZERO
	_reset_knob()

## Positions the visual knob exactly centered with the background base texture rect.
func _reset_knob() -> void:
	if knob:
		knob.position = joystick_center - (knob.size / 2.0)
