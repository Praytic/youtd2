class_name TowerMenu
extends PanelContainer


enum Tabs {
	MAIN = 0,
	DETAILS = 1
}

const SELL_BUTTON_RESET_TIME: float = 5.0
const ITEMS_CONTAINER_BUTTON_SIZE: float = 82

@export var _tab_container: TabContainer
@export var _tower_button: TowerButton
@export var _title_label: Label
@export var _level_label: Label
@export var _info_label: RichTextLabel
@export var _specials_label: RichTextLabel
@export var _reset_sell_button_timer: Timer
@export var _upgrade_button: Button
@export var _sell_button: Button
@export var _details_tab: ScrollContainer
@export var _specials_scroll_container: ScrollContainer
@export var _inventory_empty_slots: HBoxContainer
@export var _items_box_container: HBoxContainer
@export var _buff_container: BuffContainer
@export var _details: TowerDetails
@export var _buff_group_container: VBoxContainer
@export var _buff_group_button_1: BuffGroupButton
@export var _buff_group_button_2: BuffGroupButton
@export var _buff_group_button_3: BuffGroupButton
@export var _buff_group_button_4: BuffGroupButton
@export var _buff_group_button_5: BuffGroupButton
@export var _buff_group_button_6: BuffGroupButton

var _selling_for_real: bool = false
var _tower: Tower = null

@onready var _buff_group_button_list: Array[BuffGroupButton] = [
	_buff_group_button_1,
	_buff_group_button_2,
	_buff_group_button_3,
	_buff_group_button_4,
	_buff_group_button_5,
	_buff_group_button_6,
]


#########################
###     Built-in      ###
#########################

func _process(_delta: float):
	if _tower == null:
		return

# 	NOTE: need to update info label every frame because it
# 	displays creep's armor stat which changes. Also need to
# 	update upgrade button because it depends on player's
# 	gold/tomes which change.
	_info_label.text = RichTexts.get_tower_info_short(_tower)
	_update_upgrade_button()


#########################
###       Public      ###
#########################

func set_tower(tower: Tower):
	var prev_tower: Tower = _tower
	_tower = tower

	_details.set_tower(tower)
	
	for button in _buff_group_button_list:
		button.set_tower(tower)

#	Reset all scroll positions when switching to a different unit
	Utils.reset_scroll_container(_specials_scroll_container)
	Utils.reset_scroll_container(_details_tab)

	if prev_tower != null and prev_tower is Tower:
		prev_tower.items_changed.disconnect(_on_tower_items_changed)
		prev_tower.buff_list_changed.disconnect(_on_buff_list_changed)
		prev_tower.level_up.disconnect(_on_tower_level_up)
	
#	NOTE: properties below are skipped if tower is null because they can't be loaded
	if tower == null:
		return
	
	tower.items_changed.connect(_on_tower_items_changed.bind(tower))
	_on_tower_items_changed(tower)
	
	tower.buff_list_changed.connect(_on_buff_list_changed.bind(tower))
	_on_buff_list_changed(tower)
	
	tower.level_up.connect(_on_tower_level_up)
	_update_level_label()

	var tower_name: String = tower.get_display_name()
	_title_label.text = tower_name

	_update_inventory_empty_slots(tower)
	_update_sell_tooltip(tower)

	var tooltip_for_info_label: String = _get_tooltip_for_info_label()
	_info_label.set_tooltip_text(tooltip_for_info_label)

	var specials_text: String = _get_specials_text(tower)
	_specials_label.clear()
	_specials_label.append_text(specials_text)

	_tower_button.set_tower_id(tower.get_id())
	
	_set_selling_for_real(false)

	var tower_belongs_to_local_player: bool = tower.belongs_to_local_player()
	
	var game_mode: GameMode.enm = Globals.get_game_mode()
	var upgrade_button_should_be_visible: bool = game_mode == GameMode.enm.BUILD || game_mode == GameMode.enm.RANDOM_WITH_UPGRADES
	_upgrade_button.visible = upgrade_button_should_be_visible && tower_belongs_to_local_player
	_sell_button.visible = tower_belongs_to_local_player
	_buff_group_container.visible = tower_belongs_to_local_player


#########################
###      Private      ###
#########################

func _get_specials_text(tower: Tower) -> String:
	var text: String = ""

	var specials_text: String = tower.get_specials_tooltip_text()
	var extra_text: String = tower.get_ability_description()

	if !specials_text.is_empty():
		text += specials_text
		text += " \n"

	if !extra_text.is_empty():
		text += extra_text
		text += " \n"

	for autocast in tower.get_autocast_list():
		var autocast_text: String = RichTexts.get_autocast_text(autocast)
		text += autocast_text
		text += " \n"
	
	text = RichTexts.add_color_to_numbers(text)

	return text


func _update_level_label():
	_level_label.text = str(_tower.get_level())


# Show the number of empty slots equal to tower's inventory
# capacity
func _update_inventory_empty_slots(tower: Tower):
	var inventory_capacity: int = tower.get_inventory_capacity()

	var inventory_slots: Array[Node] = _inventory_empty_slots.get_children()

	for i in range(0, inventory_slots.size()):
		var slot: Control = inventory_slots[i] as Control
		slot.visible = i < inventory_capacity


