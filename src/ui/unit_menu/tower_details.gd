class_name TowerDetails extends PanelContainer

# Displays detailed information about the stats of the
# currently selected tower. Can be toggled in unit menu by
# pressing the "info" button.


@export var _tower_name_label: Label

# Attack
@export var _base_damage: Label
@export var _base_damage_bonus: Label
@export var _base_damage_bonus_perc: Label
@export var _damage_add: Label
@export var _damage_add_perc: Label
@export var _overall_damage: Label
@export var _base_attack_speed: Label
@export var _attack_speed_modifier: Label
@export var _overall_attack_speed: Label
@export var _overall_dps: Label
@export var _crit_chance: Label
@export var _crit_damage: Label
@export var _multicrit: Label
@export var _dps_with_crit: Label

# Spells
@export var _spell_damage: Label
@export var _spell_crit_chance: Label
@export var _spell_crit_damage: Label

# Veteran
@export var _total_damage: Label
@export var _total_damage_recent: Label
@export var _best_hit: Label
@export var _kills: Label
@export var _experience: Label
@export var _level_x_at_left: Label
@export var _level_x_at_right: Label

# Mana
@export var _base_mana: Label
@export var _mana_bonus: Label
@export var _mana_bonus_perc: Label
@export var _overall_mana: Label
@export var _base_mana_regen: Label
@export var _mana_regen_bonus: Label
@export var _mana_regen_bonus_perc: Label
@export var _overall_mana_regen: Label

# Misc
@export var _bounty_ratio: Label
@export var _exp_ratio: Label
@export var _item_drop_ratio: Label
@export var _item_quality_ratio: Label
@export var _trigger_chances: Label
@export var _buff_duration: Label
@export var _debuff_duration: Label

# Damage to race
@export var _dmg_to_undead: Label
@export var _dmg_to_magical: Label
@export var _dmg_to_nature: Label
@export var _dmg_to_orc: Label
@export var _dmg_to_humanoid: Label
@export var _dmg_to_challenge: Label

# Damage to size
@export var _dmg_to_mass: Label
@export var _dmg_to_normal: Label
@export var _dmg_to_air: Label
@export var _dmg_to_champion: Label
@export var _dmg_to_boss: Label

@export var _total_dmg_multiplier: Label

# Details
@export var _tower_details_label: RichTextLabel

var _tower: Tower = null


#########################
###       Public      ###
#########################

func set_tower(tower: Tower):
	_tower = tower
	update_text()


#########################
###      Private      ###
#########################

func update_text():
	if _tower == null:
		return

#	NOTE: don't set tooltips for towers that haven't been
#	added to scene tree yet because their _ready() functions
#	haven't been called so they aren't setup completely.
#	This can happen while hovering over tower build buttons.
	if !_tower.is_inside_tree():
		return

	var tower_id: int = _tower.get_id()
	var tower_name: String = TowerProperties.get_display_name(tower_id)
	_tower_name_label.text = tower_name

#	Attack
	var base_damage: int = roundi(_tower.get_current_attack_damage_base())
	_base_damage.text = TowerDetails.int_format(base_damage)

	var base_damage_bonus: int = roundi(_tower.get_base_damage_bonus())
	_base_damage_bonus.text = TowerDetails.int_format(base_damage_bonus)

	var base_damage_bonus_perc: float = _tower.get_base_damage_bonus_percent() - 1.0
	_base_damage_bonus_perc.text = TowerDetails.percent_signed_format(base_damage_bonus_perc)

#	NOTE: it's intentional that damage_add shows "overall"
#	damage_add, which includes bonus from MOD_DPS_ADD. This
#	is how it works in original game.
	var damage_add_overall: int = roundi(_tower.get_damage_add_overall())
	_damage_add.text = TowerDetails.int_format(damage_add_overall)

	var damage_add_perc: float = _tower.get_damage_add_percent() - 1.0
	_damage_add_perc.text = TowerDetails.percent_signed_format(damage_add_perc)

	var overall_damage: int = roundi(_tower.get_current_attack_damage_with_bonus())
	_overall_damage.text = TowerDetails.int_format(overall_damage)

	var base_attack_speed: float = _tower.get_base_attack_speed()
	_base_attack_speed.text = Utils.format_float(base_attack_speed, 2)

	var attack_speed_modifier: float = _tower.get_attack_speed_modifier()
	_attack_speed_modifier.text = Utils.format_percent(attack_speed_modifier, 0)

	var overall_attack_speed: float = _tower.get_current_attack_speed()
	_overall_attack_speed.text = Utils.format_float(overall_attack_speed, 2)

	var overall_dps: int = roundi(_tower.get_overall_dps())
	_overall_dps.text = TowerDetails.int_format(overall_dps)

	var crit_chance: float = _tower.get_prop_atk_crit_chance()
	_crit_chance.text = Utils.format_percent(crit_chance, 1)

	var crit_damage: float = _tower.get_prop_atk_crit_damage()
	_crit_damage.text = TowerDetails.multiplier_format(crit_damage)

	var multicrit: int = _tower.get_prop_multicrit_count()
	_multicrit.text = TowerDetails.int_format(multicrit)

	var dps_with_crit: int = roundi(_tower.get_dps_with_crit())
	_dps_with_crit.text = TowerDetails.int_format(dps_with_crit)

