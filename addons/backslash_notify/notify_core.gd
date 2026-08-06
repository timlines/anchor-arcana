extends CanvasLayer

## Global Autoload for presenting premium, standardized UI notifications.
## Name: BackslashNotify
## Depends on: Backslash Logging (Log), Backslash Controls (backslash_input)

## Standard signal emitted when the notification is dismissed or times out.
signal notification_completed
signal question_completed(is_correct: bool)

# UI child elements
var _panel: Panel = null
var _label: Label = null
var _texture_rect: TextureRect = null
var _dismiss_label: Label = null

var _timer: Timer = null
var _is_active: bool = false

var _is_question_mode: bool = false
var _correct_option_index: int = -1
var _options_container: VBoxContainer = null
var _option_buttons: Array[BaseButton] = []

func _ready() -> void:
	# Hide initially
	visible = false
	layer = 100 # Put it on top of other CanvasLayers (HUD is usually 1, card menu is usually 2)
	
	_build_notification_ui()
	
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(dismiss)
	
	if has_node("/root/Log"):
		Log.info("BackslashNotify addon initialized successfully.", "Notify")
	else:
		print("[INFO] [Notify] BackslashNotify initialized.")

var _last_dir_y: float = 0.0

func _get_backslash_input() -> BackslashInput:
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and "backslash_input" in player:
		return player.backslash_input as BackslashInput
	return null

func _navigate_down() -> void:
	var cur_focus = get_viewport().gui_get_focus_owner()
	var idx = _option_buttons.find(cur_focus)
	if idx != -1:
		var next_idx = (idx + 1) % _option_buttons.size()
		_option_buttons[next_idx].grab_focus()
	else:
		if not _option_buttons.is_empty():
			_option_buttons[0].grab_focus()

func _navigate_up() -> void:
	var cur_focus = get_viewport().gui_get_focus_owner()
	var idx = _option_buttons.find(cur_focus)
	if idx != -1:
		var prev_idx = (idx - 1 + _option_buttons.size()) % _option_buttons.size()
		_option_buttons[prev_idx].grab_focus()
	else:
		if not _option_buttons.is_empty():
			_option_buttons[0].grab_focus()

func _process(_delta: float) -> void:
	if _is_active:
		# If action1 is pressed, dismiss the notification instantly (only if NOT in question mode)
		if not _is_question_mode and Input.is_action_just_pressed("action1"):
			if has_node("/root/Log"):
				Log.info("Notification dismissed manually by Player via action1.", "Notify")
			dismiss()
			return
			
		if _is_question_mode:
			var bi = _get_backslash_input()
			if is_instance_valid(bi):
				var move_dir = bi.get_movement_vector()
				var dir_y = move_dir.y
				if abs(dir_y) > 0.5:
					if _last_dir_y == 0.0:
						if dir_y > 0.5:
							_navigate_down()
						else:
							_navigate_up()
						_last_dir_y = sign(dir_y)
				else:
					_last_dir_y = 0.0
					
				# Confirm selected button with action1
				if Input.is_action_just_pressed("action1"):
					var cur_focus = get_viewport().gui_get_focus_owner()
					if cur_focus in _option_buttons and cur_focus.is_inside_tree() and cur_focus.visible:
						cur_focus.pressed.emit()
						get_viewport().set_input_as_handled()

## Programmatically builds the premium glassmorphism notification UI
func _build_notification_ui() -> void:
	# Translucent dark styling with elegant borders
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.09, 0.12, 0.9) # Rich dark blue-gray
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.border_width_bottom = 2
	panel_style.border_width_top = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_color = Color(0.3, 0.5, 1.0, 0.5) # Glowing metallic blue border
	
	# Centered container
	_panel = Panel.new()
	_panel.add_theme_stylebox_override("panel", panel_style)
	_panel.anchor_left = 0.25
	_panel.anchor_right = 0.75
	_panel.anchor_top = 0.1
	_panel.anchor_bottom = 0.25
	_panel.offset_left = 0
	_panel.offset_right = 0
	_panel.offset_top = 0
	_panel.offset_bottom = 0
	add_child(_panel)
	
	var margin_container = MarginContainer.new()
	margin_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin_container.add_theme_constant_override("margin_left", 16)
	margin_container.add_theme_constant_override("margin_right", 16)
	margin_container.add_theme_constant_override("margin_top", 12)
	margin_container.add_theme_constant_override("margin_bottom", 12)
	_panel.add_child(margin_container)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin_container.add_child(hbox)
	
	# Optional Image display
	_texture_rect = TextureRect.new()
	_texture_rect.custom_minimum_size = Vector2(48, 48)
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture_rect.visible = false
	hbox.add_child(_texture_rect)
	
	# Spacer
	var spacing = Control.new()
	spacing.custom_minimum_size = Vector2(12, 0)
	hbox.add_child(spacing)
	
	# Vertical layout for message and button hint
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox)
	
	# Message Label
	_label = Label.new()
	_label.text = ""
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_label)
	
	# Options container for questions
	_options_container = VBoxContainer.new()
	_options_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_options_container.add_theme_constant_override("separation", 6)
	_options_container.visible = false
	vbox.add_child(_options_container)
	
	# Action Dismiss Hint Label
	_dismiss_label = Label.new()
	_dismiss_label.text = "Press [Action 1] to Dismiss"
	_dismiss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dismiss_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dismiss_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 0.8)) # Subdued blue
	_dismiss_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_dismiss_label)

