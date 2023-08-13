class_name HUD extends Control


signal start_wave(wave_index)
signal stop_wave()


@onready var _error_message_container: VBoxContainer = $MarginContainer2/ErrorMessageContainer
@onready var _normal_message_container: VBoxContainer = $MarginContainer3/NormalMessageContainer
@export var _game_over_label: RichTextLabel
@export var _roll_towers_button: Button


func _ready():
	if Config.minimap_enabled():
		$Minimap.call_deferred("create_instance")
	
	if OS.is_debug_build() and Config.dev_controls_enabled():
		$DevControls.call_deferred("create_instance")
	
	SFX.connect_sfx_to_signal_in_group("res://Assets/SFX/menu_sound_5.wav", "pressed", "sfx_menu_click")

	EventBus.game_mode_was_chosen.connect(_on_game_mode_was_chosen)
	EventBus.game_over.connect(_on_game_over)
	WaveLevel.changed.connect(_on_wave_level_changed)


func get_error_message_container() -> VBoxContainer:
	return _error_message_container


func get_normal_message_container() -> VBoxContainer:
	return _normal_message_container


func _on_game_over():
	_game_over_label.show()


func _on_roll_towers_button_pressed():
	var can_roll_again: bool = TowerDistribution.roll_starting_towers()

	if !can_roll_again:
		_roll_towers_button.hide()


func _on_game_mode_was_chosen():
	var roll_button_should_be_visible: bool = Globals.game_mode == GameMode.enm.RANDOM_WITH_UPGRADES || Globals.game_mode == GameMode.enm.TOTALLY_RANDOM
	_roll_towers_button.visible = roll_button_should_be_visible


func _on_wave_level_changed():
	var new_wave_level: int = WaveLevel.get_current()
	var start_first_wave: bool = new_wave_level == 1

	if start_first_wave:
		_roll_towers_button.hide()
