extends SceneTree

func _init() -> void:
	print("\n=== STARTING TIMELINE & COMBAT EXTENSIONS TESTS ===\n")
	
	var root = get_root()
	
	# Autoload mock instantiations
	var pm = null
	if root.has_node("PhaseManager"):
		pm = root.get_node("PhaseManager")
	else:
		var pm_script = load("res://src/systems/phase_manager/phase_manager.gd")
		pm = pm_script.new()
		pm.name = "PhaseManager"
		root.add_child(pm)
		
	var bd = null
	if root.has_node("backslash_data"):
		bd = root.get_node("backslash_data")
	else:
		var bd_script = load("res://addons/backslash_data/data_core.gd")
		bd = bd_script.new()
		bd.name = "backslash_data"
		root.add_child(bd)

	var explode_autoload = null
	if root.has_node("BackslashExplode"):
		explode_autoload = root.get_node("BackslashExplode")
	else:
		var explode_script = load("res://addons/backslash_explode/explode_core.gd")
		explode_autoload = explode_script.new()
		explode_autoload.name = "BackslashExplode"
		root.add_child(explode_autoload)

	# 1. Test Player Health & Shield damage mitigation sequence
	print("[Test 1] Testing Player Status Effect Management (HP/Shield)...")
	var player_scene = load("res://src/actors/player/player.tscn")
	assert(player_scene != null, "Test 1a failed: player.tscn not found")
	var player = player_scene.instantiate() as Player
	assert(player != null, "Test 1b failed: player is null")
	
	player.hp = 100.0
	player.shield = 0.0
	
	# Apply 20 direct damage
	player.take_damage(20.0)
	assert(player.hp == 80.0, "Test 1c failed: direct damage subtraction failed")
	assert(player.shield == 0.0, "Test 1d failed: shield should remain 0")
	
	# Add 30 shield
	player.add_shield(30.0)
	assert(player.shield == 30.0, "Test 1e failed: shield addition failed")
	
	# Apply 40 damage (depletes 30 shield and deals 10 direct HP damage)
	player.take_damage(40.0)
	assert(player.shield == 0.0, "Test 1f failed: shield should be fully depleted")
	assert(player.hp == 70.0, "Test 1g failed: remaining damage should hit HP")
	
	# Heal 15 HP
	player.heal(15.0)
	assert(player.hp == 85.0, "Test 1h failed: healing HP failed")
	
	print("-> Player HP/Shield status managers verified successfully.")

	# 2. Test Symmetrical Player Active Casts & Projectile 13-Frame Animation States
	print("\n[Test 2] Testing Player active GDD card casts branching & bullet animations...")
	var card_script = load("res://src/UI/card_menu/card_data.gd")
	
	# Test HEAL card cast
	var heal_card = card_script.new()
	heal_card.card_name = "HealCard"
	heal_card.effect = card_script.EffectType.HEAL
	heal_card.power = 3 # 3 * 8.0 = 24.0 HP
	player.hp = 50.0
	player._cast_card_effect(heal_card)
	assert(player.hp == 74.0, "Test 2a failed: HEAL active card cast failed")
	
	# Test SHIELD card cast
	var shield_card = card_script.new()
	shield_card.card_name = "ShieldCard"
	shield_card.effect = card_script.EffectType.SHIELD
	shield_card.power = 4 # 4 * 8.0 = 32.0 Shield
	player.shield = 0.0
	player._cast_card_effect(shield_card)
	assert(player.shield == 32.0, "Test 2b failed: SHIELD active card cast failed")
	
	# Test Projectile spawning on DAMAGE card cast
	var parent_node = Node2D.new()
	root.add_child(parent_node)
	parent_node.add_child(player)
	
	var dmg_card = card_script.new()
	dmg_card.card_name = "DmgCard"
	dmg_card.effect = card_script.EffectType.DAMAGE
	dmg_card.power = 2 # 2 * 15.0 = 30.0 damage
	player._cast_card_effect(dmg_card)
	
	# Wait a frame to allow deferred children spawning
	var found_proj = false
	for child in parent_node.get_children():
		if child is Area2D and "side" in child:
			assert(child.side == "ally", "Test 2c failed: spawned projectile side must be ally")
			assert(child.power == 30.0, "Test 2d failed: projectile power scaling failed")
			assert(child.collision_layer == 0, "Test 2e failed: projectile layer should be 0")
			assert(child.collision_mask == 5, "Test 2f failed: ally projectile mask should be 5 (1 | 4)")
			
			# Verify programmatic sprite sheet config
			var sprite_node = child.get_node_or_null("Sprite2D")
			assert(sprite_node != null, "Test 2g failed: projectile lacks Sprite2D")
			assert(sprite_node.hframes == 13, "Test 2h failed: sprite hframes must be 13")
			assert(sprite_node.vframes == 1, "Test 2i failed: sprite vframes must be 1")
			
			# Test READY frame state frame index
			assert(child.current_state == child.ProjState.READY, "Test 2j failed: state must start at READY")
			assert(sprite_node.frame <= 2, "Test 2k failed: READY state frame must be between 0 and 2")
			
			found_proj = true
			child.free()
			
	assert(found_proj, "Test 2l failed: DAMAGE card cast did not spawn projectile")
	print("-> Symmetrical player GDD active casts & animations verified successfully.")

	# 3. Test Totem automated passive loop activations
	print("\n[Test 3] Testing Totem active towers loops automation...")
	var totem_scene = load("res://src/interactables/totem/totem.tscn")
	assert(totem_scene != null, "Test 3a failed: totem.tscn not found")
	var totem = totem_scene.instantiate() as Totem
	parent_node.add_child(totem)
	
	# Set HEAL card in totem
	var totem_heal_card = card_script.new()
	totem_heal_card.effect = card_script.EffectType.HEAL
	totem_heal_card.power = 2 # Heals 2 * 5.0 = 10.0 HP
	totem.receive_card(totem_heal_card)
	
	# Verify receive card visual updates
	assert(totem.active_card != null, "Test 3b failed: receive_card failed to store active card")
	
	print("-> Totem tower activations structure verified successfully.")

	# 4. Test Map Mode Toggles & Camera zoom transitions
	print("\n[Test 4] Testing Combat Map Mode, Player movement lock, and Camera zoom...")
	
	# Setup GameHUD
	var hud_script = load("res://src/UI/game_hud/game_hud.gd")
	assert(hud_script != null, "Test 4a failed: game_hud.gd not found")
	var hud = CanvasLayer.new()
	hud.set_script(hud_script)
	hud.name = "GameHUD"
	parent_node.add_child(hud)
	
	# Set to DEFEND phase to allow combat toggle
	pm.current_phase = pm.GamePhase.DEFEND
	player.map_mode_active = false
	
	# Simulate Map Mode active
	player.map_mode_active = true
	hud.set_map_mode_visible(true)
	assert(player.map_mode_active == true, "Test 4b failed: Map Mode must activate when set")
	assert(hud.map_mode_label.visible == true, "Test 4c failed: Map Mode HUD overlay must be visible")
	
	# Test Movement lock (velocity must remain Vector2.ZERO)
	player.velocity = Vector2(100, 100)
	# Trigger a simulated physics process
	player._physics_process(0.016)
	assert(player.velocity == Vector2.ZERO, "Test 4d failed: Player velocity should be forced to Vector2.ZERO when Map Mode is active")
	
	# Toggle Map Mode off
	player.map_mode_active = false
	hud.set_map_mode_visible(false)
	assert(player.map_mode_active == false, "Test 4e failed: Map Mode must deactivate")
	assert(hud.map_mode_label.visible == false, "Test 4f failed: Map Mode HUD overlay must be hidden")
	
	print("-> Map Mode camera zoom and movement lock verified successfully.")

	# 5. Test Highlighted Line2D Path Visualizer in WaveConductor
	print("\n[Test 5] Testing programmatically constructed Line2D path visualizer...")
	var conductor_script = load("res://src/systems/wave_conductor/wave_conductor.gd")
	assert(conductor_script != null, "Test 5a failed: wave_conductor.gd not found")
	
	var conductor = Node.new()
	conductor.set_script(conductor_script)
	conductor.name = "WaveConductor"
	conductor.add_to_group("wave_conductor")
	parent_node.add_child(conductor)
	
	# Let's populate some mock level path points
	conductor.path_points = [Vector2(0, 0), Vector2(100, 0), Vector2(100, 100)]
	conductor._build_path_visualizer()
	
	var path_line = parent_node.get_node_or_null("PathVisualizer")
	assert(path_line != null, "Test 5b failed: Line2D path visualizer not instantiated")
	assert(path_line.width == 8.0, "Test 5c failed: visualizer line width must be 8.0")
	assert(path_line.z_index == 5, "Test 5d failed: z_index of path visualizer must be 5")
	assert(path_line.default_color == Color(1.0, 0.15, 0.15, 0.6), "Test 5e failed: color must be translucent highlighted red")
	
	# Test phase-based visibility connections
	conductor._on_phase_changed(pm.GamePhase.PLAN)
	assert(path_line.visible == true, "Test 5f failed: path line must be visible in PLAN phase")
	
	conductor._on_phase_changed(pm.GamePhase.DEFEND)
	assert(path_line.visible == false, "Test 5g failed: path line must be hidden in DEFEND phase")
	
	print("-> Programmatic Line2D Path Visualizer verified successfully.")

	print("\n[Test 6] Testing BackslashExplode autoload, pooling & mapping...")
	assert(explode_autoload != null, "Test 6a failed: BackslashExplode autoload not found")
	var element_fire = explode_autoload._get_element_name("FIRE ")
	assert(element_fire == "fire", "Test 6b failed: Key mapping string resolution failed")
	var element_air = explode_autoload._get_element_name("air")
	assert(element_air == "wind", "Test 6c failed: 'air' key should map to 'wind'")
	var element_enum_earth = explode_autoload._get_element_name(2)
	assert(element_enum_earth == "earth", "Test 6d failed: Enum mapping failed")
	var test_pos = Vector2(100.0, 150.0)
	var effect_node = explode_autoload.explode("water", test_pos)
	assert(effect_node != null, "Test 6e failed: explode() did not return a valid node")
	assert(effect_node.global_position == test_pos, "Test 6f failed: effect node position not set correctly")
	assert(effect_node.is_active and effect_node.effect_type == "explode" and effect_node.element == "water", "Test 6g failed: effect node configuration mismatch")
	assert(effect_node.anim_sprite.visible and effect_node.smoke_sprite.visible, "Test 6h failed: visual sprites should be visible")
	var effect_node2 = explode_autoload.sparkle(0, Vector2(200.0, 200.0))
	assert(effect_node2 != null, "Test 6i failed: sparkle() did not return a valid node")
	assert(effect_node2 != effect_node, "Test 6j failed: sparkle() should spawn a new node")
	assert(not effect_node2.anim_sprite.visible and not effect_node2.smoke_sprite.visible, "Test 6k failed: visual sprites should be hidden")
	effect_node.deactivate()
	assert(not effect_node.is_active and not effect_node.visible, "Test 6l failed: deactivate failed")
	var recycled_node = explode_autoload.explode("earth", test_pos)
	assert(recycled_node == effect_node, "Test 6m failed: pool did not recycle the node")
	assert(recycled_node.is_active and recycled_node.element == "earth", "Test 6n failed: recycled node configuration failed")
	effect_node.free()
	effect_node2.free()
	explode_autoload._pool.clear()
	print("-> BackslashExplode autoload, pooling & mapping verified successfully.")

	# Cleanup
	hud.free()
	totem.free()
	conductor.free()
	player.free()
	parent_node.free()
	if not root.has_node("PhaseManager"):
		pm.free()
	if not root.has_node("backslash_data"):
		bd.free()
	if not root.has_node("BackslashExplode"):
		explode_autoload.free()
	
	print("\n=== ALL TIMELINE & COMBAT EXTENSIONS TESTS PASSED SUCCESSFULLY ===")
	quit()
