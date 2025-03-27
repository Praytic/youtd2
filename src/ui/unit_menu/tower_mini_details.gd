class_name TowerMiniDetails extends TabContainer


# Displays tower stats inside unit menu


var _tower: Tower = null

@export var _dmg_left_label: RichTextLabel
@export var _dmg_right_label: RichTextLabel
@export var _misc_left_label: RichTextLabel
@export var _misc_right_label: RichTextLabel
@export var _types_left_label: RichTextLabel
@export var _types_right_label: RichTextLabel
@export var _oils_label: RichTextLabel


#########################
###       Public      ###
#########################

func set_tower(tower: Tower):
	_tower = tower


#########################
###      Private      ###
#########################

# NOTE: this code consumes a lot of frametime so it needs to
# be called sparingly. That's why it's not called every
# frame in _process().
func _update_labels():
	if _tower == null:
		return
	
	var dmg_stats_left_text: String = _get_dmg_stats_left_text()
	_dmg_left_label.clear()
	_dmg_left_label.append_text(dmg_stats_left_text)

	var dmg_stats_right_text: String = _get_dmg_stats_right_text()
	_dmg_right_label.clear()
	_dmg_right_label.append_text(dmg_stats_right_text)
	
	var support_stats_left_text: String = _get_support_stats_left_text()
	_misc_left_label.clear()
	_misc_left_label.append_text(support_stats_left_text)
	
	var support_stats_right_text: String = _get_support_stats_right_text()
	_misc_right_label.clear()
	_misc_right_label.append_text(support_stats_right_text)
	
	var dmg_against_left_text: String = _get_dmg_against_left_text()
	_types_left_label.clear()
	_types_left_label.append_text(dmg_against_left_text)
	
	var dmg_against_right_text: String = _get_dmg_against_right_text()
	_types_right_label.clear()
	_types_right_label.append_text(dmg_against_right_text)
	
	var oils_text: String = _get_tower_oils_text()
	_oils_label.clear()
	_oils_label.append_text(oils_text)


func _get_dmg_stats_left_text() -> String:
	var base_damage: int = roundi(_tower.get_current_attack_damage_base())
	var base_damage_string: String = TowerDetails.int_format(base_damage)

	var overall_damage: int = roundi(_tower.get_current_attack_damage_with_bonus())
	var overall_damage_string: String = TowerDetails.int_format(overall_damage)

	var dps_with_crit: int = roundi(_tower.get_dps_with_crit())
	var dps_with_crit_string: String = TowerDetails.int_format(dps_with_crit)

	var crit_chance: float = _tower.get_prop_atk_crit_chance()
	var crit_chance_string: String = Utils.format_percent(crit_chance, 1)

	var crit_damage: float = _tower.get_prop_atk_crit_damage()
	var crit_damage_string: String = TowerDetails.multiplier_format(crit_damage)

	var multicrit: int = _tower.get_prop_multicrit_count()
	var multicrit_string: String = TowerDetails.int_format(multicrit)

	var text: String = "" \
	+ "[hint=%s][img=30 color=e37c0e]res://resources/icons/generic_icons/hammer_drop.tres[/img] %s[/hint]\n" % [tr("TOWER_DETAILS_BASE_DMG"), base_damage_string] \
	+ "[hint=%s][img=30 color=eb4f34]res://resources/icons/generic_icons/hammer_drop.tres[/img] %s[/hint]\n" % [tr("TOWER_DETAILS_OVERALL_DNG"), overall_damage_string] \
	+ "[hint=%s][img=30 color=e83140]res://resources/icons/generic_icons/open_wound.tres[/img] %s[/hint]\n" % [tr("TOWER_DETAILS_DPS_WITH_CRIT"), dps_with_crit_string] \
	+ "[hint=%s][img=30 color=eb3495]res://resources/icons/generic_icons/root_tip.tres[/img] %s[/hint]\n" % [tr("TOWER_MINI_DETAILS_ATTACK_CRIT_CHANCE"), crit_chance_string] \
	+ "[hint=%s][img=30 color=eb3495]res://resources/icons/generic_icons/mine_explosion.tres[/img] %s[/hint]\n" % [tr("TOWER_MINI_DETAILS_ATTACK_CRIT_DAMAGE"), crit_damage_string] \
	+ "[hint=%s][img=30 color=de3535]res://resources/icons/generic_icons/triple_scratches.tres[/img] %s[/hint]\n" % [tr("TOWER_DETAILS_MULTICRIT_COUNT"), multicrit_string] \
	+ ""

	return text


