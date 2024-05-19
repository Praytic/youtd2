class_name UnitMenu extends PanelContainer


# This menu is displayed when a unit is selected. Displays
# info about towers and creeps and allows performing actions
# on them.


signal details_pressed()


const SELL_BUTTON_RESET_TIME: float = 5.0
const ABILITY_BUTTON_SIZE: Vector2 = Vector2(100, 100)

@export var _tower_button: TowerButton
@export var _creep_button: UnitButton
@export var _level_label: Label
@export var _reset_sell_button_timer: Timer
@export var _upgrade_button: Button
@export var _sell_button: Button
@export var _inventory_background_grid: GridContainer
@export var _inventory_slot_grid: GridContainer
@export var _inventory_item_grid: GridContainer
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
@export var _dmg_stats_left: RichTextLabel
@export var _dmg_stats_right: RichTextLabel
@export var _support_stats_label: RichTextLabel
@export var _dmg_against_left: RichTextLabel
@export var _dmg_against_right: RichTextLabel
@export var _oils_label: RichTextLabel
@export var _stats_panel: TabContainer
@export var _inventory_panel: PanelContainer

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
	_stats_panel,
	_inventory_panel,
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
	
	if _tower != null:
		_update_stats_panel()
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
	
#	Clear elements from previous unit
	_clear_item_buttons()

	var prev_ability_list: Array = _ability_grid.get_children()
	for button in prev_ability_list:
		_ability_grid.remove_child(button)
		button.queue_free()
	
	if unit != null:
		_load_unit()
	
	if unit is Tower:
		_load_tower()
	elif unit is Creep:
		_load_creep()


#########################
###      Private      ###
#########################

func _clear_item_buttons():
	for item_button in _inventory_item_grid.get_children():
		_inventory_item_grid.remove_child(item_button)
		item_button.queue_free()


# Setup stuff that is generic for all unit types
func _load_unit():
	_unit.buff_list_changed.connect(_on_buff_list_changed)
	_on_buff_list_changed()
	
	var overall_mana: float = _unit.get_overall_mana()
	var unit_has_mana: bool = overall_mana > 0
	_mana_bar.visible = unit_has_mana


func _load_tower():
	for button in _buff_group_button_list:
		button.set_tower(_tower)

	_tower.items_changed.connect(_on_tower_items_changed)
	_update_inventory()

	_tower.level_up.connect(_on_tower_level_up)
	_update_level_label()

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
	var ability_info_list: Array[AbilityInfo] = _creep.get_ability_info_list()
	
	for ability_info in ability_info_list:
		var button: AbilityButton = AbilityButton.make(ability_info)
		_ability_grid.add_child(button)
		_connect_to_ability_button(button)

	var column_count: int = _ability_grid.get_columns()
	var pad_count: int = column_count * 2 - _ability_grid.get_child_count()
	_pad_ability_grid(pad_count)


func _pad_ability_grid(pad_count: int):
	for i in range(0, pad_count):
		var padding_button: EmptyUnitButton = Preloads.empty_slot_button_scene.instantiate()
		padding_button.custom_minimum_size = ABILITY_BUTTON_SIZE
		_ability_grid.add_child(padding_button)


func _update_level_label():
	_level_label.text = str(_tower.get_level())


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


func _update_stats_panel():
	var dmg_stats_left_text: String = _get_dmg_stats_left_text()
	_dmg_stats_left.clear()
	_dmg_stats_left.append_text(dmg_stats_left_text)
	
	var dmg_stats_right_text: String = _get_dmg_stats_right_text()
	_dmg_stats_right.clear()
	_dmg_stats_right.append_text(dmg_stats_right_text)
	
	var support_stats_text: String = _get_support_stats_text()
	_support_stats_label.clear()
	_support_stats_label.append_text(support_stats_text)
	
	var dmg_against_left_text: String = _get_dmg_against_left_text()
	_dmg_against_left.clear()
	_dmg_against_left.append_text(dmg_against_left_text)
	
	var dmg_against_right_text: String = _get_dmg_against_right_text()
	_dmg_against_right.clear()
	_dmg_against_right.append_text(dmg_against_right_text)
	
	var oils_text: String = _get_tower_oils_text()
	_oils_label.clear()
	_oils_label.append_text(oils_text)


