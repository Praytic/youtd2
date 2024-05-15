class_name TowerDetails extends GridContainer

# Displays detailed information about the stats of the
# currently selected tower. Can be toggled in unit menu by
# pressing the "info" button.


# Attack
@export var _base_damage: Label
@export var _base_damage_bonus: Label
@export var _base_damage_bonus_perc: Label
@export var _damage_add: Label
@export var _damage_add_perc: Label
@export var _overall_damage: Label
@export var _base_cooldown: Label
@export var _attack_speed: Label
@export var _overall_cooldown: Label
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

# Damage to size
@export var _dmg_to_mass: Label
@export var _dmg_to_normal: Label
@export var _dmg_to_air: Label
@export var _dmg_to_champion: Label
@export var _dmg_to_boss: Label

# Details
@export var _tower_details_label: RichTextLabel

var _tower: Tower = null


#########################
###       Public      ###
#########################

func set_tower(tower: Tower):
	_tower = tower
	_update_text()


#########################
###      Private      ###
#########################

func _update_text():
	if _tower == null:
		return

#	NOTE: don't set tooltips for towers that haven't been
#	added to scene tree yet because their _ready() functions
#	haven't been called so they aren't setup completely.
#	This can happen while hovering over tower build buttons.
	if !_tower.is_inside_tree():
		return

#	Attack
	var base_damage: int = _tower.get_base_damage()
	_base_damage.text = TowerDetails.int_format(base_damage)

	var base_damage_bonus: float = _tower.get_base_damage_bonus()
	_base_damage_bonus.text = TowerDetails.int_format(base_damage_bonus)

	var base_damage_bonus_perc: float = _tower.get_base_damage_bonus_percent() - 1.0
	_base_damage_bonus_perc.text = _percent_signed_format(base_damage_bonus_perc)

	var damage_add: float = _tower.get_damage_add()
	_damage_add.text = TowerDetails.int_format(damage_add)

	var damage_add_perc: float = _tower.get_damage_add_percent() - 1.0
	_damage_add_perc.text = _percent_signed_format(damage_add_perc)

	var overall_damage: float = _tower.get_overall_damage()
	_overall_damage.text = TowerDetails.int_format(overall_damage)

	var base_cooldown: float = _tower.get_base_attack_speed()
	_base_cooldown.text = Utils.format_float(base_cooldown, 2)

	var attack_speed: float = _tower.get_attack_speed_modifier()
	_attack_speed.text = Utils.format_percent(attack_speed, 0)

	var overall_cooldown: float = _tower.get_current_attack_speed()
	_overall_cooldown.text = Utils.format_float(overall_cooldown, 2)

	var overall_dps: float = _tower.get_overall_dps()
	_overall_dps.text = TowerDetails.int_format(overall_dps)

	var crit_chance: float = _tower.get_prop_atk_crit_chance()
	_crit_chance.text = Utils.format_percent(crit_chance, 1)

	var crit_damage: float = _tower.get_prop_atk_crit_damage()
	_crit_damage.text = _multiplier_format(crit_damage)

	var multicrit: int = _tower.get_prop_multicrit_count()
	_multicrit.text = TowerDetails.int_format(multicrit)

	var dps_with_crit: float = _tower.get_dps_with_crit()
	_dps_with_crit.text = TowerDetails.int_format(dps_with_crit)

#	Spells
	var spell_damage: float = _tower.get_prop_spell_damage_dealt()
	_spell_damage.text = Utils.format_percent(spell_damage, 0)
	
	var spell_crit_chance: float = _tower.get_spell_crit_chance()
	_spell_crit_chance.text = Utils.format_percent(spell_crit_chance, 1)

	var spell_crit_damage: float = _tower.get_spell_crit_damage()
	_spell_crit_damage.text = _multiplier_format(spell_crit_damage)

#	Veteran
	var total_damage: float = _tower.get_damage()
	_total_damage.text = TowerDetails.int_format(total_damage)

	var best_hit: float = _tower.get_best_hit()
	_best_hit.text = TowerDetails.int_format(best_hit)

	var kills: float = _tower.get_kills()
	_kills.text = TowerDetails.int_format(kills)

	var experience: float = _tower.get_exp()
	_experience.text = TowerDetails.int_format(experience)

	var next_level: int = _tower.get_level() + 1
	var exp_for_next_level: int = Experience.get_exp_for_level(next_level)
	
	if _tower.reached_max_level():
		_level_x_at_left.text = "Max level reached!"
		_level_x_at_right.text = ""
	else:
		_level_x_at_left.text = "Level %s at" % str(next_level)
		_level_x_at_right.text = TowerDetails.int_format(exp_for_next_level)

