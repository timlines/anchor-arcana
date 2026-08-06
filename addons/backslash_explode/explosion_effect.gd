extends Node2D

## Visual instance for explosion and sparkle effects.
## Coordinates 3-frame animation sheets, expanding smoke clouds, and particle emissions.

var anim_sprite: Sprite2D = null
var smoke_sprite: Sprite2D = null
var particle_emitter: CPUParticles2D = null

var is_active: bool = false
var effect_type: String = "explode"
var element: String = "fire"

var _active_tweens: Array = []


func _ready() -> void:
	_build_components()


func _build_components() -> void:
	anim_sprite = Sprite2D.new()
	anim_sprite.name = "AnimSprite"
	anim_sprite.hframes = 3
	anim_sprite.vframes = 1
	add_child(anim_sprite)
	
	smoke_sprite = Sprite2D.new()
	smoke_sprite.name = "SmokeSprite"
	add_child(smoke_sprite)
	
	particle_emitter = CPUParticles2D.new()
	particle_emitter.name = "ParticleEmitter"
	add_child(particle_emitter)


func play_explode(element_name: String) -> void:
	is_active = true
	visible = true
	effect_type = "explode"
	element = element_name
	
	_clear_tweens()
	
	anim_sprite.texture = load("res://graphics/explosions/animations/" + element + "_exp_anim.png")
	anim_sprite.visible = true
	anim_sprite.frame = 0
	
	smoke_sprite.texture = load("res://graphics/explosions/smoke_cloud.png")
	smoke_sprite.visible = true
	smoke_sprite.modulate = _get_smoke_modulate(element)
	smoke_sprite.scale = Vector2(0.4, 0.4)
	
	particle_emitter.texture = load("res://graphics/explosions/particles/" + element + "_particle.png")
	_configure_particles_for_explode()
	particle_emitter.emitting = true
	
	var frame_tween = create_tween()
	_register_tween(frame_tween)
	frame_tween.tween_property(anim_sprite, "frame", 2, 0.24).set_trans(Tween.TRANS_LINEAR)
	frame_tween.tween_callback(func(): anim_sprite.visible = false)
	
	var smoke_scale_tween = create_tween()
	_register_tween(smoke_scale_tween)
	smoke_scale_tween.tween_property(smoke_sprite, "scale", Vector2(1.3, 1.3), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	var smoke_fade_tween = create_tween()
	_register_tween(smoke_fade_tween)
	smoke_sprite.modulate.a = 0.0
	smoke_fade_tween.tween_property(smoke_sprite, "modulate:a", 0.7, 0.08)
	smoke_fade_tween.tween_property(smoke_sprite, "modulate:a", 0.0, 0.42)
	
	var timer = get_tree().create_timer(0.6)
	timer.timeout.connect(_on_lifetime_timeout)


func play_sparkle(element_name: String) -> void:
	is_active = true
	visible = true
	effect_type = "sparkle"
	element = element_name
	
	_clear_tweens()
	
	anim_sprite.visible = false
	smoke_sprite.visible = false
	
	particle_emitter.texture = load("res://graphics/explosions/particles/" + element + "_particle.png")
	_configure_particles_for_sparkle()
	particle_emitter.emitting = true
	
	var timer = get_tree().create_timer(0.7)
	timer.timeout.connect(_on_lifetime_timeout)


func deactivate() -> void:
	is_active = false
	visible = false
	if particle_emitter:
		particle_emitter.emitting = false
	_clear_tweens()


func _clear_tweens() -> void:
	for t in _active_tweens:
		if t and t.is_valid():
			t.kill()
	_active_tweens.clear()


func _register_tween(t: Tween) -> void:
	_active_tweens.append(t)


func _on_lifetime_timeout() -> void:
	deactivate()


func _get_smoke_modulate(element_name: String) -> Color:
	match element_name:
		"fire":
			return Color(0.35, 0.25, 0.25, 0.7)
		"water":
			return Color(0.4, 0.55, 0.7, 0.6)
		"earth":
			return Color(0.45, 0.38, 0.3, 0.75)
		"wind":
			return Color(0.65, 0.7, 0.75, 0.6)
		_:
			return Color(0.5, 0.5, 0.5, 0.7)


func _configure_particles_for_explode() -> void:
	particle_emitter.amount = 12
	particle_emitter.one_shot = true
	particle_emitter.explosiveness = 0.9
	particle_emitter.lifetime = 0.5
	particle_emitter.spread = 180.0
	particle_emitter.direction = Vector2.ZERO
	particle_emitter.damping_min = 20.0
	particle_emitter.damping_max = 40.0
	
	match element:
		"fire":
			particle_emitter.gravity = Vector2(0, -60)
			particle_emitter.initial_velocity_min = 50.0
			particle_emitter.initial_velocity_max = 100.0
			particle_emitter.scale_amount_min = 0.6
			particle_emitter.scale_amount_max = 1.2
		"water":
			particle_emitter.gravity = Vector2(0, 40)
			particle_emitter.initial_velocity_min = 40.0
			particle_emitter.initial_velocity_max = 80.0
			particle_emitter.scale_amount_min = 0.5
			particle_emitter.scale_amount_max = 1.0
		"earth":
			particle_emitter.gravity = Vector2(0, 80)
			particle_emitter.initial_velocity_min = 30.0
			particle_emitter.initial_velocity_max = 70.0
			particle_emitter.scale_amount_min = 0.4
			particle_emitter.scale_amount_max = 0.9
		"wind":
			particle_emitter.gravity = Vector2.ZERO
			particle_emitter.initial_velocity_min = 60.0
			particle_emitter.initial_velocity_max = 110.0
			particle_emitter.scale_amount_min = 0.5
			particle_emitter.scale_amount_max = 1.1
			particle_emitter.damping_min = 30.0
			particle_emitter.damping_max = 50.0
			
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	particle_emitter.color_ramp = grad


func _configure_particles_for_sparkle() -> void:
	particle_emitter.amount = 8
	particle_emitter.one_shot = true
	particle_emitter.explosiveness = 0.2
	particle_emitter.lifetime = 0.6
	particle_emitter.damping_min = 5.0
	particle_emitter.damping_max = 10.0
	
	match element:
		"fire":
			particle_emitter.gravity = Vector2(0, -30)
			particle_emitter.spread = 45.0
			particle_emitter.direction = Vector2(0, -1)
			particle_emitter.initial_velocity_min = 20.0
			particle_emitter.initial_velocity_max = 40.0
			particle_emitter.scale_amount_min = 0.4
			particle_emitter.scale_amount_max = 0.8
		"water":
			particle_emitter.gravity = Vector2(0, 15)
			particle_emitter.spread = 90.0
			particle_emitter.direction = Vector2(0, 1)
			particle_emitter.initial_velocity_min = 15.0
			particle_emitter.initial_velocity_max = 30.0
			particle_emitter.scale_amount_min = 0.3
			particle_emitter.scale_amount_max = 0.7
		"earth":
			particle_emitter.gravity = Vector2(0, 20)
			particle_emitter.spread = 60.0
			particle_emitter.direction = Vector2(0, 1)
			particle_emitter.initial_velocity_min = 10.0
			particle_emitter.initial_velocity_max = 25.0
			particle_emitter.scale_amount_min = 0.3
			particle_emitter.scale_amount_max = 0.6
		"wind":
			particle_emitter.gravity = Vector2.ZERO
			particle_emitter.spread = 180.0
			particle_emitter.direction = Vector2.ZERO
			particle_emitter.initial_velocity_min = 25.0
			particle_emitter.initial_velocity_max = 50.0
			particle_emitter.scale_amount_min = 0.4
			particle_emitter.scale_amount_max = 0.8
			
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	particle_emitter.color_ramp = grad