#	Spells
	var spell_damage: float = _tower.get_prop_spell_damage_dealt()
	_spell_damage.text = Utils.format_percent(spell_damage, 0)
	
	var spell_crit_chance: float = _tower.get_spell_crit_chance()
	_spell_crit_chance.text = Utils.format_percent(spell_crit_chance, 1)

	var spell_crit_damage: float = _tower.get_spell_crit_damage()
	_spell_crit_damage.text = TowerDetails.multiplier_format(spell_crit_damage)

#	Veteran
	var total_damage: int = roundi(_tower.get_total_damage())
	_total_damage.text = TowerDetails.int_format(total_damage)
	
	var total_damage_recent: int = roundi(_tower.get_total_damage_recent())
	_total_damage_recent.text = TowerDetails.int_format(total_damage_recent)

	var best_hit: int = roundi(_tower.get_best_hit())
	_best_hit.text = TowerDetails.int_format(best_hit)

	var kills: int = _tower.get_kills()
	_kills.text = TowerDetails.int_format(kills)

	var experience: int = floori(_tower.get_exp())
	_experience.text = TowerDetails.int_format(experience)

	var next_level: int = _tower.get_level() + 1
	var exp_for_next_level: int = Experience.get_exp_for_level(next_level)
	
	if _tower.reached_max_level():
		_level_x_at_left.text = tr("MAX_LVL_REACHED")
		_level_x_at_right.text = ""
	else:
		_level_x_at_left.text = tr("LEVEL_AT_LABEL").format({NEXT_LEVEL = next_level})
		_level_x_at_right.text = TowerDetails.int_format(exp_for_next_level)

# 	Mana
	var base_mana: int = floori(_tower.get_base_mana())
	_base_mana.text = TowerDetails.int_format(base_mana)

	var mana_bonus: int = floori(_tower.get_base_mana_bonus())
	_mana_bonus.text = TowerDetails.int_format(mana_bonus)

	var mana_bonus_perc: float = _tower.get_base_mana_bonus_percent() - 1.0
	_mana_bonus_perc.text = TowerDetails.percent_signed_format(mana_bonus_perc)

	var overall_mana: int = floori(_tower.get_overall_mana())
	_overall_mana.text = TowerDetails.int_format(overall_mana)

	var base_mana_regen: float = _tower.get_base_mana_regen()
	_base_mana_regen.text = Utils.format_float(base_mana_regen, 1)

	var mana_regen_bonus: float = _tower.get_base_mana_regen_bonus()
	_mana_regen_bonus.text = Utils.format_float(mana_regen_bonus, 1)

	var mana_regen_bonus_perc: float = _tower.get_base_mana_regen_bonus_percent() - 1.0
	_mana_regen_bonus_perc.text = TowerDetails.percent_signed_format(mana_regen_bonus_perc)

	var overall_mana_regen: float = _tower.get_overall_mana_regen()
	_overall_mana_regen.text = Utils.format_float(overall_mana_regen, 1)

#	Misc
	var bounty_ratio: float = _tower.get_prop_bounty_received()
	_bounty_ratio.text = Utils.format_percent(bounty_ratio, 0)

	var exp_ratio: float = _tower.get_prop_exp_received()
	_exp_ratio.text = Utils.format_percent(exp_ratio, 0)

	var item_drop_ratio: float = _tower.get_item_drop_ratio()
	_item_drop_ratio.text = Utils.format_percent(item_drop_ratio, 0)

	var item_quality_ratio: float = _tower.get_item_quality_ratio()
	_item_quality_ratio.text = Utils.format_percent(item_quality_ratio, 0)

	var trigger_chances: float = _tower.get_prop_trigger_chances()
	_trigger_chances.text = Utils.format_percent(trigger_chances, 0)

	var buff_duration: float = _tower.get_prop_buff_duration()
	_buff_duration.text = Utils.format_percent(buff_duration, 0)

	var debuff_duration: float = _tower.get_prop_debuff_duration()
	_debuff_duration.text = Utils.format_percent(debuff_duration, 0)

#	Damage to race
	var dmg_to_undead: float = _tower.get_damage_to_undead()
	_dmg_to_undead.text = Utils.format_percent(dmg_to_undead, 0)

	var dmg_to_magical: float = _tower.get_damage_to_magic()
	_dmg_to_magical.text = Utils.format_percent(dmg_to_magical, 0)

	var dmg_to_nature: float = _tower.get_damage_to_nature()
	_dmg_to_nature.text = Utils.format_percent(dmg_to_nature, 0)

	var dmg_to_orc: float = _tower.get_damage_to_orc()
	_dmg_to_orc.text = Utils.format_percent(dmg_to_orc, 0)

	var dmg_to_humanoid: float = _tower.get_damage_to_humanoid()
	_dmg_to_humanoid.text = Utils.format_percent(dmg_to_humanoid, 0)
	
	var dmg_to_challenge: float = _tower.get_damage_to_challenge()
	_dmg_to_challenge.text = Utils.format_percent(dmg_to_challenge, 0)
	