# 	Mana
	var base_mana: float = _tower.get_base_mana()
	_base_mana.text = TowerDetails.int_format(base_mana)

	var mana_bonus: float = _tower.get_base_mana_bonus()
	_mana_bonus.text = TowerDetails.int_format(mana_bonus)

	var mana_bonus_perc: float = _tower.get_base_mana_bonus_percent() - 1.0
	_mana_bonus_perc.text = _percent_signed_format(mana_bonus_perc)

	var overall_mana: float = _tower.get_overall_mana()
	_overall_mana.text = TowerDetails.int_format(overall_mana)

	var base_mana_regen: float = _tower.get_base_mana_regen()
	_base_mana_regen.text = Utils.format_float(base_mana_regen, 1)

	var mana_regen_bonus: float = _tower.get_base_mana_regen_bonus()
	_mana_regen_bonus.text = Utils.format_float(mana_regen_bonus, 1)

	var mana_regen_bonus_perc: float = _tower.get_base_mana_regen_bonus_percent() - 1.0
	_mana_regen_bonus_perc.text = _percent_signed_format(mana_regen_bonus_perc)

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

#	Damage to size
	var dmg_to_mass: float = _tower.get_damage_to_mass()
	_dmg_to_mass.text = Utils.format_percent(dmg_to_mass, 0)

	var dmg_to_normal: float = _tower.get_damage_to_magic()
	_dmg_to_normal.text = Utils.format_percent(dmg_to_normal, 0)

	var dmg_to_air: float = _tower.get_damage_to_air()
	_dmg_to_air.text = Utils.format_percent(dmg_to_air, 0)

	var dmg_to_champion: float = _tower.get_damage_to_champion()
	_dmg_to_champion.text = Utils.format_percent(dmg_to_champion, 0)

	var dmg_to_boss: float = _tower.get_damage_to_boss()
	_dmg_to_boss.text = Utils.format_percent(dmg_to_boss, 0)

#	Details
	var tower_details_text: String = _generate_tower_details_text(_tower)
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
	if num >= 1_000_000_000_000:
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
		frac_str = ".%d" % ((num - int(num)) * 100)
	
	# Add commas to the integer part of the number
	var digits = num_str.length()
	for i in range(digits - 3, 0, -3):
		num_str = num_str.insert(i, ",")
	
	# Combine the integer part, fractional part, and suffix into the final string
	return num_str + frac_str + suffix


func _percent_signed_format(number: float) -> String:
	var formatted: String = Utils.format_percent(number, 0)

	if int(number) > 0:
		formatted = "+%s" % formatted

	return formatted


func _multiplier_format(number) -> String:
	return "x%.2f" % number


func _float_format(number) -> String:
	return Utils.format_float(number, 2)


func _generate_tower_details_text(tower: Tower) -> String:
	var oils_text: String = _get_tower_oils_text(tower)
	var details_text: String = _get_tower_details_text(tower)

	var text: String = ""
	text += oils_text
	text += " \n"
	text += " \n"
	text += details_text

	return text


func _get_tower_oils_text(tower: Tower) -> String:
	var text: String = ""

	text += "[color=PURPLE]Tower Oils:[/color]\n"
	text += " \n"

	var oil_count_map: Dictionary = _get_oil_count_map(tower)

	var oil_name_list: Array = oil_count_map.keys()
	oil_name_list.sort()

	for oil_name in oil_name_list:
		var count: int = oil_count_map[oil_name]

		text += "%s x %s\n" % [str(count), oil_name]

	if oil_count_map.is_empty():
		text += "None"

	return text


func _get_tower_details_text(tower: Tower) -> String:
	var text: String = ""
	
	var tower_multiboard: MultiboardValues = tower.on_tower_details()
	var item_multiboard_list: Array[MultiboardValues] = tower.get_item_tower_details()

	var all_multiboard_list: Array[MultiboardValues] = item_multiboard_list
	all_multiboard_list.insert(0, tower_multiboard)

	text += "[color=GOLD]Tower Details:[/color]\n \n"

	text += "[table=2]"

	for multiboard in all_multiboard_list:
		for row in range(0, multiboard.size()):
			var key: String = multiboard.get_key(row)
			var value: String = multiboard.get_value(row)

			text += "[cell]%s:[/cell][cell]%s[/cell]\n" % [key, value]

	text += "[/table]"

	return text


func _get_oil_count_map(tower: Tower) -> Dictionary:
	var oil_list: Array[Item] = tower.get_item_container().get_oil_list()

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


#########################
###     Callbacks     ###
#########################

func _on_refresh_timer_timeout():
	_update_text()
