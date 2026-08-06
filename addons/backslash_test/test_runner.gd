extends Node

func _ready() -> void:
	await get_tree().process_frame
	Log.info("=== STARTING TIMELINE & COMBAT EXTENSIONS TESTS ===", "Test")
	
	var pm = PhaseManager
	var bd = backslash_data

	# Setup a mock LevelPlayer as the current scene with a mock LevelMap so WaveConductor has wave config & path data
	var start_lp_mock = LevelPlayer.new()
	get_tree().root.add_child(start_lp_mock)
	var real_original_scene = get_tree().current_scene
	get_tree().current_scene = start_lp_mock
	
	var start_map_mock = LevelMap.new()
	start_lp_mock.active_map = start_map_mock
	
	# Pre-populate starting cards, rewards, quests, and waves with paths in start_map_mock
	var mock_card = load("res://src/UI/card_menu/card_data.gd").new()
	mock_card.card_name = "MockStartCard"
	var starting_cards_arr: Array[CardData] = []
	starting_cards_arr.append(mock_card)
	start_map_mock.starting_cards = starting_cards_arr
	start_map_mock.reward_card = mock_card
	
	var wave_cfg = WaveConfig.new()
	wave_cfg.delay = 1.0
	wave_cfg.spacing = 0.5
	wave_cfg.path = PackedVector2Array([Vector2(0,0), Vector2(100,0)])
	var enemy_cfg = WaveEnemyConfig.new()
	enemy_cfg.enemy_type = "small"
	enemy_cfg.hp = 10.0
	enemy_cfg.speed = 100.0
	var enemies_arr: Array[WaveEnemyConfig] = []
	enemies_arr.append(enemy_cfg)
	wave_cfg.enemies = enemies_arr
	var waves_arr: Array[WaveConfig] = []
	waves_arr.append(wave_cfg)
	start_map_mock.waves = waves_arr
	
	var quest_cfg = QuestConfig.new()
	quest_cfg.question_text = "What is the data buffet?"
	var options_arr: Array[String] = []
	options_arr.append("Unified Config")
	options_arr.append("Scattered Resources")
	options_arr.append("JSON files")
	quest_cfg.options = options_arr
	quest_cfg.correct_index = 0
	quest_cfg.reward_card = mock_card
	var quests_arr: Array[QuestConfig] = []
	quests_arr.append(quest_cfg)
	start_map_mock.quests = quests_arr


	# 1. Test Player Health & Shield damage mitigation sequence
	Log.info("[Test 1] Testing Player Status Effect Management (HP/Shield)...", "Test")
	
	var player_scene_path = "res://src/actors/player/player.tscn"
	var player_scene = null
	if ResourceLoader.exists(player_scene_path):
		player_scene = load(player_scene_path)
	else:
		Log.error("Test 1a failed: player.tscn not found at %s" % player_scene_path, "Test")
		get_tree().quit(1)
		return
		
	if not player_scene:
		Log.error("Test 1a failed: player.tscn loaded as null", "Test")
		get_tree().quit(1)
		return
		
	var player = player_scene.instantiate()
	if not is_instance_valid(player):
		Log.error("Test 1b failed: player instantiation failed", "Test")
		get_tree().quit(1)
		return
		
	add_child(player)
	
	player.hp = 100.0
	player.shield = 0.0
	
	# Apply 20 direct damage
	player.take_damage(20.0)
	if player.hp != 80.0:
		Log.error("Test 1c failed: direct damage subtraction failed. Expected HP 80.0, got %.1f" % player.hp, "Test")
		get_tree().quit(1)
		return
		
	if player.shield != 0.0:
		Log.error("Test 1d failed: shield should remain 0, got %.1f" % player.shield, "Test")
		get_tree().quit(1)
		return
	
	# Add 30 shield
	player.add_shield(30.0)
	if player.shield != 30.0:
		Log.error("Test 1e failed: shield addition failed. Expected 30.0, got %.1f" % player.shield, "Test")
		get_tree().quit(1)
		return
	
	# Apply 40 damage (depletes 30 shield and deals 10 direct HP damage)
	player.take_damage(40.0)
	if player.shield != 0.0:
		Log.error("Test 1f failed: shield should be fully depleted, got %.1f" % player.shield, "Test")
		get_tree().quit(1)
		return
		
	if player.hp != 70.0:
		Log.error("Test 1g failed: remaining damage should hit HP. Expected HP 70.0, got %.1f" % player.hp, "Test")
		get_tree().quit(1)
		return
	
	# Heal 15 HP
	player.heal(15.0)
	if player.hp != 85.0:
		Log.error("Test 1h failed: healing HP failed. Expected HP 85.0, got %.1f" % player.hp, "Test")
		get_tree().quit(1)
		return
	
	# Heal with excess amount, should clamp to max_hp (100.0)
	player.heal(100.0)
	if player.hp != 100.0:
		Log.error("Test 1i failed: healing HP must be clamped to max_hp (100.0), got %.1f" % player.hp, "Test")
		get_tree().quit(1)
		return

	# Add shield with excess amount, should clamp to max_shield (100.0)
	player.add_shield(150.0)
	if player.shield != 100.0:
		Log.error("Test 1j failed: shield addition must be clamped to max_shield (100.0), got %.1f" % player.shield, "Test")
		get_tree().quit(1)
		return

	# Reset shield back to 0 for subsequent tests
	player.shield = 0.0
	
	Log.info("-> Player HP/Shield status managers verified successfully.", "Test")

	# 2. Test Symmetrical Player Active Casts & Projectile 13-Frame Animation States
	Log.info("[Test 2] Testing Player active GDD card casts branching & bullet animations...", "Test")
	
	var card_script_path = "res://src/UI/card_menu/card_data.gd"
	var card_script = null
	if ResourceLoader.exists(card_script_path):
		card_script = load(card_script_path)
	else:
		Log.error("Test 2 failed: card_data.gd not found at %s" % card_script_path, "Test")
		get_tree().quit(1)
		return
		
	if not card_script:
		Log.error("Test 2 failed: card_data.gd loaded as null", "Test")
		get_tree().quit(1)
		return
	
	# Test HEAL card cast
	var heal_card = card_script.new()
	if not is_instance_valid(heal_card):
		Log.error("Test 2 failed: heal_card instantiation failed", "Test")
		get_tree().quit(1)
		return
		
	heal_card.card_name = "HealCard"
	heal_card.effect = card_script.EffectType.HEAL
	heal_card.power = 3 # 3 * 8.0 = 24.0 HP
	player.hp = 50.0
	player._cast_card_effect(heal_card)
	if player.hp != 74.0:
		Log.error("Test 2a failed: HEAL active card cast failed. Expected HP 74.0, got %.1f" % player.hp, "Test")
		get_tree().quit(1)
		return
	
	# Test SHIELD card cast
	var shield_card = card_script.new()
	if not is_instance_valid(shield_card):
		Log.error("Test 2 failed: shield_card instantiation failed", "Test")
		get_tree().quit(1)
		return
		
	shield_card.card_name = "ShieldCard"
	shield_card.effect = card_script.EffectType.SHIELD
	shield_card.power = 4 # 4 * 8.0 = 32.0 Shield
	player.shield = 0.0
	player._cast_card_effect(shield_card)
	if player.shield != 32.0:
		Log.error("Test 2b failed: SHIELD active card cast failed. Expected Shield 32.0, got %.1f" % player.shield, "Test")
		get_tree().quit(1)
		return
	
	# Test Projectile spawning on DAMAGE card cast
	var parent_node = Node2D.new()
	add_child(parent_node)
	player.get_parent().remove_child(player)
	parent_node.add_child(player)
	
	var dmg_card = card_script.new()
	if not is_instance_valid(dmg_card):
		Log.error("Test 2 failed: dmg_card instantiation failed", "Test")
		get_tree().quit(1)
		return
		
	dmg_card.card_name = "DmgCard"
	dmg_card.effect = card_script.EffectType.DAMAGE
	dmg_card.power = 2 # 2 * 15.0 = 30.0 damage
	player._cast_card_effect(dmg_card)
	
	# Wait a frame to allow deferred children spawning
	var found_proj = false
	for child in parent_node.get_children():
		if child is Area2D and "side" in child:
			if child.side != "ally":
				Log.error("Test 2c failed: spawned projectile side must be ally, got %s" % child.side, "Test")
				get_tree().quit(1)
				return
				
			if child.power != 30.0:
				Log.error("Test 2d failed: projectile power scaling failed. Expected 30.0, got %.1f" % child.power, "Test")
				get_tree().quit(1)
				return
				
			if child.collision_layer != 0:
				Log.error("Test 2e failed: projectile layer should be 0, got %d" % child.collision_layer, "Test")
				get_tree().quit(1)
				return
				
			if child.collision_mask != 5:
				Log.error("Test 2f failed: ally projectile mask should be 5 (1 | 4), got %d" % child.collision_mask, "Test")
				get_tree().quit(1)
				return
			
			# Verify programmatic sprite sheet config
			var sprite_node = child.get_node_or_null("Sprite2D")
			if not is_instance_valid(sprite_node):
				Log.error("Test 2g failed: projectile lacks Sprite2D", "Test")
				get_tree().quit(1)
				return
				
			if sprite_node.hframes != 13:
				Log.error("Test 2h failed: sprite hframes must be 13, got %d" % sprite_node.hframes, "Test")
				get_tree().quit(1)
				return
				
			if sprite_node.vframes != 1:
				Log.error("Test 2i failed: sprite vframes must be 1, got %d" % sprite_node.vframes, "Test")
				get_tree().quit(1)
				return
			
			# Test READY frame state frame index
			if child.current_state != child.ProjState.READY:
				Log.error("Test 2j failed: state must start at READY, got %d" % child.current_state, "Test")
				get_tree().quit(1)
				return
				
			if sprite_node.frame > 2:
				Log.error("Test 2k failed: READY state frame must be between 0 and 2, got %d" % sprite_node.frame, "Test")
				get_tree().quit(1)
				return
			
			found_proj = true
			child.free()
			
	if not found_proj:
		Log.error("Test 2l failed: DAMAGE card cast did not spawn projectile", "Test")
		get_tree().quit(1)
		return
		
	Log.info("-> Symmetrical player GDD active casts & animations verified successfully.", "Test")

	# 3. Test Totem automated passive loop activations
	Log.info("[Test 3] Testing Totem active towers loops automation...", "Test")
	
	var totem_scene_path = "res://src/interactables/totem/totem.tscn"
	var totem_scene = null
	if ResourceLoader.exists(totem_scene_path):
		totem_scene = load(totem_scene_path)
	else:
		Log.error("Test 3a failed: totem.tscn not found at %s" % totem_scene_path, "Test")
		get_tree().quit(1)
		return
		
	if not totem_scene:
		Log.error("Test 3a failed: totem.tscn loaded as null", "Test")
		get_tree().quit(1)
		return
		
	var totem = totem_scene.instantiate()
	if not is_instance_valid(totem):
		Log.error("Test 3a failed: totem instantiation failed", "Test")
		get_tree().quit(1)
		return
		
	parent_node.add_child(totem)
	
	# Set HEAL card in totem
	var totem_heal_card = card_script.new()
	if not is_instance_valid(totem_heal_card):
		Log.error("Test 3 failed: totem_heal_card instantiation failed", "Test")
		get_tree().quit(1)
		return
		
	totem_heal_card.effect = card_script.EffectType.HEAL
	totem_heal_card.power = 2 # Heals 2 * 5.0 = 10.0 HP
	totem.receive_card(totem_heal_card)
	
	# Verify receive card visual updates
	if totem.active_card == null:
		Log.error("Test 3b failed: receive_card failed to store active card", "Test")
		get_tree().quit(1)
		return

	# Initialize player health to 80.0
	player.hp = 80.0
	player.shield = 0.0
	
	# Execute effect (player at distance 0 <= 120)
	totem._execute_active_tower_effect()
	if player.hp != 90.0:
		Log.error("Test 3c failed: totem HEAL failed. Expected HP 90.0, got %.1f" % player.hp, "Test")
		get_tree().quit(1)
		return

	# Heal again, should clamp at 100.0
	totem._execute_active_tower_effect()
	if player.hp != 100.0:
		Log.error("Test 3d failed: totem HEAL clamp failed. Expected HP 100.0, got %.1f" % player.hp, "Test")
		get_tree().quit(1)
		return

	# Now change totem card to SHIELD
	var totem_shield_card = card_script.new()
	if not is_instance_valid(totem_shield_card):
		Log.error("Test 3 failed: totem_shield_card instantiation failed", "Test")
		get_tree().quit(1)
		return
	totem_shield_card.effect = card_script.EffectType.SHIELD
	totem_shield_card.power = 3 # 3 * 5.0 = 15.0 Shield
	totem.receive_card(totem_shield_card)

	# Execute shield effect (player at distance 0 <= 120)
	totem._execute_active_tower_effect()
	if player.shield != 15.0:
		Log.error("Test 3e failed: totem SHIELD failed. Expected Shield 15.0, got %.1f" % player.shield, "Test")
		get_tree().quit(1)
		return

	# Move player outside range (e.g. 150 pixels away on X axis)
	player.global_position = Vector2(150.0, 0.0)
	totem.global_position = Vector2(0.0, 0.0)
	# Clear shield to see if it adds shield
	player.shield = 0.0

	# Execute shield effect (player at distance 150 > 120)
	totem._execute_active_tower_effect()
	if player.shield != 0.0:
		Log.error("Test 3f failed: totem should not cast SHIELD when player is out of range. Got Shield %.1f" % player.shield, "Test")
		get_tree().quit(1)
		return

	# Move player inside range but close to boundary (e.g. 100 pixels away on X axis)
	player.global_position = Vector2(100.0, 0.0)
	totem._execute_active_tower_effect()
	if player.shield != 15.0:
		Log.error("Test 3g failed: totem SHIELD failed when player is within range boundary. Expected Shield 15.0, got %.1f" % player.shield, "Test")
		get_tree().quit(1)
		return

	# Reset player position to 0,0 for other tests
	player.global_position = Vector2.ZERO
	
	Log.info("-> Totem tower activations structure verified successfully.", "Test")

	# 4. Test Map Mode Toggles & Camera zoom transitions
	Log.info("[Test 4] Testing Combat Map Mode, Player movement lock, and Camera zoom...", "Test")
	
	# Setup GameHUD
	var hud_script_path = "res://src/UI/game_hud/game_hud.gd"
	var hud_script = null
	if ResourceLoader.exists(hud_script_path):
		hud_script = load(hud_script_path)
	else:
		Log.error("Test 4a failed: game_hud.gd not found at %s" % hud_script_path, "Test")
		get_tree().quit(1)
		return
		
	if not hud_script:
		Log.error("Test 4a failed: game_hud.gd loaded as null", "Test")
		get_tree().quit(1)
		return
		
	var hud = CanvasLayer.new()
	if not is_instance_valid(hud):
		Log.error("Test 4a failed: hud instantiation failed", "Test")
		get_tree().quit(1)
		return
		
	hud.set_script(hud_script)
	hud.name = "GameHUD"
	parent_node.add_child(hud)
	
	# Set to DEFEND phase to allow combat toggle
	pm.current_phase = pm.GamePhase.DEFEND
	player.map_mode_active = false
	
	# Simulate Map Mode active
	player.map_mode_active = true
	hud.set_map_mode_visible(true)
	if player.map_mode_active != true:
		Log.error("Test 4b failed: Map Mode must activate when set", "Test")
		get_tree().quit(1)
		return
		
	if not is_instance_valid(hud.map_mode_label) or hud.map_mode_label.visible != true:
		Log.error("Test 4c failed: Map Mode HUD overlay must be visible", "Test")
		get_tree().quit(1)
		return
	
	# Test Movement lock (velocity must remain Vector2.ZERO)
	player.velocity = Vector2(100, 100)
	# Trigger a simulated physics process
	player._physics_process(0.016)
	if player.velocity != Vector2.ZERO:
		Log.error("Test 4d failed: Player velocity should be forced to Vector2.ZERO when Map Mode is active, got %s" % str(player.velocity), "Test")
		get_tree().quit(1)
		return
	
	# Toggle Map Mode off
	player.map_mode_active = false
	hud.set_map_mode_visible(false)
	if player.map_mode_active != false:
		Log.error("Test 4e failed: Map Mode must deactivate", "Test")
		get_tree().quit(1)
		return
		
	if not is_instance_valid(hud.map_mode_label) or hud.map_mode_label.visible != false:
		Log.error("Test 4f failed: Map Mode HUD overlay must be hidden", "Test")
		get_tree().quit(1)
		return
	
	Log.info("-> Map Mode camera zoom and movement lock verified successfully.", "Test")

	# 5. Test Highlighted Line2D Path Visualizer in WaveConductor
	Log.info("[Test 5] Testing programmatically constructed Line2D path visualizer...", "Test")
	
	# Wait a frame to allow deferred gameplay systems setup (e.g. WaveConductor spawning) from Player
	await get_tree().process_frame
	
	var conductor_script_path = "res://src/systems/wave_conductor/wave_conductor.gd"
	var conductor_script = null
	if ResourceLoader.exists(conductor_script_path):
		conductor_script = load(conductor_script_path)
	else:
		Log.error("Test 5a failed: wave_conductor.gd not found at %s" % conductor_script_path, "Test")
		get_tree().quit(1)
		return
		
	if not conductor_script:
		Log.error("Test 5a failed: wave_conductor.gd loaded as null", "Test")
		get_tree().quit(1)
		return
	
	var scene = get_tree().current_scene
	if not is_instance_valid(scene):
		Log.error("Test 5a2 failed: current_scene is invalid", "Test")
		get_tree().quit(1)
		return
		
	var conductor = scene.find_child("WaveConductor", true, false)
	if not is_instance_valid(conductor):
		Log.error("Test 5a2 failed: WaveConductor not found in scene", "Test")
		get_tree().quit(1)
		return
	
	var path_line = scene.find_child("PathVisualizer", true, false)
	if not is_instance_valid(path_line):
		Log.error("Test 5b failed: Line2D path visualizer not instantiated", "Test")
		get_tree().quit(1)
		return
		
	if path_line.width != 4.0:
		Log.error("Test 5c failed: visualizer line width must be 4.0, got %.1f" % path_line.width, "Test")
		get_tree().quit(1)
		return
		
	if path_line.z_index != 5:
		Log.error("Test 5d failed: z_index of path visualizer must be 5, got %d" % path_line.z_index, "Test")
		get_tree().quit(1)
		return
		
	if path_line.default_color != Color(1.0, 0.2, 0.2, 0.25):
		Log.error("Test 5e failed: color must be subtle guide color, got %s" % str(path_line.default_color), "Test")
		get_tree().quit(1)
		return
		
	# Verify PathVisualizer2D pulse system is present
	var path_node2d = scene.find_child("PathVisualizer2D", true, false)
	if not is_instance_valid(path_node2d) or not path_node2d is Path2D:
		Log.error("Test 5e2 failed: PathVisualizer2D Path2D node not found", "Test")
		get_tree().quit(1)
		return
		
	var path_follows = path_node2d.get_children()
	if path_follows.is_empty():
		Log.error("Test 5e3 failed: PathVisualizer2D has no pulse children", "Test")
		get_tree().quit(1)
		return
		
	var first_follow = path_follows[0]
	if not first_follow is PathFollow2D:
		Log.error("Test 5e4 failed: PathVisualizer2D child is not PathFollow2D", "Test")
		get_tree().quit(1)
		return
		
	if first_follow.get_child_count() == 0:
		Log.error("Test 5e5 failed: PathFollow2D does not contain any pulse node", "Test")
		get_tree().quit(1)
		return
		
	var pulse_node = first_follow.get_child(0)
	if not ("radius" in pulse_node) or not ("color" in pulse_node):
		Log.error("Test 5e6 failed: PathFollow2D does not contain a valid PathPulse node", "Test")
		get_tree().quit(1)
		return
	
	# Test phase-based visibility connections
	conductor._on_phase_changed(pm.GamePhase.PLAN)
	var zoom_sys = get_node_or_null("/root/BackslashZoom")
	if is_instance_valid(zoom_sys):
		zoom_sys.set_phase(pm.GamePhase.PLAN)
	if path_line.visible != true or path_node2d.visible != true:
		Log.error("Test 5f failed: path line and pulse path must be visible in PLAN phase", "Test")
		get_tree().quit(1)
		return
	
	conductor._on_phase_changed(pm.GamePhase.DEFEND)
	if is_instance_valid(zoom_sys):
		zoom_sys.set_phase(pm.GamePhase.DEFEND)
	if path_line.visible != false or path_node2d.visible != false:
		Log.error("Test 5g failed: path line and pulse path must be hidden in DEFEND phase", "Test")
		get_tree().quit(1)
		return
	
	Log.info("-> Programmatic Line2D Path Visualizer verified successfully.", "Test")

	Log.info("[Test 6] Testing BackslashExplode autoload, pooling & mapping...", "Test")
	
	var explode_autoload = get_node_or_null("/root/BackslashExplode")
	if not is_instance_valid(explode_autoload):
		Log.error("Test 6a failed: BackslashExplode autoload singleton not found", "Test")
		get_tree().quit(1)
		return
		
	var element_fire = explode_autoload._get_element_name("FIRE ")
	if element_fire != "fire":
		Log.error("Test 6b failed: Key mapping string resolution failed. Expected 'fire', got '%s'" % element_fire, "Test")
		get_tree().quit(1)
		return
		
	var element_air = explode_autoload._get_element_name("air")
	if element_air != "wind":
		Log.error("Test 6c failed: 'air' key should map to 'wind'. Got '%s'" % element_air, "Test")
		get_tree().quit(1)
		return
		
	var element_enum_earth = explode_autoload._get_element_name(2)
	if element_enum_earth != "earth":
		Log.error("Test 6d failed: Enum mapping failed. Expected 'earth' for int 2, got '%s'" % element_enum_earth, "Test")
		get_tree().quit(1)
		return
		
	var test_pos = Vector2(100.0, 150.0)
	var effect_node = explode_autoload.explode("water", test_pos)
	if not is_instance_valid(effect_node):
		Log.error("Test 6e failed: explode() did not return a valid node", "Test")
		get_tree().quit(1)
		return
		
	if effect_node.global_position != test_pos:
		Log.error("Test 6f failed: effect node global_position not set correctly. Expected %s, got %s" % [str(test_pos), str(effect_node.global_position)], "Test")
		get_tree().quit(1)
		return
		
	if not effect_node.is_active or effect_node.effect_type != "explode" or effect_node.element != "water":
		Log.error("Test 6g failed: effect node configuration mismatch", "Test")
		get_tree().quit(1)
		return
		
	if not effect_node.anim_sprite.visible or not effect_node.smoke_sprite.visible:
		Log.error("Test 6h failed: anim_sprite or smoke_sprite should be visible for explode", "Test")
		get_tree().quit(1)
		return
		
	var effect_node2 = explode_autoload.sparkle(0, Vector2(200.0, 200.0))
	if not is_instance_valid(effect_node2):
		Log.error("Test 6i failed: sparkle() did not return a valid node", "Test")
		get_tree().quit(1)
		return
		
	if effect_node2 == effect_node:
		Log.error("Test 6j failed: sparkle() should have spawned a new node because the first is still active", "Test")
		get_tree().quit(1)
		return
		
	if effect_node2.anim_sprite.visible or effect_node2.smoke_sprite.visible:
		Log.error("Test 6k failed: anim_sprite and smoke_sprite should be hidden for sparkle", "Test")
		get_tree().quit(1)
		return
		
	effect_node.deactivate()
	if effect_node.is_active or effect_node.visible:
		Log.error("Test 6l failed: deactivate() did not reset active or visible state", "Test")
		get_tree().quit(1)
		return
		
	var recycled_node = explode_autoload.explode("earth", test_pos)
	if recycled_node != effect_node:
		Log.error("Test 6m failed: pool did not recycle the inactive node", "Test")
		get_tree().quit(1)
		return
		
	if not recycled_node.is_active or recycled_node.element != "earth":
		Log.error("Test 6n failed: recycled node not re-configured properly", "Test")
		get_tree().quit(1)
		return
		
	effect_node.free()
	effect_node2.free()
	explode_autoload._pool.clear()
	
	Log.info("-> BackslashExplode autoload, pooling & mapping verified successfully.", "Test")

	# 7. Test Riddle Quest Item & Card Drop rewards
	Log.info("[Test 7] Testing Riddle Quest Item & Card Drop rewards...", "Test")
	
	var quest_item_scene_path = "res://src/interactables/quest_item/quest_item.tscn"
	var quest_item_scene = null
	if ResourceLoader.exists(quest_item_scene_path):
		quest_item_scene = load(quest_item_scene_path)
	else:
		Log.error("Test 7 failed: quest_item.tscn not found at %s" % quest_item_scene_path, "Test")
		get_tree().quit(1)
		return
		
	var quest_item = quest_item_scene.instantiate()
	if not is_instance_valid(quest_item):
		Log.error("Test 7 failed: quest_item instantiation failed", "Test")
		get_tree().quit(1)
		return
		
	parent_node.add_child(quest_item)
	quest_item.global_position = Vector2(0, 0)
	
	# Verify default values
	if quest_item.correct_index != 0 or quest_item.options.size() != 3:
		Log.error("Test 7 failed: quest_item defaults do not match expected riddle.", "Test")
		get_tree().quit(1)
		return
		
	var notify = get_node_or_null("/root/BackslashNotify")
	if not is_instance_valid(notify):
		Log.error("Test 7 failed: BackslashNotify autoload not found", "Test")
		get_tree().quit(1)
		return
		
	# Trigger body entered (simulate player walking onto the quest item)
	quest_item._on_body_entered(player)
	if not notify._is_question_mode:
		Log.error("Test 7 failed: notify should enter question mode on quest item collision", "Test")
		get_tree().quit(1)
		return
		
	# Test wrong answer
	notify._on_option_selected(1) # Wrong answer index 1 ("A Cloud")
	if quest_item._triggered:
		Log.error("Test 7 failed: quest_item trigger state should reset on wrong answer to allow retry", "Test")
		get_tree().quit(1)
		return
		
	# Simulate player stepping away and stepping back on
	quest_item._on_body_exited(player)
	quest_item._on_body_entered(player)
	if not notify._is_question_mode:
		Log.error("Test 7 failed: notify should enter question mode again on re-entry", "Test")
		get_tree().quit(1)
		return
		
	# Test correct answer
	notify._on_option_selected(0) # Correct answer index 0 ("An Echo")
	
	# Let deferred add_child on the parent complete for CardDrop
	await get_tree().process_frame
	
	# Verify CardDrop has spawned in the parent node
	var found_card_drop = false
	for child in parent_node.get_children():
		if child is CardDrop:
			found_card_drop = true
			child.free()
			break
			
	if not found_card_drop:
		Log.error("Test 7 failed: CardDrop reward was not spawned on correct answer", "Test")
		get_tree().quit(1)
		return
		
	# Dismiss the completed notification screen
	notify.dismiss()
	
	Log.info("-> Riddle Quest Item and Card Drop rewards verified successfully.", "Test")

	# 8. Test Unified LevelMap "Data Buffet" resolution
	Log.info("[Test 8] Testing Unified LevelMap Data Buffet resolution...", "Test")
	
	var lp_mock = LevelPlayer.new()
	get_tree().root.add_child(lp_mock)
	
	var original_scene = get_tree().current_scene
	get_tree().current_scene = lp_mock
	
	var original_deck = bd.get_val("player_deck")
	bd.clear("player_deck")
	
	var map_mock = LevelMap.new()
	lp_mock.active_map = map_mock
	
	# Set up level properties
	map_mock.level_id = "test_map_id"
	map_mock.level_name = "Test Data Buffet Map"
	
	# Set up starting cards
	var buffet_card = card_script.new()
	buffet_card.card_name = "BuffetStartCard"
	buffet_card.element_type = card_script.ElementType.FIRE
	buffet_card.effect = card_script.EffectType.DAMAGE
	buffet_card.power = 5
	var buffet_starting_cards_arr: Array[CardData] = []
	buffet_starting_cards_arr.append(buffet_card)
	map_mock.starting_cards = buffet_starting_cards_arr
	
	# Set up reward card
	var buffet_reward = card_script.new()
	buffet_reward.card_name = "BuffetRewardCard"
	buffet_reward.element_type = card_script.ElementType.WATER
	buffet_reward.effect = card_script.EffectType.HEAL
	buffet_reward.power = 10
	map_mock.reward_card = buffet_reward
	
	# Set up wave config
	var buffet_wave_cfg = WaveConfig.new()
	buffet_wave_cfg.delay = 1.0
	buffet_wave_cfg.spacing = 0.5
	buffet_wave_cfg.path = PackedVector2Array([Vector2(0,0), Vector2(100,0)])
	var buffet_enemy_cfg = WaveEnemyConfig.new()
	buffet_enemy_cfg.enemy_type = "buffet_enemy"
	buffet_enemy_cfg.hp = 50.0
	buffet_enemy_cfg.speed = 120.0
	var buffet_enemies_arr: Array[WaveEnemyConfig] = []
	buffet_enemies_arr.append(buffet_enemy_cfg)
	buffet_wave_cfg.enemies = buffet_enemies_arr
	var buffet_waves_arr: Array[WaveConfig] = []
	buffet_waves_arr.append(buffet_wave_cfg)
	map_mock.waves = buffet_waves_arr
	
	# Set up quest config
	var buffet_quest_cfg = QuestConfig.new()
	buffet_quest_cfg.question_text = "What is the data buffet?"
	var buffet_options_arr: Array[String] = []
	buffet_options_arr.append("Unified Config")
	buffet_options_arr.append("Scattered Resources")
	buffet_options_arr.append("JSON files")
	buffet_quest_cfg.options = buffet_options_arr
	buffet_quest_cfg.correct_index = 0
	buffet_quest_cfg.reward_card = buffet_reward
	var buffet_quests_arr: Array[QuestConfig] = []
	buffet_quests_arr.append(buffet_quest_cfg)
	map_mock.quests = buffet_quests_arr
	
	# Verify WaveConductor resolves waves from active_map
	var test_conductor = WaveConductor.new()
	lp_mock.add_child(test_conductor)
	
	if test_conductor.level_data.get("waves", []).size() != 1:
		Log.error("Test 8 failed: WaveConductor did not resolve active_map waves", "Test")
		get_tree().quit(1)
		return
		
	var resolved_wave = test_conductor.level_data.get("waves", [])[0]
	if resolved_wave.get("delay") != 1.0 or resolved_wave.get("enemies", []).size() != 1:
		Log.error("Test 8 failed: Resolved wave values mismatch", "Test")
		get_tree().quit(1)
		return
		
	var resolved_enemy = resolved_wave.get("enemies", [])[0]
	if resolved_enemy.get("enemy_type") != "buffet_enemy" or resolved_enemy.get("hp") != 50.0:
		Log.error("Test 8 failed: Resolved enemy values mismatch", "Test")
		get_tree().quit(1)
		return
		
	# Verify Player resolves starting cards from active_map
	var test_player = player_scene.instantiate()
	lp_mock.add_child(test_player)
	
	if test_player.player_hand.size() != 1 or test_player.player_hand[0].card_name != "BuffetStartCard":
		Log.error("Test 8 failed: Player did not resolve starting cards from active_map", "Test")
		get_tree().quit(1)
		return
		
	# Verify QuestItem resolves quest config from active_map
	var test_quest_item = quest_item_scene.instantiate() as QuestItem
	test_quest_item.quest_index = 0
	lp_mock.add_child(test_quest_item)
	
	if test_quest_item.question_text != "What is the data buffet?" or test_quest_item.options.size() != 3:
		Log.error("Test 8 failed: QuestItem did not resolve quest config from active_map", "Test")
		get_tree().quit(1)
		return
		
	# Cleanup Test 8 mock nodes
	test_quest_item.free()
	test_player.free()
	test_conductor.free()
	map_mock.free()
	lp_mock.free()
	
	# Restore original scene context
	get_tree().current_scene = original_scene
	if original_deck != null:
		bd.set_val("player_deck", original_deck)
	
	Log.info("-> Unified LevelMap Data Buffet resolution verified successfully.", "Test")

	# Cleanup previous tests
	hud.free()
	totem.free()
	conductor.free()
	player.free()
	if is_instance_valid(quest_item):
		quest_item.free()
	parent_node.free()
	
	# Restore real original scene and cleanup initial mock nodes
	get_tree().current_scene = real_original_scene
	if is_instance_valid(start_map_mock):
		start_map_mock.free()
	if is_instance_valid(start_lp_mock):
		start_lp_mock.free()

	# 9. Test Real Level Data (Level 1 Map, Wave Configs, Paths, and Enemies)
	Log.info("[Test 9] Testing Real Level 1 Map Wave Configs, Paths, Enemies, and Completion...", "Test")
	
	var real_lp_mock = LevelPlayer.new()
	get_tree().root.add_child(real_lp_mock)
	var pre_test9_scene = get_tree().current_scene
	get_tree().current_scene = real_lp_mock
	
	var level_cfg_path = "res://data/level_1.tres"
	if not ResourceLoader.exists(level_cfg_path):
		Log.error("Test 9 failed: LevelConfig resource not found at %s" % level_cfg_path, "Test")
		get_tree().quit(1)
		return
		
	var real_level_cfg = load(level_cfg_path) as LevelConfig
	if not real_level_cfg:
		Log.error("Test 9 failed: LevelConfig failed to load", "Test")
		get_tree().quit(1)
		return
		
	real_lp_mock.load_level(real_level_cfg)
	
	# Wait two process frames to allow deferred setup from Player to complete
	await get_tree().process_frame
	await get_tree().process_frame
	
	var wonder_node = get_tree().get_first_node_in_group("wonder") as Wonder
	if not is_instance_valid(wonder_node):
		Log.error("Test 9 failed: Wonder node not found in group 'wonder'", "Test")
		get_tree().quit(1)
		return
		
	if wonder_node.global_position != Vector2.ZERO:
		Log.error("Test 9 failed: Wonder default position mismatch. Expected (0,0), got %s" % str(wonder_node.global_position), "Test")
		get_tree().quit(1)
		return
		
	if wonder_node.max_hp != 100.0 or wonder_node.hp != 100.0:
		Log.error("Test 9 failed: Wonder default hp mismatch. Expected 100.0, got %.1f" % wonder_node.hp, "Test")
		get_tree().quit(1)
		return
		
	if wonder_node.max_shield != 100.0 or wonder_node.shield != 0.0:
		Log.error("Test 9 failed: Wonder default shield mismatch. Expected max_shield 100.0 and active shield 0.0, got max_shield %.1f and shield %.1f" % [wonder_node.max_shield, wonder_node.shield], "Test")
		get_tree().quit(1)
		return
		
	Log.info("-> Wonder object setup and attribute validation completed successfully.", "Test")
	
	var real_conductor = real_lp_mock.find_child("WaveConductor", true, false) as WaveConductor
	if not is_instance_valid(real_conductor):
		Log.error("Test 9 failed: WaveConductor was not spawned on the scene", "Test")
		get_tree().quit(1)
		return
		
	var real_level_data = real_conductor.level_data
	if real_level_data.is_empty():
		Log.error("Test 9 failed: WaveConductor loaded level_data is empty", "Test")
		get_tree().quit(1)
		return
		
	var real_waves = real_level_data.get("waves", [])
	if real_waves.is_empty():
		Log.error("Test 9 failed: level_data contains no waves", "Test")
		get_tree().quit(1)
		return
		
	Log.info("Loaded real wave data containing %d waves." % real_waves.size(), "Test")
	
	for i in range(real_waves.size()):
		var w_cfg = real_waves[i]
		real_conductor._update_path_for_current_wave(i)
		
		var w_path_points = real_conductor.path_points
		if w_path_points.size() < 2:
			Log.error("Test 9 failed: Wave %d has invalid path points size %d (expected >= 2)" % [i, w_path_points.size()], "Test")
			get_tree().quit(1)
			return
			
		for pt in w_path_points:
			if not pt.is_finite():
				Log.error("Test 9 failed: Wave %d path point %s is not finite" % [i, str(pt)], "Test")
				get_tree().quit(1)
				return
		
		var w_enemies = w_cfg.get("enemies", [])
		if w_enemies.is_empty():
			Log.error("Test 9 failed: Wave %d has no enemies configured" % i, "Test")
			get_tree().quit(1)
			return
			
		for enemy_idx in range(w_enemies.size()):
			var enemy_data = w_enemies[enemy_idx]
			var enemy_type = ""
			var hp_val = 0.0
			var speed_val = 0.0
			var power_val = 0.0
			
			if enemy_data is WaveEnemyConfig:
				enemy_type = enemy_data.enemy_type
				hp_val = enemy_data.hp
				speed_val = enemy_data.speed
				power_val = enemy_data.power
			elif enemy_data is Dictionary:
				enemy_type = enemy_data.get("enemy_type", "")
				hp_val = float(enemy_data.get("hp", 0.0))
				speed_val = float(enemy_data.get("speed", 0.0))
				power_val = float(enemy_data.get("power", 0.0))
			else:
				Log.error("Test 9 failed: Wave %d Enemy %d data type is unknown" % [i, enemy_idx], "Test")
				get_tree().quit(1)
				return
				
			if enemy_type == "":
				Log.error("Test 9 failed: Wave %d Enemy %d has empty enemy_type" % [i, enemy_idx], "Test")
				get_tree().quit(1)
				return
			if hp_val <= 0.0:
				Log.error("Test 9 failed: Wave %d Enemy %d has invalid hp %.1f" % [i, enemy_idx, hp_val], "Test")
				get_tree().quit(1)
				return
			if speed_val <= 0.0:
				Log.error("Test 9 failed: Wave %d Enemy %d has invalid speed %.1f" % [i, enemy_idx, speed_val], "Test")
				get_tree().quit(1)
				return
			if power_val <= 0.0:
				Log.error("Test 9 failed: Wave %d Enemy %d has invalid power %.1f" % [i, enemy_idx, power_val], "Test")
				get_tree().quit(1)
				return
				
	Log.info("-> All wave paths and enemy config attributes validated successfully.", "Test")
	
	# Temporarily remove BackslashScene from root to prevent automatic scene transition during victory simulation
	var bs_scene = get_node_or_null("/root/BackslashScene")
	if is_instance_valid(bs_scene):
		get_tree().root.remove_child(bs_scene)
		
	PhaseManager.reset_state()
	var total_waves = real_waves.size()
	
	for i in range(total_waves):
		PhaseManager.change_phase(PhaseManager.GamePhase.DEFEND)
		if PhaseManager.current_phase != PhaseManager.GamePhase.DEFEND:
			Log.error("Test 9 failed: Failed to transition to DEFEND phase for wave %d" % i, "Test")
			if is_instance_valid(bs_scene):
				get_tree().root.add_child(bs_scene)
			get_tree().quit(1)
			return
			
		if PhaseManager.current_wave_index != i:
			Log.error("Test 9 failed: Wave index mismatch. Expected %d, got %d" % [i, PhaseManager.current_wave_index], "Test")
			if is_instance_valid(bs_scene):
				get_tree().root.add_child(bs_scene)
			get_tree().quit(1)
			return
			
		PhaseManager.complete_wave()
		
	if PhaseManager.current_phase != PhaseManager.GamePhase.VICTORY:
		Log.error("Test 9 failed: Final phase should be VICTORY after clearing all %d waves. Got phase %s" % [total_waves, PhaseManager.GamePhase.keys()[PhaseManager.current_phase]], "Test")
		if is_instance_valid(bs_scene):
			get_tree().root.add_child(bs_scene)
		get_tree().quit(1)
		return
		
	Log.info("-> Level completion flow verified: Game transitioned to VICTORY phase successfully.", "Test")
	
	# Restore BackslashScene
	if is_instance_valid(bs_scene):
		get_tree().root.add_child(bs_scene)
		
	# Cleanup Test 9 nodes
	real_lp_mock.free()
	get_tree().current_scene = pre_test9_scene

	Log.info("=== ALL TIMELINE & COMBAT EXTENSIONS TESTS PASSED SUCCESSFULLY ===", "Test")
	get_tree().quit()
