class_name HUD extends Control


signal start_wave(wave_index)
signal stop_wave()


@export var _error_message_container: VBoxContainer
@export var _normal_message_container: VBoxContainer
@export var _game_over_label: RichTextLabel
@export var _elements_menu: ElementsMenu
@export var _tower_stash_menu: TowerStashMenu
@export var _item_stash_menu: ItemStashMenu
@export var _towers_menu_card: ButtonStatusCard
@export var _items_menu_card: ButtonStatusCard
@export var _elements_menu_card: ButtonStatusCard
@export var _top_left_menu: TopLeftMenu
@export var _unit_menu: UnitMenu
@export var _host_player_label: Label
@export var _second_player_label: Label
@export var _chat_line_edit: LineEdit
@export var _desync_label: Label
@export var _button_tooltip_top: ButtonTooltip
@export var _button_tooltip_bottom: ButtonTooltip
@export var _tower_details: TowerDetails
@export var _creep_details: CreepDetails

# NOTE: this list is ordered by priority of closure. If
# multiple windows are open, then the first window in the
# list will be closed, others will stay.
@onready var _window_list: Array = [_tower_details, _creep_details, _elements_menu, _tower_stash_menu, _item_stash_menu]


#########################
###     Built-in      ###
#########################

func _ready():
	if Config.minimap_enabled():
		$Minimap.call_deferred("create_instance")
	
	if OS.is_debug_build() and Config.dev_controls_enabled():
		$DevControls.call_deferred("create_instance")
	
	SFX.connect_sfx_to_signal_in_group("res://assets/sfx/menu_sound_5.wav", "pressed", "sfx_menu_click")

	EventBus.local_player_rolled_towers.connect(_on_local_player_rolled_towers)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

#	NOTE: fill message container with blank labels before
#	first messages arrive, so that initial messages appear
#	at the bottom
	for i in range(0, Messages.NORMAL_MESSAGE_MAX):
		var blank_label: RichTextLabel = Utils.create_message_label(" ")
		_normal_message_container.add_child(blank_label)
	
	ButtonTooltip.setup_tooltip_instances(_button_tooltip_top, _button_tooltip_bottom)


#########################
###       Public      ###
#########################

func set_tower_stash_filter_type(filter_type: TowerStashMenu.FilterType):
	_tower_stash_menu.set_filter_type(filter_type)


func show_desync_message(message: String):
	_desync_label.show()
	_desync_label.text = message


func update_wave_details():
	var local_player: Player = PlayerManager.get_local_player()
	var next_waves: Array[Wave] = local_player.get_next_5_waves()
	_top_left_menu.show_wave_details(next_waves)


func start_editing_chat():
	_chat_line_edit.show()
	_chat_line_edit.grab_focus()


func finish_editing_chat():
	_chat_line_edit.clear()
	_chat_line_edit.hide()


func enter_slash_into_chat():
	_chat_line_edit.text = "/"
	_chat_line_edit.caret_column = 1


func editing_chat() -> bool:
	return _chat_line_edit.visible


func get_chat_edit_text() -> String:
	var text: String = _chat_line_edit.text

	return text


func add_chat_message(player: Player, message: String):
	var player_name: String = player.get_player_name()

	var complete_message: String = "[%s]: %s" % [player_name, message]
	
	Messages.add_normal(null, complete_message)


# Set tower or creep which should be displayed in unit menus
# NOTE: the callback for set_pressed() which make tower menu
# or creep menu visible.
func set_menu_unit(unit: Unit):
	_unit_menu.set_unit(unit)
	_unit_menu.visible = unit != null
	
	var tower: Tower = unit as Tower
	var creep: Creep = unit as Creep
	_tower_details.set_tower(tower)
	_creep_details.set_creep(creep)

	if tower == null:
		_tower_details.hide()
	if creep == null:
		_creep_details.hide()


func hide_roll_towers_button():
	_elements_menu.hide_roll_towers_button()


func connect_to_local_player(local_player: Player):
	var item_stash: ItemContainer = local_player.get_item_stash()
	item_stash.items_changed.connect(_on_local_player_item_stash_changed)

	var horadric_stash: ItemContainer = local_player.get_horadric_stash()
	horadric_stash.items_changed.connect(_on_local_player_horadric_stash_changed)

	var tower_stash: TowerStash = local_player.get_tower_stash()
	tower_stash.changed.connect(_on_local_player_tower_stash_changed)

	var local_team: Team = local_player.get_team()
	local_team.level_changed.connect(_on_local_team_level_changed)
	_on_local_team_level_changed()

	local_player.element_level_changed.connect(_on_local_player_element_level_changed)
	_on_local_player_element_level_changed()

	local_player.selected_builder.connect(_on_local_player_selected_builder)

	local_player.roll_was_disabled.connect(_on_local_player_roll_was_disabled)


