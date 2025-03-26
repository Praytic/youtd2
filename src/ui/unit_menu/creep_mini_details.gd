class_name CreepMiniDetails extends TabContainer


# Displays creep stats inside unit menu

var _creep: Creep = null

@export var _stats_left_label: RichTextLabel
@export var _stats_right_label: RichTextLabel
@export var _dmg_left_label: RichTextLabel
@export var _dmg_right_label: RichTextLabel


#########################
###       Public      ###
#########################

func set_creep(creep: Creep):
	_creep = creep


#########################
###      Private      ###
#########################

# NOTE: this code consumes a lot of frametime so it needs to
# be called sparingly. That's why it's not called every
# frame in _process().
func _update_labels():
	if _creep == null:
		return
	
	var stats_left_text: String = _get_stats_left_text()
	_stats_left_label.clear()
	_stats_left_label.append_text(stats_left_text)
	
	var stats_right_text: String = _get_stats_right_text()
	_stats_right_label.clear()
	_stats_right_label.append_text(stats_right_text)
	
	var dmg_left_text: String = _get_dmg_left_text()
	_dmg_left_label.clear()
	_dmg_left_label.append_text(dmg_left_text)
	
	var dmg_right_text: String = _get_dmg_right_text()
	_dmg_right_label.clear()
	_dmg_right_label.append_text(dmg_right_text)


func _get_stats_left_text() -> String:
	var slow_amount: float = _creep.get_prop_move_speed() - 1.0
	var slow_amount_string: String = Utils.format_percent(slow_amount, 0)

	var overall_armor: float = _creep.get_overall_armor()
	var overall_armor_string: String = Utils.format_float(overall_armor, 1)

	var exp_ratio: float = _creep.get_prop_exp_granted()
	var exp_ratio_string: String = Utils.format_percent(exp_ratio, 0)

	var item_drop_ratio: float = _creep.get_item_drop_ratio_on_death()
	var item_drop_ratio_string: String = Utils.format_percent(item_drop_ratio, 0)
	
	var item_quality_ratio: float = _creep.get_item_quality_ratio_on_death()
	var item_quality_ratio_string: String = Utils.format_percent(item_quality_ratio, 0)

	var text: String = "" \
	+ "[hint=%s][img=30 color=6495ed]res://resources/icons/generic_icons/barefoot.tres[/img] %s[/hint]\n" % [tr("CREEP_MINI_DETAILS_SPEED"), slow_amount_string] \
	+ "[hint=%s][img=30 color=d2b48c]res://resources/icons/generic_icons/abdominal_armor.tres[/img] %s[/hint]\n" % [tr("CREEP_MINI_DETAILS_ARMOR"), overall_armor_string] \
	+ "[hint=%s][img=30 color=9630f0]res://resources/icons/generic_icons/moebius_trefoil.tres[/img] %s[/hint]\n" % [tr("CREEP_MINI_DETAILS_EXP_RATIO"), exp_ratio_string] \
	+ "[hint=%s][img=30 color=bcde35]res://resources/icons/generic_icons/polar_star.tres[/img] %s[/hint]\n" % [tr("CREEP_MINI_DETAILS_ITEM_CHANCE"), item_drop_ratio_string] \
	+ "[hint=%s][img=30 color=bcde35]res://resources/icons/generic_icons/gold_bar.tres[/img] %s[/hint]\n" % [tr("CREEP_MINI_DETAILS_ITEM_QUALITY"), item_quality_ratio_string] \
	+ ""
	
	return text


func _get_stats_right_text() -> String:
	var overall_health_regen: float = _creep.get_overall_health_regen()
	var overall_health_regen_string: String = Utils.format_float(overall_health_regen, 1)

	var overall_mana_regen: float = _creep.get_overall_mana_regen()
	var overall_mana_regen_string: String = Utils.format_float(overall_mana_regen, 1)

	var text: String = "" \
	+ "[hint=%s][img=30 color=32cd32]res://resources/icons/generic_icons/rolling_energy.tres[/img] %s/s[/hint]\n" % [tr("CREEP_MINI_DETAILS_HEALTH_REGEN"), overall_health_regen_string] \
	+ "[hint=%s][img=30 color=31cde8]res://resources/icons/generic_icons/rolling_energy.tres[/img] %s/s[/hint]\n" % [tr("CREEP_MINI_DETAILS_MANA_REGEN"), overall_mana_regen_string] \
	+ ""
	
	return text