func _get_dmg_stats_right_text() -> String:
	var overall_cooldown: float = _tower.get_current_attack_speed()
	var overall_cooldown_string: String = Utils.format_float(overall_cooldown, 2)

	var spell_damage: float = _tower.get_prop_spell_damage_dealt()
	var spell_damage_string: String = Utils.format_percent(spell_damage, 0)
	
	var spell_crit_chance: float = _tower.get_spell_crit_chance()
	var spell_crit_chance_string: String = Utils.format_percent(spell_crit_chance, 1)

	var spell_crit_damage: float = _tower.get_spell_crit_damage()
	var spell_crit_damage_string: String = TowerDetails.multiplier_format(spell_crit_damage)

	var overall_mana_regen: float = _tower.get_overall_mana_regen()
	var overall_mana_regen_string: String = Utils.format_float(overall_mana_regen, 1)

	var text: String = "" \
	+ "[hint=%s][img=30 color=eb8f34]res://resources/icons/generic_icons/hourglass.tres[/img] %s[/hint]\n" % [tr("TOWER_MINI_DETAILS_ATTACK_SPEED"), overall_cooldown_string] \
	+ "[hint=%s][img=30 color=31cde8]res://resources/icons/generic_icons/rolling_energy.tres[/img] %s/s[/hint]\n" % [tr("TOWER_MINI_DETAILS_MANA_REGEN"), overall_mana_regen_string] \
	+ "[hint=%s][img=30 color=31e896]res://resources/icons/generic_icons/flame.tres[/img] %s[/hint]\n" % [tr("TOWER_MINI_DETAILS_SPELL_DAMAGE_BONUS"), spell_damage_string] \
	+ "[hint=%s][img=30 color=35a8de]res://resources/icons/generic_icons/root_tip.tres[/img] %s[/hint]\n" % [tr("TOWER_MINI_DETAILS_SPELL_CRIT_CHANCE"), spell_crit_chance_string] \
	+ "[hint=%s][img=30 color=35a8de]res://resources/icons/generic_icons/mine_explosion.tres[/img] %s[/hint]\n" % [tr("TOWER_MINI_DETAILS_SPELL_CRIT_DAMAGE"), spell_crit_damage_string] \
	+ ""

	return text


func _get_support_stats_left_text() -> String:
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

	var text: String = "" \
	+ "[hint=%s][img=30 color=deca35]res://resources/icons/generic_icons/shiny_omega.tres[/img] %s[/hint]\n" % [tr("TOWER_DETAILS_BOUNTY_RAT"), bounty_ratio_string] \
	+ "[hint=%s][img=30 color=9630f0]res://resources/icons/generic_icons/moebius_trefoil.tres[/img] %s[/hint]\n" % [tr("TOWER_DETAILS_EXP_RAT"), exp_ratio_string] \
	+ "[hint=%s][img=30 color=bcde35]res://resources/icons/generic_icons/polar_star.tres[/img] %s[/hint]\n" % [tr("TOWER_DETAILS_DROP_RAT"), item_drop_ratio_string] \
	+ "[hint=%s][img=30 color=c2ae3c]res://resources/icons/generic_icons/gold_bar.tres[/img] %s[/hint]\n" % [tr("TOWER_DETAILS_QUALITY_RAT"), item_quality_ratio_string] \
	+ "[hint=%s][img=30 color=35ded5]res://resources/icons/generic_icons/cog.tres[/img] %s[/hint]\n" % [tr("TOWER_DETAILS_TRIGGER_CHANCES"), trigger_chances_string] \
	+ ""

	return text