func _update_upgrade_button():
	var upgrade_id: int = TowerProperties.get_upgrade_id_for_tower(_tower.get_id())

	var can_upgrade: bool
	if upgrade_id != -1:
		var local_player: Player = PlayerManager.get_local_player()
		var requirements_are_satisfied: bool = TowerProperties.requirements_are_satisfied(upgrade_id, local_player)
		var enough_gold: bool = local_player.enough_gold_for_tower(upgrade_id)
		var enough_tomes: bool = local_player.enough_tomes_for_tower(upgrade_id)
		can_upgrade = requirements_are_satisfied && enough_gold && enough_tomes
	else:
		can_upgrade = false

	_upgrade_button.set_disabled(!can_upgrade)


func _update_sell_tooltip(tower: Tower):
	var game_mode: GameMode.enm = Globals.get_game_mode()
	var sell_ratio: float = GameMode.get_sell_ratio(game_mode)
	var sell_ratio_string: String = Utils.format_percent(sell_ratio, 0)
	var sell_price: int = TowerProperties.get_sell_price(tower.get_id())
	var tooltip: String = "Sell tower\nYou will receive %d gold (%s of original cost)." % [sell_price, sell_ratio_string]

	_sell_button.set_tooltip_text(tooltip)


func _get_tooltip_for_info_label() -> String:
	var attack_type: AttackType.enm = _tower.get_attack_type()
	var attack_type_name: String = AttackType.convert_to_string(attack_type).capitalize()
	var text_for_damage_against: String = AttackType.get_text_for_damage_dealt(attack_type)

	var tooltip: String = ""
	tooltip += "%s attacks deal this much damage\nagainst armor types:\n" % attack_type_name
	tooltip += text_for_damage_against

	return tooltip


func _set_selling_for_real(value: bool):
	_selling_for_real = value

	if _selling_for_real:
		_sell_button.modulate = Color(Color.CRIMSON)
	else:
		_sell_button.modulate = Color(Color.WHITE)

	if _selling_for_real:
		_reset_sell_button_timer.start(SELL_BUTTON_RESET_TIME)
	else:
		_reset_sell_button_timer.stop()


#########################
###     Callbacks     ###
#########################

func _on_tower_items_changed(tower: Tower):
	for unit_button_container in _items_box_container.get_children():
		unit_button_container.queue_free()

	var items: Array[Item] = tower.get_items()

	for item in items:
		var item_button: ItemButton = ItemButton.make(item)
		item_button.show_cooldown_indicator()
		item_button.show_auto_mode_indicator()
		item_button.theme_type_variation = "TinyUnitButton"
		item_button.show_charges()
		item_button.custom_minimum_size = Vector2(ITEMS_CONTAINER_BUTTON_SIZE, ITEMS_CONTAINER_BUTTON_SIZE)
		_items_box_container.add_child(item_button)
		item_button.pressed.connect(_on_item_button_pressed.bind(item_button))
		item_button.shift_right_clicked.connect(_on_item_button_shift_right_clicked.bind(item_button))
		item_button.right_clicked.connect(_on_item_button_right_clicked.bind(item_button))


func _on_item_button_pressed(item_button: ItemButton):
	var item: Item = item_button.get_item()
	EventBus.player_clicked_item_in_tower_inventory.emit(item)


func _on_item_button_right_clicked(item_button: ItemButton):
	var item: Item = item_button.get_item()
	EventBus.player_right_clicked_item_in_tower_inventory.emit(item)


func _on_item_button_shift_right_clicked(item_button: ItemButton):
	var item: Item = item_button.get_item()
	EventBus.player_shift_right_clicked_item_in_tower_inventory.emit(item)


func _on_upgrade_button_pressed():
	EventBus.player_requested_to_upgrade_tower.emit(_tower)

#	NOTE: hide and show upgrade button to trigger
#	mouse_entered() signal to refresh the button tooltip.
#	Note that we cannot manually call
#	_on_tower_upgrade_button_mouse_entered() because it
#	doesn't work correctly for the case where upgrade button
#	was pressed using the keyboard shortcut.
	_upgrade_button.hide()
	_upgrade_button.show()


func _on_reset_sell_button_timer_timeout():
	_set_selling_for_real(false)


func _on_sell_button_pressed():
	if !_selling_for_real:
		_set_selling_for_real(true)
		
		return

	EventBus.player_requested_to_sell_tower.emit(_tower)


func _on_details_button_pressed():
	var new_tab: int
	if _tab_container.current_tab == Tabs.MAIN:
		new_tab = Tabs.DETAILS
	else:
		new_tab = Tabs.MAIN
		
	_tab_container.set_current_tab(new_tab)


func _on_buff_list_changed(unit: Unit):
	_buff_container.load_buffs_for_unit(unit)


func _on_upgrade_button_mouse_entered():
	var upgrade_id: int = TowerProperties.get_upgrade_id_for_tower(_tower.get_id())

	var local_player: Player = PlayerManager.get_local_player()

	var tooltip: String
	if upgrade_id != -1:
		tooltip = RichTexts.get_tower_text(upgrade_id, local_player)
	else:
		tooltip = "Cannot upgrade any further."

	ButtonTooltip.show_tooltip(_upgrade_button, tooltip)


func _on_items_container_gui_input(event):
	var left_click: bool = event.is_action_released("left_click")

	if left_click:
		EventBus.player_clicked_tower_inventory.emit(_tower)


# When tower menu is closed, deselect the unit which will
# also close the menu
func _on_close_button_pressed():
	hide()


func _on_tower_level_up(_level_increased: bool):
	_update_level_label()