func _get_dmg_stats_left_text() -> String:
	var overall_damage: float = _tower.get_overall_damage()
	var overall_damage_string: String = TowerDetails.int_format(roundi(overall_damage))

	var overall_cooldown: float = _tower.get_current_attack_speed()
	var overall_cooldown_string: String = Utils.format_float(overall_cooldown, 2)

	var crit_chance: float = _tower.get_prop_atk_crit_chance()
	var crit_chance_string: String = Utils.format_percent(crit_chance, 1)

	var crit_damage: float = _tower.get_prop_atk_crit_damage()
	var crit_damage_string: String = TowerDetails.multiplier_format(crit_damage)

	var multicrit: int = _tower.get_prop_multicrit_count()
	var multicrit_string: String = TowerDetails.int_format(multicrit)

	var overall_dps: float = _tower.get_overall_dps()
	var overall_dps_string: String = TowerDetails.int_format(roundi(overall_dps))

	var dps_with_crit: float = _tower.get_dps_with_crit()
	var dps_with_crit_string: String = TowerDetails.int_format(roundi(dps_with_crit))

	var text: String = "" \
	+ "[hint=Attack damage][img=30 color=eb4f34]res://resources/icons/generic_icons/hammer_drop.tres[/img] %s[/hint]\n" % overall_damage_string \
	+ "[hint=Attack speed][img=30 color=eb8f34]res://resources/icons/generic_icons/hourglass.tres[/img] %s[/hint]\n" % overall_cooldown_string \
	+ "[hint=Attack crit chance][img=30 color=eb3495]res://resources/icons/generic_icons/root_tip.tres[/img] %s[/hint]\n" % crit_chance_string \
	+ "[hint=Attack crit damage][img=30 color=eb3495]res://resources/icons/generic_icons/mine_explosion.tres[/img] %s[/hint]\n" % crit_damage_string \
	+ "[hint=Multicrit][img=30 color=de3535]res://resources/icons/generic_icons/triple_scratches.tres[/img] %s[/hint]\n" % multicrit_string \
	+ "[hint=DPS][img=30 color=e85831]res://resources/icons/generic_icons/open_wound.tres[/img] %s[/hint]\n" % overall_dps_string \
	+ "[hint=DPS with crit][img=30 color=e83140]res://resources/icons/generic_icons/open_wound.tres[/img] %s[/hint]\n" % dps_with_crit_string \
	+ ""

	return text


func _get_dmg_stats_right_text() -> String:
	var spell_damage: float = _tower.get_prop_spell_damage_dealt()
	var spell_damage_string: String = Utils.format_percent(spell_damage, 0)
	
	var spell_crit_chance: float = _tower.get_spell_crit_chance()
	var spell_crit_chance_string: String = Utils.format_percent(spell_crit_chance, 1)

	var spell_crit_damage: float = _tower.get_spell_crit_damage()
	var spell_crit_damage_string: String = TowerDetails.multiplier_format(spell_crit_damage)

	var overall_mana_regen: float = _tower.get_overall_mana_regen()
	var overall_mana_regen_string: String = Utils.format_float(overall_mana_regen, 1)

	var text: String = "" \
	+ "[hint=Mana regen][img=30 color=31cde8]res://resources/icons/generic_icons/rolling_energy.tres[/img] %s[/hint]\n" % overall_mana_regen_string \
	+ "[hint=Spell damage bonus][img=30 color=31e896]res://resources/icons/generic_icons/flame.tres[/img] %s[/hint]\n" % spell_damage_string \
	+ "[hint=Spell crit chance][img=30 color=35a8de]res://resources/icons/generic_icons/root_tip.tres[/img] %s[/hint]\n" % spell_crit_chance_string \
	+ "[hint=Spell crit damage][img=30 color=35a8de]res://resources/icons/generic_icons/mine_explosion.tres[/img] %s[/hint]\n" % spell_crit_damage_string \
	+ ""

	return text


