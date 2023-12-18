class_name HUD extends Control


signal start_wave(wave_index)
signal stop_wave()


@export var _error_message_container: VBoxContainer
@export var _normal_message_container: VBoxContainer
@export var _game_over_label: RichTextLabel
@export var _elements_tower_menu: Control
@export var _item_stash_menu: Control
@export var _unit_menu: Control


func _ready():
	if Config.minimap_enabled():
		$Minimap.call_deferred("create_instance")
	
	if OS.is_debug_build() and Config.dev_controls_enabled():
		$DevControls.call_deferred("create_instance")
	
	SFX.connect_sfx_to_signal_in_group("res://Assets/SFX/menu_sound_5.wav", "pressed", "sfx_menu_click")

	EventBus.game_over.connect(_on_game_over)


func get_error_message_container() -> VBoxContainer:
	return _error_message_container


func get_normal_message_container() -> VBoxContainer:
	return _normal_message_container


func _on_game_over():
	_game_over_label.show()


func _on_towers_button_pressed():
	_elements_tower_menu.show()
	if _item_stash_menu.visible:
		_item_stash_menu.hide()


func _on_items_button_pressed():
	_item_stash_menu.show()
	if _elements_tower_menu.visible:
		_elements_tower_menu.hide()

