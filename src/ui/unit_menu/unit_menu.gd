class_name UnitMenu extends PanelContainer


# This menu is displayed when a unit is selected. Displays
# info about towers and creeps and allows performing actions
# on them.


signal details_pressed()


const SELL_BUTTON_RESET_TIME: float = 5.0

@export var _tower_button: TowerButton
@export var _creep_button: Button
@export var _level_label: Label
@export var _reset_sell_button_timer: Timer
@export var _upgrade_button: Button
@export var _sell_button: Button
@export var _buff_container: BuffContainer
@export var _ability_grid: GridContainer
@export var _exp_bar: ProgressBarWithLabel
@export var _health_bar: ProgressBarWithLabel
@export var _mana_bar: ProgressBarWithLabel
@export var _tower_mini_details: TowerMiniDetails
@export var _creep_mini_details: CreepMiniDetails
@export var _tower_inventory_panel: ItemContainerPanel
@export var _tower_inventory_outer_panel: PanelContainer
@export var _buff_group_editor: BuffGroupEditor

var _selling_for_real: bool = false
var _unit: Unit = null
var _tower: Unit = null
var _creep: Creep = null

@onready var _visible_controls_for_tower: Array[Control] = [
	_tower_button,
	_exp_bar,
	_upgrade_button,
	_sell_button,
	_buff_group_editor,
	_tower_mini_details,
	_tower_inventory_outer_panel,
]

@onready var _visible_controls_for_creep: Array[Control] = [
	_creep_button,
	_health_bar,
	_creep_mini_details,
]


#########################
###     Built-in      ###
#########################

func _process(_delta: float):
	if _unit == null:
		return
	
	var health: int = floori(_unit.get_health())
	var health_max: int = floori(_unit.get_overall_health())
	_health_bar.set_ratio_custom(health, health_max)
	
	var mana: int = roundi(_unit.get_mana())
	var mana_max: int = roundi(_unit.get_overall_mana())
	_mana_bar.set_ratio_custom(mana, mana_max)
	
	var unit_level: int = _unit.get_level()
	
	var max_unit_level: int = Constants.MAX_LEVEL
	var owner: Player = _unit.get_player()
	
	if owner != null:
		max_unit_level = owner.get_max_tower_level()
		
	var unit_is_max_level: bool = unit_level == max_unit_level
	if !unit_is_max_level:
		var exp_for_current_level: int = Experience.get_exp_for_level(unit_level)
		var exp_for_next_level: int = Experience.get_exp_for_level(unit_level + 1)
		var current_exp: int = floori(_unit.get_exp())
		var exp_over_current_level: int = current_exp - exp_for_current_level
		var exp_until_next_level: int = exp_for_next_level - exp_for_current_level
		_exp_bar.set_ratio_custom(current_exp, exp_for_next_level)

#		NOTE: need to set ratio manually because exp bar
#		needs to display:
#		text - current total exp
#		ratio - current total exp minus exp for prev level
		var exp_ratio: float = Utils.divide_safe(exp_over_current_level, exp_until_next_level)
		_exp_bar.set_as_ratio(exp_ratio)
	else:
		var current_exp: int = floori(_unit.get_exp())
		var exp_for_max_level: int = Experience.get_exp_for_level(max_unit_level)
		_exp_bar.set_ratio_custom(current_exp, exp_for_max_level)
	
	if _tower != null:
		_update_upgrade_button()
	

#########################
###       Public      ###
#########################

func get_unit() -> Unit:
	return _unit


func set_unit(unit: Unit):
	var prev_unit: Unit = _unit
	
	_unit = unit
	_tower = unit as Tower
	_creep = unit as Creep
	
	_tower_mini_details.set_tower(_tower)
	_buff_group_editor.set_tower(_tower)

	_creep_mini_details.set_creep(_creep)
	
	if prev_unit != null:
		prev_unit.buff_list_changed.disconnect(_on_buff_list_changed)
	
		if prev_unit is Tower:
			var prev_tower: Tower = prev_unit as Tower
			prev_tower.level_changed.disconnect(_on_tower_level_changed)
	