func _get_support_stats_text() -> String:
	var bounty_ratio: float = _tower.get_prop_bounty_received()
	var bounty_ratio_string: String = Utils.format_percent(bounty_ratio, 0)

	var exp_ratio: float = _tower.get_prop_exp_received()
	var exp_ratio_string: String = Utils.format_percent(exp_ratio, 0)

	var item_drop_ratio: float = _tower.get_item_drop_ratio()
	var item_drop_ratio_string: String = Utils.format_percent(item_drop_ratio, 0)

	var item_quality_ratio: float = _tower.get_item_quality_ratio()
	var item_quality_ratio_string: String = Utils.format_percent(item_quality_ratio, 0)

	var trigger_chances: float = _tower.get_prop_trigger_chances()
	var trigger_chances_string: String = Utils.format_percent(trigger_chances, 0)

	var buff_duration: float = _tower.get_prop_buff_duration()
	var buff_duration_string: String = Utils.format_percent(buff_duration, 0)

	var debuff_duration: float = _tower.get_prop_debuff_duration()
	var debuff_duration_string: String = Utils.format_percent(debuff_duration, 0)

	var text: String = "" \
	+ "[hint=Bounty ratio][img=30 color=deca35]res://resources/icons/generic_icons/shiny_omega.tres[/img] %s[/hint]\n" % bounty_ratio_string \
	+ "[hint=Exp ratio][img=30 color=9630f0]res://resources/icons/generic_icons/moebius_trefoil.tres[/img] %s[/hint]\n" % exp_ratio_string \
	+ "[hint=Item chance][img=30 color=bcde35]res://resources/icons/generic_icons/polar_star.tres[/img] %s[/hint]\n" % item_drop_ratio_string \
	+ "[hint=Item quality][img=30 color=c2ae3c]res://resources/icons/generic_icons/gold_bar.tres[/img] %s[/hint]\n" % item_quality_ratio_string \
	+ "[hint=Trigger chances][img=30 color=35ded5]res://resources/icons/generic_icons/cog.tres[/img] %s[/hint]\n" % trigger_chances_string \
	+ "[hint=Buff duration][img=30 color=49c23c]res://resources/icons/generic_icons/hourglass.tres[/img] %s[/hint]\n" % buff_duration_string \
	+ "[hint=Debuff duration][img=30 color=c2433c]res://resources/icons/generic_icons/hourglass.tres[/img] %s[/hint]\n" % debuff_duration_string \
	+ ""

	return text


func _get_dmg_against_left_text() -> String:
	var dmg_to_undead: float = _tower.get_damage_to_undead()
	var dmg_to_undead_string: String = Utils.format_percent(dmg_to_undead, 0)

	var dmg_to_magic: float = _tower.get_damage_to_magic()
	var dmg_to_magic_string: String = Utils.format_percent(dmg_to_magic, 0)

	var dmg_to_nature: float = _tower.get_damage_to_nature()
	var dmg_to_nature_string: String = Utils.format_percent(dmg_to_nature, 0)

	var dmg_to_orc: float = _tower.get_damage_to_orc()
	var dmg_to_orc_string: String = Utils.format_percent(dmg_to_orc, 0)

	var dmg_to_humanoid: float = _tower.get_damage_to_humanoid()
	var dmg_to_humanoid_string: String = Utils.format_percent(dmg_to_humanoid, 0)

	var text: String = "" \
	+ "[hint=Damage to Undead][img=30 color=9370db]res://resources/icons/generic_icons/animal_skull.tres[/img] %s[/hint]\n" % dmg_to_undead_string \
	+ "[hint=Damage to Magic][img=30 color=6495ed]res://resources/icons/generic_icons/polar_star.tres[/img] %s[/hint]\n" % dmg_to_magic_string \
	+ "[hint=Damage to Nature][img=30 color=32cd32]res://resources/icons/generic_icons/root_tip.tres[/img] %s[/hint]\n" % dmg_to_nature_string \
	+ "[hint=Damage to Orc][img=30 color=8fbc8f]res://resources/icons/generic_icons/orc_head.tres[/img] %s[/hint]\n" % dmg_to_orc_string \
	+ "[hint=Damage to Humanoid][img=30 color=d2b48c]res://resources/icons/generic_icons/armor_vest.tres[/img] %s[/hint]\n" % dmg_to_humanoid_string \
	+ ""
	
	return text


func _get_dmg_against_right_text() -> String:
	var dmg_to_mass: float = _tower.get_damage_to_mass()
	var dmg_to_mass_string: String = Utils.format_percent(dmg_to_mass, 0)

	var dmg_to_normal: float = _tower.get_damage_to_magic()
	var dmg_to_normal_string: String = Utils.format_percent(dmg_to_normal, 0)

	var dmg_to_air: float = _tower.get_damage_to_air()
	var dmg_to_air_string: String = Utils.format_percent(dmg_to_air, 0)

	var dmg_to_champion: float = _tower.get_damage_to_champion()
	var dmg_to_champion_string: String = Utils.format_percent(dmg_to_champion, 0)

	var dmg_to_boss: float = _tower.get_damage_to_boss()
	var dmg_to_boss_string: String = Utils.format_percent(dmg_to_boss, 0)

	var text: String = "" \
	+ "[hint=Damage to Mass][img=30 color=ffa500]res://resources/icons/generic_icons/sprint.tres[/img] %s[/hint]\n" % dmg_to_mass_string \
	+ "[hint=Damage to Normal][img=30 color=8fbc8f]res://resources/icons/generic_icons/barbute.tres[/img] %s[/hint]\n" % dmg_to_normal_string \
	+ "[hint=Damage to Air][img=30 color=6495ed]res://resources/icons/generic_icons/liberty_wing.tres[/img] %s[/hint]\n" % dmg_to_air_string \
	+ "[hint=Damage to Champion][img=30 color=9370db]res://resources/icons/generic_icons/horned_helm.tres[/img] %s[/hint]\n" % dmg_to_champion_string \
	+ "[hint=Damage to Boss][img=30 color=ff4500]res://resources/icons/generic_icons/bat_mask.tres[/img] %s[/hint]\n" % dmg_to_boss_string \
	+ ""
	
	return text


