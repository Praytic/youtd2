class_name HUD extends Control


signal start_wave(wave_index)
signal stop_wave()

const CHAT_MESSAGE_MAX: int = 10
const CHAT_DELAY_BEFORE_FADE_START: float = 10.0
const CHAT_FADE_DURATION: float = 2.0


@export var _error_message_container: VBoxContainer
@export var _normal_message_container: VBoxContainer
@export var _chat_message_container: VBoxContainer
@export var _game_over_label: RichTextLabel
@export var _elements_tower_menu: ElementTowersMenu
@export var _item_stash_menu: ItemStashMenu
@export var _towers_menu_card: ButtonStatusCard
@export var _items_menu_card: ButtonStatusCard
@export var _unit_status_menu_card: ButtonStatusCard
@export var _top_left_menu: TopLeftMenu
@export var _creep_menu: CreepMenu
@export var _tower_menu: TowerMenu
@export var _host_player_label: Label
@export var _second_player_label: Label
@export var _chat_line_edit: LineEdit

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
	HighlightUI.register_target("tower_stash_button", towers_menu_button)
	towers_menu_button.pressed.connect(func(): 	EventBus.player_performed_tutorial_advance_action.emit("press_tower_stash_button"))
	var items_menu_button = _items_menu_card.get_main_button()
	HighlightUI.register_target("item_stash_button", items_menu_button)
	items_menu_button.pressed.connect(func(): 	EventBus.player_performed_tutorial_advance_action.emit("press_item_stash_button"))
	var unit_status_menu_button = _unit_status_menu_card.get_main_button()
	HighlightUI.register_target("unit_status_menu_button", unit_status_menu_button)
	unit_status_menu_button.pressed.connect(func(): 	EventBus.player_performed_tutorial_advance_action.emit("press_unit_status_button"))
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


#########################
###       Public      ###
#########################

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


func editing_chat() -> bool:
	return _chat_line_edit.visible


func get_chat_edit_text() -> String:
	var text: String = _chat_line_edit.text

	return text


func add_chat_message(player_id: int, message: String):
	var complete_message: String = "[player %d]: %s" % [player_id, message]

	var label: RichTextLabel = RichTextLabel.new()
	label.append_text(complete_message)
	label.fit_content = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_theme_type_variation("RichTextLabelLarge")

	label.modulate = Color.WHITE
	var modulate_tween: Tween = create_tween()
	modulate_tween.tween_property(label, "modulate",
		Color(label.modulate.r, label.modulate.g, label.modulate.b, 0),
		CHAT_FADE_DURATION).set_delay(CHAT_DELAY_BEFORE_FADE_START)

	_chat_message_container.add_child(label)

	var label_count: int = _chat_message_container.get_children().size()
	var reached_max: bool = label_count >= CHAT_MESSAGE_MAX + 1

	if reached_max:
		var child_list: Array = _chat_message_container.get_children()
		var last_label: RichTextLabel = child_list.front()

		_chat_message_container.remove_child(last_label)
		last_label.queue_free()


func enable_extra_recipes():
	_item_stash_menu.enable_extra_recipes()


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


func hide_roll_towers_button():
	_elements_tower_menu.hide_roll_towers_button()


func update_element_level(element_levels: Dictionary):
	_elements_tower_menu.update_element_level(element_levels)


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


func set_game_start_timer(timer: ManualTimer):
	_top_left_menu.set_game_start_timer(timer)


func set_local_builder_name(builder_name: String):
	_top_left_menu.set_local_builder_name(builder_name)


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


func _on_local_player_horadric_stash_changed():
	var local_player: Player = PlayerManager.get_local_player()
	var horadric_stash: ItemContainer = local_player.get_horadric_stash()
	var item_list: Array[Item] = horadric_stash.get_item_list()
	
	_item_stash_menu.set_items_for_horadric_cube(item_list)


func _on_local_player_tower_stash_changed():
	var local_player: Player = PlayerManager.get_local_player()
	var tower_stash: TowerStash = local_player.get_tower_stash()
	var towers: Dictionary = tower_stash.get_towers()
	
	_elements_tower_menu.set_towers(towers)


func _on_local_team_level_changed():
	update_wave_details()
	
	var local_player: Player = PlayerManager.get_local_player()
	var local_team: Team = local_player.get_team()
	var level: int = local_team.get_level()
	_elements_tower_menu.update_level(level)


func _on_creep_menu_hidden():
	_unit_status_menu_card.collapse()


func _on_tower_menu_hidden():
	_unit_status_menu_card.collapse()


func _on_element_towers_menu_hidden():
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