func _get_dmg_left_text() -> String:
	var attack_damage_received: float = _creep.get_prop_atk_damage_received()
	var attack_damage_received_string: String = Utils.format_percent(attack_damage_received, 0)

	var spell_damage_received: float = _creep.get_prop_spell_damage_received()
	var spell_damage_received_string: String = Utils.format_percent(spell_damage_received, 0)
	
	var dmg_from_ice: float = _creep.get_damage_from_element(Element.enm.ICE)
	var dmg_from_ice_string: String = Utils.format_percent(dmg_from_ice, 0)
	var dmg_from_nature: float = _creep.get_damage_from_element(Element.enm.NATURE)
	var dmg_from_nature_string: String = Utils.format_percent(dmg_from_nature, 0)

	var dmg_from_fire: float = _creep.get_damage_from_element(Element.enm.FIRE)
	var dmg_from_fire_string: String = Utils.format_percent(dmg_from_fire, 0)

	var dmg_from_astral: float = _creep.get_damage_from_element(Element.enm.ASTRAL)
	var dmg_from_astral_string: String = Utils.format_percent(dmg_from_astral, 0)

	var text: String = "" \
	+ "[hint=%s][img=30 color=eb4f34]res://resources/icons/generic_icons/hammer_drop.tres[/img] %s[/hint]\n" % [tr("CREEP_MINI_DETAILS_ATTACK_DAMAGE_RECEIVED"), attack_damage_received_string] \
	+ "[hint=%s][img=30 color=31e896]res://resources/icons/generic_icons/flame.tres[/img] %s[/hint]\n" % [tr("CREEP_MINI_DETAILS_SPELL_DAMAGE_RECEIVED"), spell_damage_received_string] \
	+ "[hint=%s][img=30 color=6495ed]res://resources/icons/generic_icons/azul_flake.tres[/img] %s[/hint]\n" % [tr("CREEP_MINI_DETAILS_DAMAGE_FROM_ICE"), dmg_from_ice_string] \
	+ "[hint=%s][img=30 color=32cd32]res://resources/icons/generic_icons/root_tip.tres[/img] %s[/hint]\n" % [tr("CREEP_MINI_DETAILS_DAMAGE_FROM_NATURE"), dmg_from_nature_string] \
	+ "[hint=%s][img=30 color=ff4500]res://resources/icons/generic_icons/flame.tres[/img] %s[/hint]\n" % [tr("CREEP_MINI_DETAILS_DAMAGE_FROM_FIRE"), dmg_from_fire_string] \
	+ "[hint=%s][img=30 color=66cdaa]res://resources/icons/generic_icons/star_swirl.tres[/img] %s[/hint]\n" % [tr("CREEP_MINI_DETAILS_DAMAGE_FROM_ASTRAL"), dmg_from_astral_string] \
	+ ""
	
	return text


func _get_dmg_right_text() -> String:
	var dmg_from_darkness: float = _creep.get_damage_from_element(Element.enm.DARKNESS)
	var dmg_from_darkness_string: String = Utils.format_percent(dmg_from_darkness, 0)

	var dmg_from_iron: float = _creep.get_damage_from_element(Element.enm.IRON)
	var dmg_from_iron_string: String = Utils.format_percent(dmg_from_iron, 0)

	var dmg_from_storm: float = _creep.get_damage_from_element(Element.enm.STORM)
	var dmg_from_storm_string: String = Utils.format_percent(dmg_from_storm, 0)

	var text: String = "" \
	+ "[hint=%s][img=30 color=9370db]res://resources/icons/generic_icons/animal_skull.tres[/img] %s[/hint]\n" % [tr("CREEP_MINI_DETAILS_DAMAGE_FROM_DARKNESS"), dmg_from_darkness_string] \
	+ "[hint=%s][img=30 color=d2b48c]res://resources/icons/generic_icons/pokecog.tres[/img] %s[/hint]\n" % [tr("CREEP_MINI_DETAILS_DAMAGE_FROM_IRON"), dmg_from_iron_string] \
	+ "[hint=%s][img=30 color=ffffe0]res://resources/icons/generic_icons/rolling_energy.tres[/img] %s[/hint]\n" % [tr("CREEP_MINI_DETAILS_DAMAGE_FROM_STORM"), dmg_from_storm_string] \
	+ ""
	
	return text


#########################
###     Callbacks     ###
#########################

func _on_update_timer_timeout() -> void:
	_update_labels()


func _on_visibility_changed() -> void:
	_update_labels()
