class_name HUD extends Control


signal start_wave(wave_index)
signal stop_wave()


@export var _error_message_container: VBoxContainer
@export var _normal_message_container: VBoxContainer
@export var _game_over_label: RichTextLabel
@export var _elements_tower_menu: ElementTowersMenu
@export var _item_stash_menu: ItemStashMenu
@export var _towers_menu_card: ButtonStatusCard
@export var _items_menu_card: ButtonStatusCard
@export var _unit_status_menu_card: ButtonStatusCard
@export var _bottom_menu_bar: BottomMenuBar
@export var _top_left_menu: TopLeftMenu
@export var _creep_menu: CreepMenu
@export var _tower_menu: TowerMenu

@onready var _window_list: Array = [_elements_tower_menu, _item_stash_menu, _tower_menu, _creep_menu]


#########################
###     Built-in      ###
#########################

func _ready():
	if Config.minimap_enabled():
		$Minimap.call_deferred("create_instance")
	
	if OS.is_debug_build() and Config.dev_controls_enabled():
		$DevControls.call_deferred("create_instance")
	
	SFX.connect_sfx_to_signal_in_group("res://Assets/SFX/menu_sound_5.wav", "pressed", "sfx_menu_click")

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

# Set tower or creep which should be displayed in unit menus
# NOTE: the callback for set_pressed() which make tower menu
# or creep menu visible.
func set_menu_unit(unit: Unit):
	if unit == null:
		_tower_menu.set_tower(null)
		_creep_menu.set_creep(null)
	elif unit is Tower:
		var tower: Tower = unit as Tower
		_tower_menu.set_tower(tower)
		_tower_menu.show()
		_creep_menu.hide()
	elif unit is Creep:
		var creep: Creep = unit as Creep
		_creep_menu.set_creep(creep)
		_creep_menu.show()
		_tower_menu.hide()
	
	_unit_status_menu_card.set_unit(unit)
	_unit_status_menu_card.visible = unit != null
	_unit_status_menu_card.get_main_button().set_pressed(unit != null)


func update_level(level: int):
	_elements_tower_menu.update_level(level)


func hide_roll_towers_button():
	_elements_tower_menu.hide_roll_towers_button()


func update_element_level(element_levels: Dictionary):
	_elements_tower_menu.update_element_level(element_levels)


func set_player(player: Player):
	_tower_menu.set_player(player)
	_elements_tower_menu.set_player(player)


func hide_all_windows():
	for window in _window_list:
		window.hide()


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


func set_tomes(tomes: int):
	_bottom_menu_bar.set_tomes(tomes)


func set_food(food: int, food_cap: int):
	_bottom_menu_bar.set_food(food, food_cap)


func set_pregame_settings(wave_count: int, game_mode: GameMode.enm, difficulty: Difficulty.enm, builder_id: int):
	_top_left_menu.set_pregame_settings(wave_count, game_mode, difficulty, builder_id)


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


func load_player_stats(player_list: Array[Player]):
	_top_left_menu.load_player_stats(player_list)


func set_game_time(time: float):
	_top_left_menu.set_game_time(time)


func show_game_over():
	_game_over_label.show()


#########################
###     Callbacks     ###
#########################

func _on_creep_menu_hidden():
	_unit_status_menu_card.collapse()


func _on_tower_menu_hidden():
	_unit_status_menu_card.collapse()


func _on_element_towers_menu_hidden():
	_towers_menu_card.collapse()


func _on_item_stash_menu_hidden():
	_items_menu_card.collapse()


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


func _on_towers_status_card_main_button_toggled(toggled_on: bool):
	_elements_tower_menu.visible = toggled_on


func _on_items_status_card_main_button_toggled(toggled_on: bool):
	_item_stash_menu.visible = toggled_on


func _on_unit_status_card_main_button_toggled(toggled_on: bool):
	if toggled_on:
		var displayed_unit: Unit = _unit_status_menu_card.get_unit()
		
		if displayed_unit is Tower:
			_tower_menu.show()
		else:
			_creep_menu.show()
	else:
		_tower_menu.hide()
		_creep_menu.hide()
