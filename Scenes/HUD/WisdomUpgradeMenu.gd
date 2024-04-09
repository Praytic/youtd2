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


#########################
###     Built-in      ###
#########################

func _ready():
	var bar_node_list: Array = _bar_container.get_children()
	
	for bar_node in bar_node_list:
		var bar: WisdomUpgradeBar = bar_node as WisdomUpgradeBar
		var upgrade: WisdomUpgrade.enm = bar.wisdom_upgrade
		
		bar.minus_pressed.connect(_on_minus_pressed.bind(bar))
		bar.plus_pressed.connect(_on_plus_pressed.bind(bar))
		bar.max_pressed.connect(_on_max_pressed.bind(bar))
		
		_bar_map[upgrade] = bar
	
	var player_lvl: int = _get_player_level()
	var orb_count: int = player_lvl * 1
	_orbs_total = orb_count
	_orbs_remaining = orb_count
	_update_orbs_label()
	
	var level_orbs_text: String = "You are level [color=GOLD]%d[/color] and you have [color=GOLD]%d[/color] orbs." % [player_lvl, orb_count]
	_level_orbs_label.clear()
	_level_orbs_label.append_text(level_orbs_text)

	var local_player: Player = PlayerManager.get_local_player()
	_upgrade_max = local_player.get_wisdom_upgrade_max()

	for bar in _bar_map.values():
		bar.set_max_value(_upgrade_max)


#########################
###      Private      ###
#########################

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