## Presents a notification with optional image and duration countdown.
func notify(text: String, image: Texture2D = null, duration: float = 3.0) -> void:
	if has_node("/root/Log"):
		Log.info("Displaying notification: %s (Duration: %.1fs)" % [text, duration], "Notify")
	else:
		print("[INFO] [Notify] Displaying: %s" % text)
		
	_label.text = text
	
	if image:
		_texture_rect.texture = image
		_texture_rect.visible = true
	else:
		_texture_rect.visible = false
		
	# Reset states
	visible = true
	_is_active = true
	
	# Configure duration timer
	if duration > 0.0:
		_timer.wait_time = duration
		_timer.start()
		_dismiss_label.text = "Press [Action 1] to Dismiss (Auto-dismiss in %.1fs)" % duration
	else:
		_timer.stop()
		_dismiss_label.text = "Press [Action 1] to Dismiss"
		
	# Scale overlay layout dynamically
	_update_layout()

## Presents a multiple choice question/riddle with 3 options.
## Emits `question_completed(is_correct: bool)` when an option is selected.
func ask_question(question_text: String, options: Array[String], correct_index: int) -> void:
	if has_node("/root/Log"):
		Log.info("Displaying question: %s" % question_text, "Notify")
	else:
		print("[INFO] [Notify] Question: %s" % question_text)
		
	_is_active = true
	_is_question_mode = true
	_correct_option_index = correct_index
	visible = true
	
	# Stop auto-dismiss timer
	_timer.stop()
	
	# Configure labels
	_label.text = question_text
	_dismiss_label.text = "Select an answer with Arrow Keys/D-pad and press Space/Action 1 to Confirm"
	_dismiss_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 0.8))
	
	# Clear previous buttons
	if _options_container:
		for child in _options_container.get_children():
			child.queue_free()
		_option_buttons.clear()
		
		# Create option buttons
		for i in range(options.size()):
			var btn = BackslashButtonManager.create_button(options[i])
			
			# Bind signal connection
			btn.pressed.connect(_on_option_selected.bind(i))
			
			_options_container.add_child(btn)
			_option_buttons.append(btn)
			
		_options_container.visible = true
		
	# Scale overlay layout dynamically
	_update_layout()
	
	# Grab focus on the first button for keyboard navigation
	if not _option_buttons.is_empty():
		_option_buttons[0].grab_focus()

## Called when player selects a riddle option
func _on_option_selected(index: int) -> void:
	var is_correct = (index == _correct_option_index)
	
	if has_node("/root/Log"):
		Log.info("Question option %d selected. Correct: %s" % [index, str(is_correct)], "Notify")
		
	# Close the question menu immediately
	dismiss()
	
	# Present standard notification with the result
	var result_text = "CORRECT ANSWER!" if is_correct else "WRONG ANSWER! Try again."
	notify(result_text, null, 2.5)
	
	question_completed.emit(is_correct)

## Hides and dismisses the notification.
func dismiss() -> void:
	if not _is_active:
		return
		
	_is_active = false
	_is_question_mode = false
	_timer.stop()
	visible = false
	
	# Clear question UI
	if _options_container:
		_options_container.visible = false
		for child in _options_container.get_children():
			child.queue_free()
		_option_buttons.clear()
		
	notification_completed.emit()
	
	if has_node("/root/Log"):
		Log.debug("Notification overlay dismissed successfully.", "Notify")
	else:
		print("[INFO] [Notify] Dismissed.")

## Dynamically scales the notification overlay relative to the viewport size.
func _update_layout() -> void:
	if not is_inside_tree():
		return
		
	var viewport_size = get_viewport().get_visible_rect().size
	if viewport_size.y <= 0:
		return
		
	var scale_factor = viewport_size.y / 648.0
	scale_factor = clamp(scale_factor, 0.8, 1.25)
	
	if _panel:
		if _is_question_mode:
			# Larger centered overlay for multiple choice questions
			_panel.anchor_left = 0.2
			_panel.anchor_right = 0.8
			_panel.anchor_top = 0.22
			_panel.anchor_bottom = 0.78
			_panel.custom_minimum_size = Vector2(400.0 * scale_factor, 280.0 * scale_factor)
		else:
			# Centered on the upper portion of the screen
			_panel.anchor_left = 0.25
			_panel.anchor_right = 0.75
			_panel.anchor_top = 0.08
			_panel.anchor_bottom = 0.22
			_panel.custom_minimum_size = Vector2(300.0 * scale_factor, 80.0 * scale_factor)
