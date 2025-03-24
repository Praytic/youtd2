class_name WisdomUpgradeMenu extends PanelContainer


# Menu where player can choose keeper of wisdom upgrades.


@export var _button_container: GridContainer
@export var _available_label: Label
@export var _next_upgrade_unlock_label: RichTextLabel


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
	var player_level: int = Utils.get_local_player_level()
	_upgrade_available_count = Utils.get_wisdom_upgrade_count_for_player_level(player_level)
	_upgrades_cached = _load_wisdom_upgrade_state(_upgrade_available_count)

	var upgrade_id_list: Array = WisdomUpgradeProperties.get_id_list()
	for upgrade_id in upgrade_id_list:
		var button: WisdomUpgradeButton = _button_map[upgrade_id]
		var upgrade_is_enabled: bool = _upgrades_cached[upgrade_id]
		button.set_upgrade_used_status(upgrade_is_enabled)
	
	var next_unlock_level: int = _get_next_upgrade_unlock_level()
	var next_unlock_level_exists: bool = next_unlock_level != -1
	_next_upgrade_unlock_label.visible = next_unlock_level_exists
	_next_upgrade_unlock_label.clear()
	if next_unlock_level_exists:
		_next_upgrade_unlock_label.append_text(tr("WISDOM_UPGRADES_UNLOCK_LABEL") + "[color=GOLD]%d[/color]." % next_unlock_level)

	_update_available_label()


#########################
###      Private      ###
#########################

# Find next unlock level by finding a level at which the
# upgrade count doesn't equal to current upgrade count.
func _get_next_upgrade_unlock_level() -> int:
	var current_player_level: int = Utils.get_local_player_level()

	var upgrade_id_list: Array = WisdomUpgradeProperties.get_id_list()
	var upgrade_available_count_max: int = upgrade_id_list.size()
	var unlocked_all_upgrades: bool = _upgrade_available_count == upgrade_available_count_max

	if unlocked_all_upgrades:
		return -1
	
	var current_upgrade_count: int = Utils.get_wisdom_upgrade_count_for_player_level(current_player_level)

	var next_unlock_level: int = -1

	for level in range(current_player_level, Constants.PLAYER_MAX_LEVEL):
		var this_upgrade_count: int = Utils.get_wisdom_upgrade_count_for_player_level(level)
		var new_upgrade_unlocks_at_this_level: bool = this_upgrade_count != current_upgrade_count
		
		if new_upgrade_unlocks_at_this_level:
			next_unlock_level = level
			
			break

	return next_unlock_level


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