func _get_tower_oils_text() -> String:
	var oil_count_map: Dictionary = _get_oil_count_map()
	
	if oil_count_map.is_empty():
		return "No oils applied."

	var text: String = ""

	var oil_name_list: Array = oil_count_map.keys()
	oil_name_list.sort()

	for oil_name in oil_name_list:
		var count: int = oil_count_map[oil_name]

		text += "%s x %s\n" % [str(count), oil_name]

	return text


func _get_oil_count_map() -> Dictionary:
	var oil_list: Array[Item] = _tower.get_item_container().get_oil_list()

	var oil_count_map: Dictionary = {}

	for oil in oil_list:
		var oil_id: int = oil.get_id()
		var oil_name: String = ItemProperties.get_display_name(oil_id)
		var oil_rarity: Rarity.enm = ItemProperties.get_rarity(oil_id)
		var rarity_color: Color = Rarity.get_color(oil_rarity)
		var oil_name_colored: String = Utils.get_colored_string(oil_name, rarity_color)

		if !oil_count_map.has(oil_name_colored):
			oil_count_map[oil_name_colored] = 0

		oil_count_map[oil_name_colored] += 1

	return oil_count_map


func _update_inventory():
	_clear_item_buttons()

	if _tower == null:
		return
	
	var inventory_capacity: int = _tower.get_inventory_capacity()
	var item_list: Array[Item] = _tower.get_items()

	for item in item_list:
		var item_button: ItemButton = ItemButton.make(item)
		item_button.show_cooldown_indicator()
		item_button.show_auto_mode_indicator()
		item_button.show_charges()
		item_button.set_tooltip_location(ButtonTooltip.Location.BOTTOM)
		_inventory_item_grid.add_child(item_button)
		item_button.pressed.connect(_on_item_button_pressed.bind(item_button))
		item_button.shift_right_clicked.connect(_on_item_button_shift_right_clicked.bind(item_button))
		item_button.right_clicked.connect(_on_item_button_right_clicked.bind(item_button))

#	Update color and visibility of grid cells, based on
#	capacity and current item count.
#	NOTE: need to make cells transparent instead of hiding.
#	This is to preserve size of grid container.
	var background_cell_list: Array[Node] = _inventory_background_grid.get_children()
	var slot_cell_list: Array[Node] = _inventory_slot_grid.get_children()
	for i in range(0, background_cell_list.size()):
		var slot_cell: Control = slot_cell_list[i] as Control
		var background_cell: Control = background_cell_list[i] as Control
		var within_capacity: bool = i < inventory_capacity
		var behind_item: bool = i < item_list.size()
	
		var background_color: Color
		if within_capacity:
			background_color = Color.WHITE
		else:
			background_color = Color.WHITE.darkened(0.6)
		background_cell.modulate = background_color

		var slot_color: Color
		if behind_item:
			slot_color = Color.TRANSPARENT
		elif within_capacity:
			slot_color = Color.WHITE.darkened(0.2)
		else:
			slot_color = Color.TRANSPARENT
		slot_cell.modulate = slot_color


#########################
###     Callbacks     ###
#########################

func _on_tower_items_changed():
	_update_inventory()


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


func _on_buff_list_changed():
	_buff_container.load_buffs_for_unit(_unit)


func _on_upgrade_button_mouse_entered():
	var upgrade_id: int = TowerProperties.get_upgrade_id_for_tower(_tower.get_id())

	var local_player: Player = PlayerManager.get_local_player()

	var tooltip: String
	if upgrade_id != -1:
		tooltip = "[color=GOLD]Upgrade tower[/color]\n" \
		+ " \n" \
		+ RichTexts.get_tower_text(upgrade_id, local_player)
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


func _on_details_button_pressed():
	details_pressed.emit()


# NOTE: need to clear current unit when hiding to avoid
# leaving invalid references in case unit got removed from
# the game
func _on_hidden():
	set_unit(null)