#	NOTE: need to setup visibility before calling _load_tower() because it can further hide some controls conditionally.
	for control in _visible_controls_for_tower:
		control.visible = unit is Tower
	
	for control in _visible_controls_for_creep:
		control.visible = unit is Creep
	
	var prev_ability_list: Array = _ability_grid.get_children()
	for button in prev_ability_list:
		_ability_grid.remove_child(button)
		button.queue_free()
	
	if unit != null && unit is Tower:
		var tower_item_container: ItemContainer = _tower.get_item_container()
		_tower_inventory_panel.set_item_container(tower_item_container)
	else:
		_tower_inventory_panel.set_item_container(null)
	
	if unit != null:
		_load_unit()
	
	if unit is Tower:
		_load_tower()
	elif unit is Creep:
		_load_creep()


#########################
###      Private      ###
#########################

# Setup stuff that is generic for all unit types
func _load_unit():
	_unit.buff_list_changed.connect(_on_buff_list_changed)
	_on_buff_list_changed()
	
	var overall_mana: float = _unit.get_overall_mana()
	var unit_has_mana: bool = overall_mana > 0
	_mana_bar.visible = unit_has_mana


func _load_tower():
	_tower.level_changed.connect(_on_tower_level_changed)
	_update_level_label()

	_update_sell_tooltip()
	_setup_tower_ability_buttons()

	var tower_id: int = _tower.get_id()
	_tower_button.set_tower_id(tower_id)
	_tower_button.set_tier_visible(true)

	_set_selling_for_real(false)

	var game_mode: GameMode.enm = Globals.get_game_mode()
	var upgrade_button_should_be_visible: bool = game_mode == GameMode.enm.BUILD || game_mode == GameMode.enm.RANDOM_WITH_UPGRADES
	_upgrade_button.visible = upgrade_button_should_be_visible


func _load_creep():
	var icon: Texture2D = UnitIcons.get_creep_icon(_creep)
	_creep_button.set_button_icon(icon)

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
	var button_data_list: Array[AbilityButton.Data] = _tower.get_ability_button_data_list()
	
	for button_data in button_data_list:
		var button: AbilityButton = AbilityButton.make_from_data(button_data)
		_ability_grid.add_child(button)
		_connect_to_ability_button(button)

	var tower_id: int = _tower.get_id()
	
	var ability_id_list: Array = TowerProperties.get_ability_id_list(tower_id)
	for ability_id in ability_id_list:
		var button: AbilityButton = AbilityButton.make_from_ability_id(ability_id)
		_ability_grid.add_child(button)
		_connect_to_ability_button(button)

	var aura_id_list: Array = TowerProperties.get_aura_id_list(tower_id)
	for aura_id in aura_id_list:
		var aura_is_hidden: bool = AuraProperties.get_is_hidden(aura_id)
		if aura_is_hidden:
			continue

		var button: AbilityButton = AbilityButton.make_from_aura_id(aura_id)
		_ability_grid.add_child(button)
		_connect_to_ability_button(button)

#	NOTE: add padding buttons so that autocasts abilities go
#	on the second row (for visual separation). If there are
#	too many passive abilities, then some of them will go to
#	second row.
	var ability_count_without_autocasts: int = _ability_grid.get_child_count()
	var column_count: int = _ability_grid.get_columns()
	if ability_count_without_autocasts < column_count:
		var first_row_pad_count: int = column_count - ability_count_without_autocasts

		_pad_ability_grid(first_row_pad_count)

	var autocast_list: Array[Autocast] = _tower.get_autocast_list()
	for autocast in autocast_list:
		var autocast_button: AutocastButton = AutocastButton.make(autocast)  
		_ability_grid.add_child(autocast_button)
		_connect_to_autocast_button(autocast_button)

	var second_row_pad_count: int = column_count * 2 - _ability_grid.get_child_count()
	_pad_ability_grid(second_row_pad_count)


