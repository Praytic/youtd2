class_name HUD extends Control


signal start_wave(wave_index)
signal stop_wave()


@export var _error_message_container: VBoxContainer
@export var _normal_message_container: VBoxContainer
@export var _game_over_label: RichTextLabel
@export var _elements_tower_menu: Control
@export var _item_stash_menu: Control
@export var _unit_menu: Control
@export var _towers_menu_card: ButtonStatusCard
@export var _items_menu_card: ButtonStatusCard

@onready var _window_list: Array = [_elements_tower_menu, _item_stash_menu, _unit_menu]


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


func _on_towers_button_toggled(toggled):
	if toggled:
		_elements_tower_menu.show()
		_towers_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_OPENED)
		_items_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_CLOSED)
	else:
		_elements_tower_menu.hide()
		if _item_stash_menu.visible:
			_towers_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_CLOSED)
			_items_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_CLOSED)
		elif any_window_is_open():
			_towers_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_CLOSED)
			_items_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_CLOSED)
		else:
			_towers_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.ESSENTIALS)
			_items_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.ESSENTIALS)


func _on_items_button_toggled(toggled):
	if toggled:
		_item_stash_menu.show()
		_towers_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_CLOSED)
		_items_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_OPENED)
	else:
		_item_stash_menu.hide()
		if _elements_tower_menu.visible:
			_towers_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_OPENED)
			_items_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_CLOSED)
		elif any_window_is_open():
			_towers_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_CLOSED)
			_items_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_CLOSED)
		else:
			_towers_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.ESSENTIALS)
			_items_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.ESSENTIALS)


func _unhandled_input(event):
	var cancelled: bool = event.is_action_released("ui_cancel")
	var left_click: bool = event.is_action_released("left_click")
	if (cancelled or left_click) and not any_window_is_open():
		_items_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.ESSENTIALS)
		_towers_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.ESSENTIALS)


func any_window_is_open() -> bool:
	for window in _window_list:
		if window.visible:
			return true
	
	return false


func close_all_windows():
	for window in _window_list:
		window.hide()
	
	_towers_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.ESSENTIALS)
	_items_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.ESSENTIALS)
	
#	NOTE: also deselect current unit because if the unit menu is closed, then there should be no unit selected
	SelectUnit.set_selected_unit(null)
	


func _on_close_button_pressed():
	if not _elements_tower_menu.visible and not _item_stash_menu.visible:
		_towers_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_CLOSED)
		_items_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_CLOSED)
	elif not any_window_is_open():
		_towers_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.ESSENTIALS)
		_items_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.ESSENTIALS)
