extends Character

@export var speed: float = 300.0
@onready var input: BackslashInput = $BackslashInput

@export var acceleration: float = 8
@export var deceleration: float = 4
@onready var camera = $CameraController/Camera3D
@onready var skin = $PlayerSkin

func _ready() -> void:
	# Hook up action triggers
	input.action1_triggered.connect(_on_jump)
	input.action2_triggered.connect(_on_attack)
	input.menu_toggled.connect(_on_menu)

func _physics_process(delta: float) -> void:
	# Poll unified Vector3 direction
	move_logic(delta)
	jump_logic(delta)
	move_and_slide()
	
	
func move_logic(delta):
	movement_input = input.get_movement_vector().rotated(-camera.global_rotation.y)
	var vel_2d = Vector2(velocity.x, velocity.z)
	
	if movement_input != Vector2.ZERO:
		vel_2d += movement_input * base_speed * delta * acceleration
		vel_2d = vel_2d.limit_length(base_speed)
		velocity.x = vel_2d.x
		velocity.z = vel_2d.y
		var target_angle = -movement_input.angle() + PI / 2
		skin.rotation.y = rotate_toward(skin.rotation.y, target_angle, delta *  6)
		set_move_state('Running_A')
		
	else:
		vel_2d = vel_2d.move_toward(Vector2.ZERO, base_speed * delta * deceleration)
		velocity.x = vel_2d.x
		velocity.z = vel_2d.y
		set_move_state('Idle')
	
		
# handels being in the air (every frame)
func jump_logic(delta: float) -> void:
	if not is_on_floor():
		set_move_state('Jump_Idle')
	apply_gravity(jump_gravity if velocity.y > 0.0 else fall_gravity, delta)

#handles the moment of jumping (one-time trigger)
func _on_jump() -> void:
	if is_on_floor():
		velocity.y = -jump_velocity
		set_move_state('Jump_Idle')


func _on_attack() -> void:
	# Trigger attack mechanics
	pass

func _on_menu() -> void:
	# Toggle menu UI
	pass
