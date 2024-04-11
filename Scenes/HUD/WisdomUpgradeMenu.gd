class_name WisdomUpgradeMenu extends PanelContainer


# Menu where player can choose keeper of wisdom upgrades.


@export var _button_container: GridContainer
@export var _orbs_label: Label
@export var _error_label: Label


var _orb_count_total: int
var _upgrades_cached: Dictionary = {}
var _button_map: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
# 	NOTE: upgrades cache may be invalid if player manually
# 	modifies settings file or if player chooses a builder
# 	which modifies max upgrades and old cached values don't
# 	fit.
	var upgrade_id_list: Array = WisdomUpgradeProperties.get_id_list()

	for upgrade_id in upgrade_id_list:
		var button: WisdomUpgradeButton = WisdomUpgradeButton.make(upgrade_id)
		_button_container.add_child(button)
		
		button.pressed.connect(_on_button_pressed.bind(button, upgrade_id))
		
		_button_map[upgrade_id] = button


#########################
###       Public      ###
#########################

func load_wisdom_upgrades_from_settings():
	var upgrade_id_list: Array = WisdomUpgradeProperties.get_id_list()

	var player_lvl: int = _get_player_level()
	var orb_count_total_max: int = upgrade_id_list.size()
	_orb_count_total = min(orb_count_total_max, player_lvl * Constants.PLAYER_LEVEL_TO_WISDOM_ORBS)
	_upgrades_cached = _load_wisdom_upgrade_state(_orb_count_total)

	for upgrade_id in upgrade_id_list:
		var button: WisdomUpgradeButton = _button_map[upgrade_id]
		var upgrade_is_enabled: bool = _upgrades_cached[upgrade_id]
		button.set_indicator_visible(upgrade_is_enabled)

	_update_orbs_label()


#########################
###      Private      ###
#########################

func _load_wisdom_upgrade_state(orb_count_total: int) -> Dictionary:
	var result: Dictionary = Settings.get_wisdom_upgrades()

	var orb_used_count: int = _get_orb_used_count(result)
	var used_more_orbs_than_got: bool = orb_used_count > orb_count_total
	if used_more_orbs_than_got:
		push_warning("Wisdom upgrade cache is invalid! Resetting upgrades. Invalid cache = %s" % result)
		
		for key in result.keys():
			result[key] = false

	return result


func _get_orb_used_count(upgrade_state: Dictionary) -> int:
	var upgrade_id_list: Array = WisdomUpgradeProperties.get_id_list()
	var orbs_used: int = 0

	for upgrade_id in upgrade_id_list:
		var upgrade_is_enabled: bool = upgrade_state[upgrade_id]
		
		if upgrade_is_enabled:
			orbs_used += 1

	return orbs_used


func _get_player_level() -> int:
	var exp_password: String = Settings.get_setting(Settings.EXP_PASSWORD)
	var player_exp: int = ExperiencePassword.decode(exp_password)
	var player_exp_is_valid: bool = player_exp != -1
	
	if !player_exp_is_valid:
		_show_error("Experience password is invalid, resetting level to 0.")
		
		return 0
	
	var player_lvl: int = PlayerExperience.get_level_at_exp(player_exp)
	
	return player_lvl


func _update_orbs_label():
	var orb_used_count: int = _get_orb_used_count(_upgrades_cached)
	var orb_unused_count: int = _orb_count_total - orb_used_count
	_orbs_label.text = str(orb_unused_count)


func _show_error(text: String):
	_error_label.text = text
	_error_label.show()


#########################
###     Callbacks     ###
#########################

func _on_button_pressed(button: WisdomUpgradeButton, upgrade_id: int):
	_error_label.hide()
	
	var current_state: bool = _upgrades_cached[upgrade_id]
	var new_state: bool = !current_state
	var orb_used_count: int = _get_orb_used_count(_upgrades_cached)
	var will_spend_orb: bool = new_state == true
	var can_spend_orb: bool = orb_used_count < _orb_count_total
	
	if will_spend_orb && !can_spend_orb:
		_show_error("Not enough orbs.")
		
		return
	
	_upgrades_cached[upgrade_id] = new_state
	button.set_indicator_visible(new_state)
	
	_update_orbs_label()

	Settings.set_setting(Settings.WISDOM_UPGRADES_CACHED, _upgrades_cached)
	Settings.flush()
