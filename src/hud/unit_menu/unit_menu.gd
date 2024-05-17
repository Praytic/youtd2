class_name UnitMenu extends PanelContainer


# This menu is displayed when a unit is selected. Displays
# info about towers and creeps and allows performing actions
# on them.


const SELL_BUTTON_RESET_TIME: float = 5.0

@export var _tower_button: TowerButton
@export var _creep_button: UnitButton
@export var _level_label: Label
@export var _reset_sell_button_timer: Timer
@export var _upgrade_button: Button
@export var _sell_button: Button
@export var _inventory_empty_grid: GridContainer
@export var _inventory_grid: GridContainer
@export var _buff_container: BuffContainer
@export var _buff_group_container: BoxContainer
@export var _buff_group_button_1: BuffGroupButton
@export var _buff_group_button_2: BuffGroupButton
@export var _buff_group_button_3: BuffGroupButton
@export var _buff_group_button_4: BuffGroupButton
@export var _buff_group_button_5: BuffGroupButton
@export var _buff_group_button_6: BuffGroupButton
@export var _ability_grid: GridContainer
@export var _exp_bar: ProgressBarWithLabel
@export var _health_bar: ProgressBarWithLabel
@export var _mana_bar: ProgressBarWithLabel

var _selling_for_real: bool = false
var _unit: Unit = null
var _tower: Unit = null
var _creep: Creep = null

@onready var _buff_group_button_list: Array[BuffGroupButton] = [
	_buff_group_button_1,
	_buff_group_button_2,
	_buff_group_button_3,
	_buff_group_button_4,
	_buff_group_button_5,
	_buff_group_button_6,
]

@onready var _visible_controls_for_tower: Array[Control] = [
	_tower_button,
	_exp_bar,
	_upgrade_button,
	_sell_button,
	_buff_group_container,
	_buff_group_container,
]

@onready var _visible_controls_for_creep: Array[Control] = [
	_creep_button,
	_health_bar,
]

#########################
###     Built-in      ###
#########################

func _ready():
	_tower_button.set_tooltip_location(ButtonTooltip.Location.BOTTOM)


func _process(_delta: float):
	if _unit == null:
		return
	
	var health: int = floori(_unit.get_health())
	var health_max: int = floori(_unit.get_overall_health())
	var health_ratio: float = _unit.get_health_ratio()
	var health_string: String = "%d/%d" % [floori(health), floori(health_max)]
	_health_bar.set_text(health_string)
	_health_bar.set_as_ratio(health_ratio)
	
	var mana: float = _unit.get_mana()
	var mana_max: float = _unit.get_overall_mana()
	var mana_ratio: float = _unit.get_mana_ratio()
	var mana_string: String = "%d/%d" % [floori(mana), floori(mana_max)]
	_mana_bar.set_text(mana_string)
	_mana_bar.set_as_ratio(mana_ratio)
	
	var unit_level: int = _unit.get_level()
	var unit_is_max_level: bool = unit_level == Constants.MAX_LEVEL
	if !unit_is_max_level:
		var exp_for_current_level: int = Experience.get_exp_for_level(unit_level)
		var exp_for_next_level: int = Experience.get_exp_for_level(unit_level + 1)
		var current_exp: int = floori(_unit.get_exp())
		var exp_over_current_level: int = current_exp - exp_for_current_level
		var exp_until_next_level: int = exp_for_next_level - exp_for_current_level
		var exp_ratio: float = Utils.divide_safe(exp_over_current_level, exp_until_next_level)
		var exp_string: String = "%d/%d" % [current_exp, exp_for_next_level]
		_exp_bar.set_text(exp_string)
		_exp_bar.set_as_ratio(exp_ratio)
	else:
		var current_exp: int = floori(_unit.get_exp())
		var exp_for_max_level: int = Experience.get_exp_for_level(Constants.MAX_LEVEL)
		var exp_string: String = "%d/%d" % [current_exp, exp_for_max_level]
		_exp_bar.set_text(exp_string)
		_exp_bar.set_as_ratio(1.0)


#########################
###       Public      ###
#########################

func set_unit(unit: Unit):
	var prev_unit: Unit = _unit
	
	_unit = unit
	_tower = unit as Tower
	_creep = unit as Creep
	
	if prev_unit != null:
		prev_unit.buff_list_changed.disconnect(_on_buff_list_changed)
	
		if prev_unit is Tower:
			var prev_tower: Tower = prev_unit as Tower
			prev_tower.level_up.disconnect(_on_tower_level_up)
			prev_tower.items_changed.disconnect(_on_tower_items_changed)
	
