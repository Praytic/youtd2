class_name WisdomUpgradeMenu extends PanelContainer


# Menu where player can choose keeper of wisdom upgrades.


@export var _button_container: GridContainer
@export var _available_label: Label


var _upgrade_available_count: int
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
	_upgrade_available_count = Utils.get_local_wisdom_upgrade_count()
	_upgrades_cached = _load_wisdom_upgrade_state(_upgrade_available_count)

	var upgrade_id_list: Array = WisdomUpgradeProperties.get_id_list()
	for upgrade_id in upgrade_id_list:
		var button: WisdomUpgradeButton = _button_map[upgrade_id]
		var upgrade_is_enabled: bool = _upgrades_cached[upgrade_id]
		button.set_upgrade_used_status(upgrade_is_enabled)

	_update_available_label()


#########################
###      Private      ###
#########################

func _load_wisdom_upgrade_state(upgrade_available_count: int) -> Dictionary:
	var result: Dictionary = Settings.get_wisdom_upgrades()

	var used_count: int = _get_used_upgrade_count(result)
	var used_more_upgrades_than_available: bool = used_count > upgrade_available_count
	if used_more_upgrades_than_available:
		push_warning("Wisdom upgrade cache is invalid! Resetting upgrades. Invalid cache = %s" % result)
		
		for key in result.keys():
			result[key] = false

	return result


func _get_used_upgrade_count(upgrade_state: Dictionary) -> int:
	var upgrade_id_list: Array = WisdomUpgradeProperties.get_id_list()
	var used_count: int = 0

	for upgrade_id in upgrade_id_list:
		var upgrade_is_used: bool = upgrade_state[upgrade_id]
		
		if upgrade_is_used:
			used_count += 1

	return used_count


func _update_available_label():
	var used_count: int = _get_used_upgrade_count(_upgrades_cached)
	var available_count: int = _upgrade_available_count - used_count
	_available_label.text = str(available_count)


#########################
###     Callbacks     ###
#########################

func _on_button_pressed(button: WisdomUpgradeButton, upgrade_id: int):
	var current_state: bool = _upgrades_cached[upgrade_id]
	var new_state: bool = !current_state
	var used_count: int = _get_used_upgrade_count(_upgrades_cached)
	var will_increase_used: bool = new_state == true
	var can_increase_used: bool = used_count < _upgrade_available_count
	
	if will_increase_used && !can_increase_used:
		return
	
	_upgrades_cached[upgrade_id] = new_state
	button.set_upgrade_used_status(new_state)
	
	_update_available_label()

	Settings.set_setting(Settings.WISDOM_UPGRADES_CACHED, _upgrades_cached)
	Settings.flush()
