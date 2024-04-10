class_name WisdomUpgradeMenu extends PanelContainer


# Menu where player can choose keeper of wisdom upgrades.


signal finished()


@export var _bar_container: VBoxContainer
@export var _level_orbs_label: RichTextLabel
@export var _orbs_label: Label


var _bar_map: Dictionary = {}

var _orbs_total: int
var _orbs_remaining: int
var _upgrade_max: int
var _upgrades_cached: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	var player_lvl: int = _get_player_level()
	var orb_count: int = player_lvl * 1
	_orbs_total = orb_count
#	TODO: this value is currently incorrect if loaded cached
#	upgrades.
	_orbs_remaining = orb_count
	_update_orbs_label()
	var local_player: Player = PlayerManager.get_local_player()
	_upgrade_max = local_player.get_wisdom_upgrade_max()

# 	NOTE: upgrades cache may be invalid if player manually
# 	modifies settings file or if player chooses a builder
# 	which modifies max upgrades and old cached values don't
# 	fit.
	var upgrades_cached_is_valid: bool = _validate_upgrades_cache(_upgrades_cached, _upgrade_max, orb_count)
	if !upgrades_cached_is_valid:
		_upgrades_cached = {}
	
	var upgrade_id_list: Array = WisdomUpgradeProperties.get_id_list()

	for upgrade_id in upgrade_id_list:
		var bar: WisdomUpgradeBar = WisdomUpgradeBar.make(upgrade_id)
		
		bar.minus_pressed.connect(_on_minus_pressed.bind(bar))
		bar.plus_pressed.connect(_on_plus_pressed.bind(bar))
		bar.max_pressed.connect(_on_max_pressed.bind(bar))
		
#		NOTE: need to convert upgrade_id to string because
#		cache comes from settings JSON which forces dict
#		keys to be strings.
		var cached_value: int = _upgrades_cached.get(str(upgrade_id), 0)
		bar.set_value(cached_value)

		_bar_container.add_child(bar)
		
		_bar_map[upgrade_id] = bar
	
	var level_orbs_text: String = "You are level [color=GOLD]%d[/color] and you have [color=GOLD]%d[/color] orbs." % [player_lvl, orb_count]
	_level_orbs_label.clear()
	_level_orbs_label.append_text(level_orbs_text)

	for bar in _bar_map.values():
		bar.set_max_value(_upgrade_max)


#########################
###       Public      ###
#########################

func set_wisdom_upgrades_cached(upgrades_cached: Dictionary):
	if is_inside_tree():
		push_error("This f-n must be called before addding menu to tree.")

	_upgrades_cached = upgrades_cached


func get_wisdom_upgrades() -> Dictionary:
	var result: Dictionary = {}

	var upgrade_id_list: Array = WisdomUpgradeProperties.get_id_list()

	for upgrade_id in upgrade_id_list:
		var bar: WisdomUpgradeBar = _bar_map[upgrade_id]
		var upgrade_value: int = bar.get_value()

		result[upgrade_id] = upgrade_value

	return result


#########################
###      Private      ###
#########################

func _validate_upgrades_cache(cache: Dictionary, upgrades_max: int, orb_count: int) -> bool:
	var upgrade_id_list: Array = WisdomUpgradeProperties.get_id_list()

	var orbs_used: int = 0

	for upgrade_id in upgrade_id_list:
		var value: int = cache.get(str(upgrade_id), 0)

		var value_in_bounds: bool =  0 <= value && value <= upgrades_max

		if !value_in_bounds:
			push_error("Cached value for upgrade %d is out of bounds. Value: %d" % [upgrade_id, value])

			return false

		orbs_used += value

	var used_more_orbs_than_got: bool = orbs_used > orb_count

	if used_more_orbs_than_got:
		push_error("Cached wisdom upgrades use too many orbs. Upgrades: %s" % cache)

		return false

	return true


func _get_player_level() -> int:
	var exp_password: String = Settings.get_setting(Settings.EXP_PASSWORD)
	var player_exp: int = ExperiencePassword.decode(exp_password)
	var player_exp_is_valid: bool = player_exp != -1
	
	if !player_exp_is_valid:
		# TODO: show error msg
		
		return 0
	
	var player_lvl: int = PlayerExperience.get_level_at_exp(player_exp)
	
	return player_lvl


func _update_orbs_label():
	var used_orb_count: int = _orbs_total - _orbs_remaining
	var orbs_text: String = "%d/%d" % [used_orb_count, _orbs_total]
	
	_orbs_label.text = orbs_text


#########################
###     Callbacks     ###
#########################

func _on_minus_pressed(bar: WisdomUpgradeBar):
	var current_value: int = bar.get_value()
	
	if current_value == 0:
		return
	
	bar.set_value(current_value - 1)
	_orbs_remaining += 1
	_update_orbs_label()


func _on_plus_pressed(bar: WisdomUpgradeBar):
	if _orbs_remaining == 0:
#		Messages.add_error(PlayerManager.get_local_player(), "Not enough orbs.")
		print("Not enough orbs.")
		
		return
	
	var current_value: int = bar.get_value()
	
	if current_value == _upgrade_max:
		return
	
	bar.set_value(current_value + 1)
	_orbs_remaining -= 1
	_update_orbs_label()


func _on_max_pressed(bar: WisdomUpgradeBar):
	if _orbs_remaining == 0:
#		Messages.add_error(PlayerManager.get_local_player(), "Not enough orbs.")
		print("Not enough orbs.")
		
		return
	
	while _orbs_remaining > 0 && bar.get_value() < _upgrade_max:
		bar.set_value(bar.get_value() + 1)
		_orbs_remaining -= 1
		_update_orbs_label()

func _on_confirm_button_pressed():
	finished.emit()
