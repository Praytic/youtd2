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
@export var _unit_status_menu_card: ButtonStatusCard

@onready var _window_list: Array = [_elements_tower_menu, _item_stash_menu, _unit_menu]


#########################
###     Built-in      ###
#########################

func _ready():
	if Config.minimap_enabled():
		$Minimap.call_deferred("create_instance")
	
	if OS.is_debug_build() and Config.dev_controls_enabled():
		$DevControls.call_deferred("create_instance")
	
	SFX.connect_sfx_to_signal_in_group("res://Assets/SFX/menu_sound_5.wav", "pressed", "sfx_menu_click")

	EventBus.game_over.connect(_on_game_over)
	
	# Tutorial setup
	var towers_menu_button = _towers_menu_card.get_main_button()
	HighlightUI.register_target("tower_stash_button", _towers_menu_card.get_main_button())
	towers_menu_button.pressed.connect(func(): HighlightUI.highlight_target_ack.emit("tower_stash_button"))
	var items_menu_button = _items_menu_card.get_main_button()
	HighlightUI.register_target("item_stash_button", _items_menu_card.get_main_button())
	items_menu_button.pressed.connect(func(): HighlightUI.highlight_target_ack.emit("item_stash_button"))
	var unit_status_menu_button = _unit_status_menu_card.get_main_button()
	HighlightUI.register_target("unit_status_menu_button", _unit_status_menu_card.get_main_button())
	unit_status_menu_button.pressed.connect(func(): HighlightUI.highlight_target_ack.emit("unit_status_menu_button"))


#########################
###       Public      ###
#########################

func close_all_windows():
	for window in _window_list:
		window.close()
	
#	NOTE: also deselect current unit because if the unit menu is closed, then there should be no unit selected
#	NOTE: this method is called twice due to UnitMenu window `close()` method.
	SelectUnit.set_selected_unit(null)


#########################
###      Private      ###
#########################

func _update_menus_visibility():
	_elements_tower_menu.visible = _towers_menu_card.get_main_button().is_pressed()
	_item_stash_menu.visible = _items_menu_card.get_main_button().is_pressed()
	_unit_menu.visible = _unit_status_menu_card.get_main_button().is_pressed()


#########################
###     Callbacks     ###
#########################


func _on_main_button_toggled(_button_pressed):
	_update_menus_visibility()
	_update_cards_visibility()


func _on_close_button_pressed():
	_update_menus_visibility()
	_update_cards_visibility()



func _on_game_over():
	_game_over_label.show()


func _update_cards_visibility():
	if _unit_menu.visible:
		_towers_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_CLOSED)
		_unit_status_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_OPENED)
		_items_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_CLOSED)
	elif _item_stash_menu.visible:
		_towers_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_CLOSED)
		_unit_status_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_CLOSED)
		_items_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_OPENED)
	elif _elements_tower_menu.visible:
		_towers_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_OPENED)
		_unit_status_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_CLOSED)
		_items_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.MENU_CLOSED)
	else:
		# nothing is visible
		_towers_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.ESSENTIALS)
		_unit_status_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.ESSENTIALS)
		_items_menu_card.change_visibility_level(ButtonStatusCard.VisibilityLevel.ESSENTIALS)



#########################
### Setters / Getters ###
#########################

func get_error_message_container() -> VBoxContainer:
	return _error_message_container


func get_normal_message_container() -> VBoxContainer:
	return _normal_message_container


func any_window_is_open() -> bool:
	for window in _window_list:
		if window.visible:
			return true
	
	return false