#	NOTE: need to setup visibility before calling _load_tower() because it can further hide some controls conditionally.
	for control in _visible_controls_for_tower:
		control.visible = unit is Tower
	
	for control in _visible_controls_for_creep:
		control.visible = unit is Creep
	
	if unit != null:
		_load_unit()
	
	if unit is Tower:
		_load_tower()
	elif unit is Creep:
		_load_creep()


#########################
###      Private      ###
#########################

func _load_unit():
	_unit.buff_list_changed.connect(_on_buff_list_changed)
	_on_buff_list_changed()
	
	var overall_mana: float = _unit.get_overall_mana()
	var unit_has_mana: bool = overall_mana > 0
	_mana_bar.visible = unit_has_mana

	var prev_button_list: Array = _ability_grid.get_children()
	for button in prev_button_list:
		_ability_grid.remove_child(button)
		button.queue_free()


func _load_tower():
	for button in _buff_group_button_list:
		button.set_tower(_tower)

	_tower.items_changed.connect(_on_tower_items_changed)
	_on_tower_items_changed()

	_tower.level_up.connect(_on_tower_level_up)
	_update_level_label()

	var inventory_capacity: int = _tower.get_inventory_capacity()
	_update_inventory_empty_slots(inventory_capacity)
	_update_sell_tooltip()
	_setup_tower_ability_buttons()

	var tower_id: int = _tower.get_id()
	_tower_button.set_tower_id(tower_id)
	_tower_button.set_tier_visible(true)

	_set_selling_for_real(false)

	var tower_belongs_to_local_player: bool = _tower.belongs_to_local_player()

	var game_mode: GameMode.enm = Globals.get_game_mode()
	var upgrade_button_should_be_visible: bool = game_mode == GameMode.enm.BUILD || game_mode == GameMode.enm.RANDOM_WITH_UPGRADES
	_upgrade_button.visible = upgrade_button_should_be_visible && tower_belongs_to_local_player
	_sell_button.visible = tower_belongs_to_local_player
	_buff_group_container.visible = tower_belongs_to_local_player


func _load_creep():
	var icon: Texture2D = UnitIcons.get_creep_icon(_creep)
	_creep_button.set_icon(icon)

	var empty_item_list: Array[Item] = []
	_load_items(empty_item_list)
	_update_inventory_empty_slots(0)
	
	_setup_creep_ability_buttons()

	var creep_level: int = _creep.get_spawn_level()
	_level_label.text = str(creep_level)


func _connect_to_ability_button(button: AbilityButton):
	button.mouse_entered.connect(_on_ability_button_mouse_entered.bind(button))
	
	button.mouse_exited.connect(_on_ability_button_mouse_exited.bind(button))
	button.tree_exited.connect(_on_ability_button_mouse_exited.bind(button))
	button.hidden.connect(_on_ability_button_mouse_exited.bind(button))


func _connect_to_autocast_button(button: AutocastButton):
	button.mouse_entered.connect(_on_autocast_button_mouse_entered.bind(button))

	button.mouse_exited.connect(_on_autocast_button_mouse_exited.bind(button))
	button.tree_exited.connect(_on_autocast_button_mouse_exited.bind(button))
	button.hidden.connect(_on_autocast_button_mouse_exited.bind(button))


func _setup_tower_ability_buttons():	
	var ability_info_list: Array[AbilityInfo] = _tower.get_ability_info_list()
	
	for ability_info in ability_info_list:
		var button: AbilityButton = AbilityButton.make(ability_info)
		_ability_grid.add_child(button)
		_connect_to_ability_button(button)

	var aura_type_list: Array[AuraType] = _tower.get_aura_types()
	for aura_type in aura_type_list:
		if aura_type.is_hidden:
			continue

		var button: AbilityButton = AbilityButton.make_from_aura_type(aura_type)
		_ability_grid.add_child(button)
		_connect_to_ability_button(button)

	var autocast_list: Array[Autocast] = _tower.get_autocast_list()
	for autocast in autocast_list:
		var autocast_button: AutocastButton = AutocastButton.make(autocast)  
		_ability_grid.add_child(autocast_button)
		_connect_to_autocast_button(autocast_button)


func _setup_creep_ability_buttons():
	var ability_info_list: Array[AbilityInfo] = _creep.get_ability_info_list()
	
	for ability_info in ability_info_list:
		var button: AbilityButton = AbilityButton.make(ability_info)
		_ability_grid.add_child(button)
		_connect_to_ability_button(button)


