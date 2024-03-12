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
@export var _bottom_menu_bar: BottomMenuBar
@export var _top_left_menu: TopLeftMenu

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


func set_items(item_list: Array[Item]):
	_item_stash_menu.set_items(item_list)
	_items_menu_card.set_items(item_list)


func set_items_for_horadric_cube(item_list: Array[Item]):
	_item_stash_menu.set_items_for_horadric_cube(item_list)
	

func set_towers(towers: Dictionary):
	_elements_tower_menu.set_towers(towers)
	_towers_menu_card.set_towers(towers)


func set_gold(gold: float):
	_bottom_menu_bar.set_gold(gold)
	_top_left_menu.set_gold(gold)


func set_tomes(tomes: int):
	_bottom_menu_bar.set_tomes(tomes)


func set_food(food: int, food_cap: int):
	_bottom_menu_bar.set_food(food, food_cap)


func set_pregame_settings(wave_count: int, game_mode: GameMode.enm, difficulty: Difficulty.enm, builder_id: int):
	_top_left_menu.set_pregame_settings(wave_count, game_mode, difficulty, builder_id)


#########################
###      Private      ###
#########################

func _update_menus_and_cards_visibility():
	_elements_tower_menu.visible = _towers_menu_card.get_main_button().is_pressed()
	_item_stash_menu.visible = _items_menu_card.get_main_button().is_pressed()
	_unit_menu.visible = _unit_status_menu_card.get_main_button().is_pressed()

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


func show_game_start_time():
	_top_left_menu.show_game_start_time()

func hide_game_start_time():
	_top_left_menu.hide_game_start_time()


func show_next_wave_button():
	_top_left_menu.show_next_wave_button()


func show_next_wave_time(time: float):
	_top_left_menu.show_next_wave_time(time)


func hide_next_wave_time():
	_top_left_menu.hide_next_wave_time()


func show_wave_details(wave_list: Array[Wave]):
	_top_left_menu.show_wave_details(wave_list)


func disable_next_wave_button():
	_top_left_menu.disable_next_wave_button()


func update_level(level: int):
	_top_left_menu.update_level(level)


func set_lives(lives: float):
	_top_left_menu.set_lives(lives)


func set_total_damage(total_damage: float):
	_top_left_menu.set_total_damage(total_damage)


func set_game_time(time: float):
	_top_left_menu.set_game_time(time)


func set_gold_farmed(gold_farmed: float):
	_top_left_menu.set_gold_farmed(gold_farmed)


func set_score(score: int):
	_top_left_menu.set_score(score)


#########################
###     Callbacks     ###
#########################


func _on_main_button_toggled():
	_update_menus_and_cards_visibility()


func _on_unit_menu_hidden():
	_update_menus_and_cards_visibility()


func _on_element_towers_menu_hidden():
	_update_menus_and_cards_visibility()


func _on_item_stash_menu_hidden():
	_update_menus_and_cards_visibility()


func _on_game_over():
	_game_over_label.show()


#########################
### Setters / Getters ###
#########################

func get_error_message_container() -> VBoxContainer:
	return _error_message_container


func get_normal_message_container() -> VBoxContainer:
	return _normal_message_container


func get_item_stash_button() -> Button:
	return _items_menu_card.get_main_button()


func any_window_is_open() -> bool:
	for window in _window_list:
		if window.visible:
			return true
	
	return false