func _setup_creep_ability_buttons():
	var button_data_list: Array[AbilityButton.Data] = _creep.get_ability_button_data_list()
	
	for button_data in button_data_list:
		var button: AbilityButton = AbilityButton.make_from_data(button_data)
		_ability_grid.add_child(button)
		_connect_to_ability_button(button)

	var column_count: int = _ability_grid.get_columns()
	var pad_count: int = column_count * 2 - _ability_grid.get_child_count()
	_pad_ability_grid(pad_count)


func _pad_ability_grid(pad_count: int):
	for i in range(0, pad_count):
		var padding_button: EmptyUnitButton = Preloads.empty_slot_button_scene.instantiate()
		padding_button.custom_minimum_size = Constants.ABILITY_BUTTON_SIZE
		_ability_grid.add_child(padding_button)


func _update_level_label():
	_level_label.text = str(_tower.get_level())


# NOTE: upgrade button is disabled when wave/research
# requirements are not satisfied. Gold/tomes/food costs are
# not considered and this is on purpose.
func _update_upgrade_button():
	var upgrade_id: int = TowerProperties.get_upgrade_id_for_tower(_tower.get_id())

	var can_upgrade: bool
	if upgrade_id != -1:
		var local_player: Player = PlayerManager.get_local_player()
		var requirements_are_satisfied: bool = TowerProperties.requirements_are_satisfied(upgrade_id, local_player)
		can_upgrade = requirements_are_satisfied
	else:
		can_upgrade = false

	_upgrade_button.set_disabled(!can_upgrade)


func _update_sell_tooltip():
	var game_mode: GameMode.enm = Globals.get_game_mode()
	var sell_ratio: float = GameMode.get_sell_ratio(game_mode)
	var sell_ratio_string: String = Utils.format_percent(sell_ratio, 0)
	var tower_id: int = _tower.get_id()
	var sell_price: int = TowerProperties.get_sell_price(tower_id)
	var tooltip: String = tr("SELL_TOWER_BUTTON_TOOLTIP").format({GOLD_AMOUNT = sell_price, SELL_RATIO = sell_ratio_string})

	_sell_button.set_tooltip_text(tooltip)


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
	var autocast_name_english: String = autocast.get_name_english()
	_tower.set_range_indicator_visible(autocast_name_english, value)


func _set_ability_range_visible(button: AbilityButton, value: bool):
	if _tower == null:
		return

	var ability_name_english: String = button.get_ability_name_english()
	_tower.set_range_indicator_visible(ability_name_english, value)

#########################
###     Callbacks     ###
#########################

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


func _on_buff_list_changed():
	_buff_container.load_buffs_for_unit(_unit)


func _on_upgrade_button_mouse_entered():
	var upgrade_id: int = TowerProperties.get_upgrade_id_for_tower(_tower.get_id())

	var local_player: Player = PlayerManager.get_local_player()

	var tooltip: String
	if upgrade_id != -1:
		tooltip = "[color=GOLD]%s[/color]\n" % tr("UPGRADE_TOWER_BUTTON_TITLE") \
		+ " \n" \
		+ RichTexts.get_tower_text(upgrade_id, local_player)
	else:
		tooltip = tr("UPGRADE_TOWER_BUTTON_CANNOT_UPGRADE")

	ButtonTooltip.show_tooltip(_upgrade_button, tooltip, ButtonTooltip.Location.BOTTOM)


# When tower menu is closed, deselect the unit which will
# also close the menu
func _on_close_button_pressed():
	hide()


func _on_tower_level_changed(_level_increased: bool):
	_update_level_label()


func _on_autocast_button_mouse_entered(button: AutocastButton):
	_set_autocast_range_visible(button, true)


func _on_autocast_button_mouse_exited(button: AutocastButton):
	_set_autocast_range_visible(button, false)


func _on_ability_button_mouse_entered(button: AbilityButton):
	_set_ability_range_visible(button, true)


func _on_ability_button_mouse_exited(button: AbilityButton):
	_set_ability_range_visible(button, false)


func _on_details_button_pressed():
	details_pressed.emit()


# NOTE: need to clear current unit when hiding to avoid
# leaving invalid references in case unit got removed from
# the game
func _on_hidden():
	set_unit(null)
