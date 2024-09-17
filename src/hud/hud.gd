class_name HUD extends Control


@export var _error_message_container: VBoxContainer
@export var _normal_message_container: VBoxContainer
@export var _game_over_label: RichTextLabel
@export var _elements_menu: ElementsMenu
@export var _tower_stash_menu: TowerStashMenu
@export var _item_stash_menu: ItemStashMenu
@export var _tower_stash_button: MenuExpandingButton
@export var _item_stash_button: MenuExpandingButton
@export var _top_left_menu: TopLeftMenu
@export var _unit_menu: UnitMenu
@export var _chat_line_edit: LineEdit
@export var _desync_indicator: PanelContainer
@export var _button_tooltip_top: ButtonTooltip
@export var _button_tooltip_bottom: ButtonTooltip
@export var _tower_details: TowerDetails
@export var _creep_details: CreepDetails
@export var _ping_label: Label
@export var _players_are_lagging_indicator: MarginContainer
@export var _lagging_player_list_label: Label
@export var _multiplayer_pause_indicator: Control

# NOTE: this list is ordered by priority of closure. If
# multiple windows are open, then the first window in the
# list will be closed, others will stay.
@onready var _window_list: Array = [_tower_details, _creep_details, _elements_menu, _tower_stash_menu, _item_stash_menu]


#########################
###     Built-in      ###
#########################

func _ready():
	if OS.is_debug_build() && Config.dev_controls_enabled():
		$DevControls.call_deferred("create_instance")
	
	EventBus.item_started_flying_to_item_stash.connect(_on_item_started_flying_to_item_stash)

	ButtonTooltip.setup_tooltip_instances(_button_tooltip_top, _button_tooltip_bottom)


#########################
###       Public      ###
#########################

func set_multiplayer_pause_indicator_visible(value: bool):
	_multiplayer_pause_indicator.visible = value


func toggle_ping_indicator_visibility():
	_ping_label.visible = !_ping_label.visible


func set_waiting_for_lagging_players_indicator_visible(indicator_visible: bool):
	_players_are_lagging_indicator.visible = indicator_visible


func set_waiting_for_lagging_players_indicator_player_list(lagging_player_list: Array):
	var lagging_player_list_text: String = ""
	
	for player_name in lagging_player_list:
		lagging_player_list_text += "%s\n" % player_name

	_lagging_player_list_label.text = lagging_player_list_text


func set_ping_time(ping_time_ms: float):
	_ping_label.text = "Ping: %dms" % ceil(ping_time_ms)


func show_desync_indicator():
	_desync_indicator.show()


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
	var player_is_ignored: bool = player.get_chat_ignored()
	if player_is_ignored:
		print_verbose("Skipping chat message from ignored player %s: %s" % [player.get_player_name(), message])

		return

#	NOTE: don't need to sanitize player name here because it
#	already is sanitized.
	var player_color: Color = player.get_color()
	var player_name: String = player.get_player_name()

#	NOTE: chat message input field has a length limit but we
#	still need to limit the length here as well just in
#	case.
	message = message.substr(0, Constants.MAX_CHAT_MESSAGE_LENGTH)
	message = Utils.escape_bbcode(message)

	var complete_message: String = "[color=%s]%s:[/color] %s" % [player_color.to_html(), player_name, message]
	
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


func connect_to_local_player(local_player: Player):
	local_player.rolled_starting_towers.connect(_on_local_player_rolled_towers)
	
	_item_stash_menu.connect_to_local_player(local_player)
	_tower_stash_menu.connect_to_local_player(local_player)
	_elements_menu.connect_to_local_player(local_player)
	_top_left_menu.connect_to_local_player(local_player)

	var local_team: Team = local_player.get_team()
	local_team.game_lose.connect(_on_local_game_lose)


func set_game_start_timer(timer: ManualTimer):
	_top_left_menu.set_game_start_timer(timer)


func close_one_window():
	for window in _window_list:
		if window.visible:
			window.hide()
			break


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


# Manually press status button for tower stash menu to
# switch to tower stash menu after rolling towers.
func _on_local_player_rolled_towers():
	_tower_stash_button.set_pressed(true)


func _on_item_started_flying_to_item_stash(item: Item, canvas_pos: Vector2):
	if !item.belongs_to_local_player():
		return

	var item_stash_button_pos: Vector2 = _item_stash_button.global_position + Vector2(45, 45)
	var item_id: int = item.get_id()

	var flying_item: FlyingItem = FlyingItem.create(item_id, canvas_pos, item_stash_button_pos)
	flying_item.visible = item.is_visible()
	add_child(flying_item)


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


func _on_local_game_lose():
	_game_over_label.show()


func _on_quit_button_pressed():
	EventBus.player_requested_quit_to_title.emit()
