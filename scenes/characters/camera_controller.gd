extends SpringArm3D

@export var min_limit_x : float = -0.8
@export var max_limit_x : float = -0.2
@export var horizontal_acceleration : float = 2
@export var vertical_acceleration : float = 1
@export var mouse_acceleration : float = 0.005
@export var touch_acceleration: float = 0.005

var _touch_last_pos: Vector2 = Vector2.ZERO
var _touch_index: int = -1  # Track which finger is panning

func _process(delta: float) -> void:
	var joy_dir = Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
	var joy_dir_accelerated = joy_dir * delta * Vector2(horizontal_acceleration, vertical_acceleration)
	rotate_from_vector(joy_dir_accelerated)
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_dir_accelerated = event.relative * mouse_acceleration
		rotate_from_vector(mouse_dir_accelerated)

	elif event is InputEventScreenTouch:
		if event.pressed:
			# Only claim this finger if nothing else is panning yet
			if _touch_index == -1:
				_touch_index = event.index
				_touch_last_pos = event.position
		else:
			# Finger lifted — release if it was our pan finger
			if event.index == _touch_index:
				_touch_index = -1

	elif event is InputEventScreenDrag:
		# Only rotate if this is our designated pan finger
		if event.index == _touch_index:
			var delta_pos = event.position - _touch_last_pos
			rotate_from_vector(delta_pos * touch_acceleration)
			_touch_last_pos = event.position

func _ready() -> void:
	# Disable this so touch events don't ALSO fire as mouse events
	# causing double rotation
	ProjectSettings.set("input_devices/pointing/emulate_mouse_from_touch", false)
	_update_mouse_capture()
	
func rotate_from_vector(v: Vector2):
	if v.length() == 0 : return
	rotation.y -= v.x
	rotation.x -= v.y
	rotation.x = clamp(rotation.x, min_limit_x, max_limit_x)

#Capture Mouse input in the window
func _update_mouse_capture() -> void:
	var platform = OS.get_name()
	if not platform in ["Android", "iOS"]:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
