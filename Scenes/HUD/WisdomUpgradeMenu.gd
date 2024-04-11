class_name WisdomUpgradeMenu extends PanelContainer


# Menu where player can choose keeper of wisdom upgrades.


signal finished()


@export var _button_container: GridContainer
@export var _level_orbs_label: RichTextLabel
@export var _orbs_label: Label
@export var _error_label: Label


var _orb_count_total: int
var _upgrades_cached: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	var player_lvl: int = _get_player_level()
	_orb_count_total = player_lvl * Constants.PLAYER_LEVEL_TO_WISDOM_ORBS

# 	NOTE: upgrades cache may be invalid if player manually
# 	modifies settings file or if player chooses a builder
# 	which modifies max upgrades and old cached values don't
# 	fit.
	var upgrade_id_list: Array = WisdomUpgradeProperties.get_id_list()
	var orb_used_count: int = _get_orb_used_count()
	var used_more_orbs_than_got: bool = orb_used_count > _orb_count_total

	if used_more_orbs_than_got:
		push_warning("Wisdom upgrade cache is invalid! Resetting to empty. State = %s" % _upgrades_cached)
		
		_upgrades_cached = {}
	
	_update_orbs_label()
	
	for upgrade_id in upgrade_id_list:
		var button: WisdomUpgradeButton = WisdomUpgradeButton.make(upgrade_id)
		_button_container.add_child(button)
		
		button.pressed.connect(_on_button_pressed.bind(button, upgrade_id))
		
		var upgrade_is_enabled: bool = _upgrades_cached[upgrade_id]
		button.set_indicator_visible(upgrade_is_enabled)
	
	var level_orbs_text: String = "You are level [color=GOLD]%d[/color] and you have [color=GOLD]%d[/color] orbs." % [player_lvl, _orb_count_total]
	_level_orbs_label.clear()
	_level_orbs_label.append_text(level_orbs_text)


#########################
###       Public      ###
#########################

func set_wisdom_upgrades_cached(cache: Dictionary):
	if is_inside_tree():
		push_error("This f-n must be called before addding menu to tree.")

#	NOTE: need to convert cache keys to ints because cache
#	dict may contain int keys or string keys.
#	- If game just started and cache has been loaded from
#	  settings file, it will contain string keys because
#	  JSON forces dict keys to be strings.
#	- When wisdom menu is finished, the game updates the
#	  cache in memory. In this case, keys will be ints.
	_upgrades_cached = {}
	var upgrade_id_list: Array = WisdomUpgradeProperties.get_id_list()
	for upgrade_id in upgrade_id_list:
		if cache.has(upgrade_id):
			_upgrades_cached[upgrade_id] = cache[upgrade_id]
		elif cache.has(str(upgrade_id)):
			_upgrades_cached[upgrade_id] = cache[str(upgrade_id)]
		else:
			_upgrades_cached[upgrade_id] = false


func get_wisdom_upgrades() -> Dictionary:
	return _upgrades_cached


#########################
###      Private      ###
#########################

func _get_orb_used_count() -> int:
	var upgrade_id_list: Array = WisdomUpgradeProperties.get_id_list()
	var orbs_used: int = 0

	for upgrade_id in upgrade_id_list:
		var upgrade_is_enabled: bool = _upgrades_cached[upgrade_id]
		
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
	var orb_used_count: int = _get_orb_used_count()
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
	var orb_used_count: int = _get_orb_used_count()
	var will_spend_orb: bool = new_state == true
	var can_spend_orb: bool = orb_used_count < _orb_count_total
	
	if will_spend_orb && !can_spend_orb:
		_show_error("Not enough orbs.")
		
		return
	
	_upgrades_cached[upgrade_id] = new_state
	button.set_indicator_visible(new_state)
	
	_update_orbs_label()


func _on_confirm_button_pressed():
	finished.emit()