func _get_support_stats_right_text() -> String:
	var buff_duration: float = _tower.get_prop_buff_duration()
	var buff_duration_string: String = Utils.format_percent(buff_duration, 0)

	var debuff_duration: float = _tower.get_prop_debuff_duration()
	var debuff_duration_string: String = Utils.format_percent(debuff_duration, 0)

	var text: String = "" \
	+ "[hint=%s][img=30 color=49c23c]res://resources/icons/generic_icons/hourglass.tres[/img] %s[/hint]\n" % [tr("TOWER_DETAILS_BUFF_DUR"), buff_duration_string] \
	+ "[hint=%s][img=30 color=c2433c]res://resources/icons/generic_icons/hourglass.tres[/img] %s[/hint]\n" % [tr("TOWER_DETAILS_DEBUFF_DUR"), debuff_duration_string] \
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
	+ "[hint=%s][img=30 color=9370db]res://resources/icons/generic_icons/animal_skull.tres[/img] %s[/hint]\n" % [tr("TOWER_MINI_DETAILS_DAMAGE_TO_UNDEAD"), dmg_to_undead_string] \
	+ "[hint=%s][img=30 color=6495ed]res://resources/icons/generic_icons/polar_star.tres[/img] %s[/hint]\n" % [tr("TOWER_MINI_DETAILS_DAMAGE_TO_MAGIC"), dmg_to_magic_string] \
	+ "[hint=%s][img=30 color=32cd32]res://resources/icons/generic_icons/root_tip.tres[/img] %s[/hint]\n" % [tr("TOWER_MINI_DETAILS_DAMAGE_TO_NATURE"), dmg_to_nature_string] \
	+ "[hint=%s][img=30 color=8fbc8f]res://resources/icons/generic_icons/orc_head.tres[/img] %s[/hint]\n" % [tr("TOWER_MINI_DETAILS_DAMAGE_TO_ORC"), dmg_to_orc_string] \
	+ "[hint=%s][img=30 color=d2b48c]res://resources/icons/generic_icons/armor_vest.tres[/img] %s[/hint]\n" % [tr("TOWER_MINI_DETAILS_DAMAGE_TO_HUMANOID"), dmg_to_humanoid_string] \
	+ ""
	
	return text


func _get_dmg_against_right_text() -> String:
	var dmg_to_mass: float = _tower.get_damage_to_mass()
	var dmg_to_mass_string: String = Utils.format_percent(dmg_to_mass, 0)

	var dmg_to_normal: float = _tower.get_damage_to_normal()
	var dmg_to_normal_string: String = Utils.format_percent(dmg_to_normal, 0)

	var dmg_to_air: float = _tower.get_damage_to_air()
	var dmg_to_air_string: String = Utils.format_percent(dmg_to_air, 0)

	var dmg_to_champion: float = _tower.get_damage_to_champion()
	var dmg_to_champion_string: String = Utils.format_percent(dmg_to_champion, 0)

	var dmg_to_boss: float = _tower.get_damage_to_boss()
	var dmg_to_boss_string: String = Utils.format_percent(dmg_to_boss, 0)

	var text: String = "" \
	+ "[hint=%s][img=30 color=ffa500]res://resources/icons/generic_icons/sprint.tres[/img] %s[/hint]\n" % [tr("TOWER_MINI_DETAILS_DAMAGE_TO_MASS"), dmg_to_mass_string] \
	+ "[hint=%s][img=30 color=8fbc8f]res://resources/icons/generic_icons/barbute.tres[/img] %s[/hint]\n" % [tr("TOWER_MINI_DETAILS_DAMAGE_TO_NORMAL"), dmg_to_normal_string] \
	+ "[hint=%s][img=30 color=6495ed]res://resources/icons/generic_icons/liberty_wing.tres[/img] %s[/hint]\n" % [tr("TOWER_MINI_DETAILS_DAMAGE_TO_AIR"), dmg_to_air_string] \
	+ "[hint=%s][img=30 color=9370db]res://resources/icons/generic_icons/horned_helm.tres[/img] %s[/hint]\n" % [tr("TOWER_MINI_DETAILS_DAMAGE_TO_CHAMPION"), dmg_to_champion_string] \
	+ "[hint=%s][img=30 color=ff4500]res://resources/icons/generic_icons/bat_mask.tres[/img] %s[/hint]\n" % [tr("TOWER_MINI_DETAILS_DAMAGE_TO_BOSS"), dmg_to_boss_string] \
	+ ""
	
	return text


func _get_tower_oils_text() -> String:
	var oil_count_map: Dictionary = _get_oil_count_map()
	
	if oil_count_map.is_empty():
		return tr("TOWER_MINI_DETAILS_NO_OILS")

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


#########################
###     Callbacks     ###
#########################

func _on_update_timer_timeout() -> void:
	_update_labels()


func _on_visibility_changed() -> void:
	_update_labels()
