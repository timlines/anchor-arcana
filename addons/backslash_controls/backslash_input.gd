extends CanvasLayer
class_name BackslashInput

signal action1_triggered
signal action2_triggered
signal menu_toggled

@onready var joystick: Control = $VirtualJoystick
@onready var action_pad: Control = $ActionPad

@export var fade_duration: float = 0.25

var _is_mobile_ui_visible: bool = true
var _fade_tween: Tween

## Sets up the BackslashInput layer, performs initialization checks on required child nodes,
## detects the operating system, adjusts initial mobile controls visibility,
## and connects viewport resizing listeners for dynamic scaling.
func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if joystick == null or action_pad == null:
		Log.error("Critical: VirtualJoystick or ActionPad node not found in BackslashInput scene tree", "Input")
		return
		
	var platform = OS.get_name()
	Log.info("Initializing BackslashInput layout. Operating system platform detected: " + platform, "Input")
	
	if platform in ["Android", "iOS"]:
		_set_mobile_ui_visible(true, true)
	else:
		_set_mobile_ui_visible(false, true)
	
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()

## Listens for unified game action triggers on physical buttons (keyboard/controllers)
## and emits corresponding signals to listening actors.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("action1"):
		action1_triggered.emit()
	if Input.is_action_just_pressed("action2"):
		action2_triggered.emit()
	if Input.is_action_just_pressed("menu"):
		menu_toggled.emit()

## Monitors input events, automatically toggling the touchscreen mobile overlay on touch signals
## and hiding it when keyboard/gamepad actions or active analog joysticks are used.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_set_mobile_ui_visible(true)
	elif event is InputEventKey or event is InputEventJoypadButton:
		_set_mobile_ui_visible(false)
	elif event is InputEventJoypadMotion:
		if abs(event.axis_value) > 0.25:
			_set_mobile_ui_visible(false)

## Smoothly animates the visibility and opacity of the touch overlay using dynamic tweens,
## ensuring input processing is disabled for fully transparent controls to prevent capturing mouse drags.
func _set_mobile_ui_visible(visible_state: bool, instant: bool = false) -> void:
	if _is_mobile_ui_visible == visible_state and not instant:
		return
	
	Log.info("Transitioning mobile virtual controls visibility to: " + str(visible_state), "Input")
	_is_mobile_ui_visible = visible_state
	
	if _fade_tween:
		_fade_tween.kill()
		
	var target_alpha = 1.0 if visible_state else 0.0
	
	if instant:
		joystick.modulate.a = target_alpha
		action_pad.modulate.a = target_alpha
		joystick.visible = visible_state
		action_pad.visible = visible_state
	else:
		if visible_state:
			joystick.visible = true
			action_pad.visible = true
		
		_fade_tween = create_tween().set_parallel(true)
		_fade_tween.tween_property(joystick, "modulate:a", target_alpha, fade_duration)
		_fade_tween.tween_property(action_pad, "modulate:a", target_alpha, fade_duration)
		
		if not visible_state:
			_fade_tween.set_parallel(false)
			_fade_tween.tween_callback(func():
				joystick.visible = false
				action_pad.visible = false
			)

## Exposes a unified normalized 2D movement vector, seamlessly prioritizing active
## touch joystick dragging vectors when visible, or falling back to raw keyboard/controller axis inputs.
func get_movement_vector() -> Vector2:
	var hardware_dir = Input.get_vector("left", "right", "forward", "backward")
	
	if _is_mobile_ui_visible and joystick.current_vector != Vector2.ZERO:
		return joystick.current_vector
		
	return hardware_dir

## Updates the Action 1 touchscreen button texture normal to show card artwork/element
func set_action1_image(texture: Texture2D) -> void:
	if not is_inside_tree():
		return
	var action1 = action_pad.get_node_or_null("action1") as TouchScreenButton
	if is_instance_valid(action1):
		if texture != null:
			action1.texture_normal = texture
			action1.texture_pressed = null
		else:
			# Fallback to defaults
			action1.texture_normal = load("res://addons/backslash_controls/button_normal.png")
			action1.texture_pressed = load("res://addons/backslash_controls/button_pressed.png")

## Dynamically scales the virtual controls relative to a 648px design height baseline,
## clamping the factor between 0.65x and 1.35x to keep controls readable and clear on any display density.
func _update_layout() -> void:
	if not is_inside_tree():
		return
		
	var viewport_size = get_viewport().get_visible_rect().size
	if viewport_size.y <= 0:
		return
		
	var scale_factor = viewport_size.y / 648.0
	scale_factor = clamp(scale_factor, 0.65, 1.35)
	
	if joystick:
		joystick.scale = Vector2(scale_factor, scale_factor)
		joystick.anchor_left = 0.0
		joystick.anchor_right = 0.0
		joystick.anchor_top = 1.0
		joystick.anchor_bottom = 1.0
		
		# Spacing from bottom-left corner calculated based on viewport percentage
		var margin_x = viewport_size.x * 0.04
		var margin_y = viewport_size.y * 0.06
		margin_x = clamp(margin_x, 20.0, 80.0)
		margin_y = clamp(margin_y, 20.0, 80.0)
		
		# Position the 300x300 container using the margins
		joystick.offset_left = margin_x
		joystick.offset_bottom = -margin_y
		joystick.offset_right = margin_x + 300.0
		joystick.offset_top = -margin_y - 300.0
		
		joystick.pivot_offset = Vector2(0, 300)
		
	if action_pad:
		action_pad.scale = Vector2(scale_factor, scale_factor)
		action_pad.anchor_left = 1.0
		action_pad.anchor_right = 1.0
		action_pad.anchor_top = 1.0
		action_pad.anchor_bottom = 1.0
		
		# Spacing from bottom-right corner calculated based on viewport percentage
		var margin_x = viewport_size.x * 0.04
		var margin_y = viewport_size.y * 0.06
		margin_x = clamp(margin_x, 20.0, 80.0)
		margin_y = clamp(margin_y, 20.0, 80.0)
		
		# Position the 300x300 container using the margins
		action_pad.offset_left = -margin_x - 300.0
		action_pad.offset_bottom = -margin_y
		action_pad.offset_right = -margin_x
		action_pad.offset_top = -margin_y - 300.0
		
		action_pad.pivot_offset = Vector2(300, 300)