#	Damage to size
	var dmg_to_mass: float = _tower.get_damage_to_mass()
	_dmg_to_mass.text = Utils.format_percent(dmg_to_mass, 0)

	var dmg_to_normal: float = _tower.get_damage_to_normal()
	_dmg_to_normal.text = Utils.format_percent(dmg_to_normal, 0)

	var dmg_to_air: float = _tower.get_damage_to_air()
	_dmg_to_air.text = Utils.format_percent(dmg_to_air, 0)

	var dmg_to_champion: float = _tower.get_damage_to_champion()
	_dmg_to_champion.text = Utils.format_percent(dmg_to_champion, 0)

	var dmg_to_boss: float = _tower.get_damage_to_boss()
	_dmg_to_boss.text = Utils.format_percent(dmg_to_boss, 0)
	
	var total_dmg_multiplier: float = _tower.get_total_damage_multiplier()
	_total_dmg_multiplier.text = Utils.format_percent(total_dmg_multiplier, 0)
	
#	Details
	var tower_details_text: String = _get_tower_details_text(_tower)
	_tower_details_label.clear()
	_tower_details_label.append_text(tower_details_text)


# Formats numbers which can go above million and need to be
# shortened.
# Examples:
# 1340 = "1,340"
# 1340000 = "1.34M"
# 1340000000 = "1.34G"
static func int_format(num: float) -> String:
	# Determine the appropriate suffix for the number
	var suffix = ""
	if num >= 1_000_000_000_000_000:
		num /= 1_000_000_000_000_000
		suffix = "Q"
	elif num >= 1_000_000_000_000:
		num /= 1_000_000_000_000
		suffix = "T"
	elif num >= 1_000_000_000:
		num /= 1_000_000_000
		suffix = "G"
	elif num >= 1_000_000:
		num /= 1_000_000
		suffix = "M"

	# Convert the number to a string and handle the fractional part
	var num_str = ""
	if num >= 1:
		num_str = str(int(num))
	else:
		num_str = "0"
	var frac_str = ""
	if suffix != "":
		var num_float_str: String = Utils.format_float(num, 2)
		if num_float_str.contains("."):
			var num_float_str_split: Array = num_float_str.split(".")
			frac_str = ".%s" % num_float_str_split[1]

	# Add commas to the integer part of the number
	var digits = num_str.length()
	for i in range(digits - 3, 0, -3):
		num_str = num_str.insert(i, ",")
	
	# Combine the integer part, fractional part, and suffix into the final string
	return num_str + frac_str + suffix


# This variant shortens thousands as well and doesn't
# include fractional part.
static func int_format_shortest(num: float) -> String:
	# Determine the appropriate suffix for the number
	var suffix = ""
	if num >= 1_000_000_000_000_000:
		num /= 1_000_000_000_000_000
		suffix = "Q"
	elif num >= 1_000_000_000_000:
		num /= 1_000_000_000_000
		suffix = "T"
	elif num >= 1_000_000_000:
		num /= 1_000_000_000
		suffix = "G"
	elif num >= 1_000_000:
		num /= 1_000_000
		suffix = "M"
	elif num >= 1_000:
		num /= 1_000
		suffix = "K"

	var num_str = ""
	if num >= 1:
		num_str = str(int(num))
	else:
		num_str = "0"
	
	return num_str + suffix


static func percent_signed_format(number: float) -> String:
	var formatted: String = Utils.format_percent(number, 0)

	if int(number) > 0:
		formatted = "+%s" % formatted

	return formatted


static func multiplier_format(number) -> String:
	return "x%.2f" % number


static func float_format(number) -> String:
	return Utils.format_float(number, 2)


func _get_tower_details_text(tower: Tower) -> String:
	var text: String = ""
	
	var tower_multiboard: MultiboardValues = tower.on_tower_details()
	var item_multiboard_list: Array[MultiboardValues] = tower.get_item_tower_details()

	var all_multiboard_list: Array[MultiboardValues] = item_multiboard_list
	all_multiboard_list.insert(0, tower_multiboard)

	text += "[color=GOLD]%s[/color]\n \n" % tr("TOWER_DETAILS_TITLE")

	text += "[table=2]"

	for multiboard in all_multiboard_list:
		for row in range(0, multiboard.size()):
			var key: String = multiboard.get_key(row)
			var value: String = multiboard.get_value(row)

			text += "[cell]%s:[/cell][cell]%s[/cell]\n" % [key, value]

	text += "[/table]"

	return text


#########################
###     Callbacks     ###
#########################

func _on_refresh_timer_timeout():
	if !visible:
		return
	
	update_text()


func _on_close_button_pressed():
	hide()