func set_game_start_timer(timer: ManualTimer):
	_top_left_menu.set_game_start_timer(timer)


func close_one_window():
	for window in _window_list:
		if window.visible:
			window.hide()
			break


func set_pregame_settings(wave_count: int, game_mode: GameMode.enm, difficulty: Difficulty.enm):
	_top_left_menu.set_pregame_settings(wave_count, game_mode, difficulty)


func show_next_wave_button():
	_top_left_menu.show_next_wave_button()


func show_game_over():
	_game_over_label.show()


#########################
###     Callbacks     ###
#########################

func _on_local_player_item_stash_changed():
	var local_player: Player = PlayerManager.get_local_player()
	var item_stash: ItemContainer = local_player.get_item_stash()
	var item_list: Array[Item] = item_stash.get_item_list()
	
	_item_stash_menu.set_items(item_list)
	_items_menu_card.set_items(item_list)


func _on_local_player_horadric_stash_changed():
	var local_player: Player = PlayerManager.get_local_player()
	var horadric_stash: ItemContainer = local_player.get_horadric_stash()
	var item_list: Array[Item] = horadric_stash.get_item_list()
	
	_item_stash_menu.set_items_for_horadric_cube(item_list)


func _on_local_player_tower_stash_changed():
	var local_player: Player = PlayerManager.get_local_player()
	var tower_stash: TowerStash = local_player.get_tower_stash()
	var towers: Dictionary = tower_stash.get_towers()
	
	_tower_stash_menu.set_towers(towers)
	_towers_menu_card.set_towers(towers)


func _on_local_team_level_changed():
	update_wave_details()
	
	var local_player: Player = PlayerManager.get_local_player()
	var local_team: Team = local_player.get_team()
	var level: int = local_team.get_level()
	_tower_stash_menu.update_level(level)


func _on_local_player_element_level_changed():
	var local_player: Player = PlayerManager.get_local_player()
	var new_element_levels: Dictionary = local_player.get_element_level_map()
	_tower_stash_menu.update_element_level(new_element_levels)
	_elements_menu.update_element_level(new_element_levels)


func _on_local_player_selected_builder():
	var local_player: Player = PlayerManager.get_local_player()
	var builder: Builder = local_player.get_builder()
	var builder_id: int = builder.get_id()

	_top_left_menu.set_local_builder(builder_id)

	var builder_adds_extra_recipes: bool = builder.get_adds_extra_recipes()
	if builder_adds_extra_recipes:
		_item_stash_menu.enable_extra_recipes()


func _on_local_player_roll_was_disabled():
	hide_roll_towers_button()


func _on_tower_stash_menu_hidden():
	_towers_menu_card.collapse()


func _on_item_stash_menu_hidden():
	_items_menu_card.collapse()


func _on_peer_connected(id):
	_host_player_label.text = "Player ID: %s" % multiplayer.get_unique_id()
	_second_player_label.text = "Player ID: %s" % id


func _on_peer_disconnected(_id):
	_second_player_label.text = ""


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
	_tower_stash_menu.visible = toggled_on


func _on_items_status_card_main_button_toggled(toggled_on: bool):
	_item_stash_menu.visible = toggled_on


func _on_element_status_card_main_button_toggled(toggled_on):
	_elements_menu.visible = toggled_on


func _on_elements_menu_hidden():
	_elements_menu_card.collapse()


# Manually press status button for tower stash menu to
# switch to tower stash menu after rolling towers.
func _on_local_player_rolled_towers():
	var tower_status_button: Button = _towers_menu_card.get_main_button()
	tower_status_button.set_pressed(true)


func _on_unit_menu_details_pressed():
	var current_unit: Unit = _unit_menu.get_unit()
	
	if current_unit is Tower:
		_tower_details.visible = !_tower_details.visible
		_creep_details.visible = false
	
		_tower_details.update_text()
	elif current_unit is Creep:
		_tower_details.visible = false
		_creep_details.visible = !_creep_details.visible
	
		_creep_details.update_text()
	else:
		_tower_details.visible = false
		_creep_details.visible = false


func _on_speed_normal_toggled(button_pressed: bool):
	if button_pressed:
		Globals.set_update_ticks_per_physics_tick(Constants.GAME_SPEED_NORMAL)


func _on_speed_fast_toggled(button_pressed: bool):
	if button_pressed:
		Globals.set_update_ticks_per_physics_tick(Constants.GAME_SPEED_FAST)


func _on_speed_fastest_toggled(button_pressed: bool):
	if button_pressed:
		Globals.set_update_ticks_per_physics_tick(Constants.GAME_SPEED_FASTEST)
