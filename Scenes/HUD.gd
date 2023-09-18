class_name HUD extends Control


signal start_wave(wave_index)
signal stop_wave()


@export var _error_message_container: VBoxContainer
@export var _normal_message_container: VBoxContainer
@export var _game_over_label: RichTextLabel
@export var _roll_towers_button: Button
@export var _right_panel_button_group: ButtonGroup


func _ready():
	if Config.minimap_enabled():
		$Minimap.call_deferred("create_instance")
	
	if OS.is_debug_build() and Config.dev_controls_enabled():
		$DevControls.call_deferred("create_instance")
	
	SFX.connect_sfx_to_signal_in_group("res://Assets/SFX/menu_sound_5.wav", "pressed", "sfx_menu_click")

	EventBus.game_mode_was_chosen.connect(_on_game_mode_was_chosen)
	EventBus.game_over.connect(_on_game_over)
	WaveLevel.changed.connect(_on_wave_level_changed)
	BuildTower.tower_built.connect(_on_tower_built)
	
	for button in _right_panel_button_group.get_buttons():
		button.toggled.connect(_on_right_panel_button_toggled)
	
	HighlightUI.register_target("roll_towers_button", _roll_towers_button)
	_update_tooltip_for_roll_towers_button()


func get_error_message_container() -> VBoxContainer:
	return _error_message_container


func get_normal_message_container() -> VBoxContainer:
	return _normal_message_container


func _on_game_over():
	_game_over_label.show()


func _on_roll_towers_button_pressed():
	var research_any_elements: bool = false

	for element in Element.get_list():
		var researched_element: bool = ElementLevel.get_current(element) > 0
		if researched_element:
			research_any_elements = true

	if !research_any_elements:
		Messages.add_error("Cannot roll towers yet! You need to research at least one element.")

		return

	var can_roll_again: bool = TowerDistribution.roll_starting_towers()

	_update_tooltip_for_roll_towers_button()

	if !can_roll_again:
		_roll_towers_button.hide()


func _update_tooltip_for_roll_towers_button():
	var roll_count: int = TowerDistribution.get_current_starting_tower_roll_amount()
	var tooltip: String = "Press to get a random set of starting towers.\nYou can reroll if you don't like the initial towers\nbut each time you will get less towers.\nNext roll will give you %d towers" % roll_count
	_roll_towers_button.set_tooltip_text(tooltip)


func _on_game_mode_was_chosen():
	var roll_button_should_be_visible: bool = Globals.game_mode_is_random()
	_roll_towers_button.visible = roll_button_should_be_visible


func _on_wave_level_changed():
	var new_wave_level: int = WaveLevel.get_current()
	var start_first_wave: bool = new_wave_level == 1

	if start_first_wave:
		_roll_towers_button.hide()


func _on_tower_built(_tower_id: int):
	_roll_towers_button.hide()


func _on_right_panel_button_toggled(_toggle: bool):
	var pressed_button = _right_panel_button_group.get_pressed_button()
	if pressed_button:
		for button in _right_panel_button_group.get_buttons():
			button.hide()
		pressed_button.show()
	else:
		for button in _right_panel_button_group.get_buttons():
			button.show()