func _update_level_label():
	_level_label.text = str(_tower.get_level())


# Show the number of empty slots equal to tower's inventory
# capacity
func _update_inventory_empty_slots(inventory_capacity: int):
	var inventory_empty_slots: Array[Node] = _inventory_empty_grid.get_children()

#	NOTE: need to make slots transparent instead of
#	invisible to have correct size for grid container
	for i in range(0, inventory_empty_slots.size()):
		var slot: Control = inventory_empty_slots[i] as Control
		var slot_is_available: bool = i < inventory_capacity
		var slot_color: Color
		if slot_is_available:
			slot_color = Color.WHITE
		else:
			slot_color = Color.TRANSPARENT
		slot.modulate = slot_color


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


func _update_sell_tooltip():
	var game_mode: GameMode.enm = Globals.get_game_mode()
	var sell_ratio: float = GameMode.get_sell_ratio(game_mode)
	var sell_ratio_string: String = Utils.format_percent(sell_ratio, 0)
	var tower_id: int = _tower.get_id()
	var sell_price: int = TowerProperties.get_sell_price(tower_id)
	var tooltip: String = "Sell tower\nYou will receive %d gold (%s of original cost)." % [sell_price, sell_ratio_string]

	_sell_button.set_tooltip_text(tooltip)


func _get_tooltip_for_info_label() -> String:
	var attack_type: AttackType.enm = _tower.get_attack_type()
	var attack_type_name: String = AttackType.convert_to_colored_string(attack_type)
	var text_for_damage_against: String = AttackType.get_rich_text_for_damage_dealt(attack_type)

	var tooltip: String = ""
	tooltip += "%s attacks deal this much damage against armor types:\n" % attack_type_name
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


func _set_autocast_range_visible(button: AutocastButton, value: bool):
	if _tower == null:
		return

	var autocast: Autocast = button.get_autocast()
	var autocast_name: String = autocast.title
	_tower.set_range_indicator_visible(autocast_name, value)


func _set_ability_range_visible(button: AbilityButton, value: bool):
	if _tower == null:
		return

	var ability_name: String = button.get_ability_name()
	_tower.set_range_indicator_visible(ability_name, value)


#########################
###     Callbacks     ###
#########################

func _on_tower_items_changed():
	var item_list: Array[Item] = _tower.get_items()
	_load_items(item_list)


func _load_items(item_list: Array[Item]):
	for item_button in _inventory_grid.get_children():
		_inventory_grid.remove_child(item_button)
		item_button.queue_free()

	for item in item_list:
		var item_button: ItemButton = ItemButton.make(item)
		item_button.show_cooldown_indicator()
		item_button.show_auto_mode_indicator()
		item_button.show_charges()
		item_button.set_tooltip_location(ButtonTooltip.Location.BOTTOM)
		_inventory_grid.add_child(item_button)
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


#func _on_details_button_pressed():
#	var new_tab: int
#	if _tab_container.current_tab == Tabs.MAIN:
#		new_tab = Tabs.DETAILS
#	else:
#		new_tab = Tabs.MAIN
#
#	_tab_container.set_current_tab(new_tab)


func _on_buff_list_changed():
	_buff_container.load_buffs_for_unit(_unit)


func _on_upgrade_button_mouse_entered():
	var upgrade_id: int = TowerProperties.get_upgrade_id_for_tower(_tower.get_id())

	var local_player: Player = PlayerManager.get_local_player()

	var tooltip: String
	if upgrade_id != -1:
		tooltip = RichTexts.get_tower_text(upgrade_id, local_player)
	else:
		tooltip = "Cannot upgrade any further."

	ButtonTooltip.show_tooltip(_upgrade_button, tooltip, ButtonTooltip.Location.BOTTOM)


# When tower menu is closed, deselect the unit which will
# also close the menu
func _on_close_button_pressed():
	hide()


func _on_tower_level_up(_level_increased: bool):
	_update_level_label()


func _on_autocast_button_mouse_entered(button: AutocastButton):
	_set_autocast_range_visible(button, true)


func _on_autocast_button_mouse_exited(button: AutocastButton):
	_set_autocast_range_visible(button, false)


func _on_ability_button_mouse_entered(button: AbilityButton):
	_set_ability_range_visible(button, true)


func _on_ability_button_mouse_exited(button: AbilityButton):
	_set_ability_range_visible(button, false)


func _on_inventory_grid_gui_input(event):
	var left_click: bool = event.is_action_released("left_click")

	if left_click:
		EventBus.player_clicked_tower_inventory.emit(_tower)
