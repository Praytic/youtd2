extends TowerBehavior


# NOTE: it may look wrong that the parasite buff has
# "friendly" property set to true but it doesn't matter
# because this buff is only for visual purposes. Leave it as
# is and do not change this.


var parasite_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {vuln_value = 0.025, vuln_value_add = 0.0005},
		2: {vuln_value = 0.030, vuln_value_add = 0.0006},
		3: {vuln_value = 0.035, vuln_value_add = 0.0007},
		4: {vuln_value = 0.040, vuln_value_add = 0.0008},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []

	var vuln_value: String = Utils.format_percent(_stats.vuln_value, 2)
	var vuln_value_add: String = Utils.format_percent(_stats.vuln_value_add, 2)

	var decay_string: String = AttackType.convert_to_colored_string(AttackType.enm.DECAY)
	var nature_string: String = Element.convert_to_colored_string(Element.enm.NATURE)
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Slumbering Parasite"
	ability.icon = "res://resources/icons/tower_icons/spider_queen.tres"
	ability.description_short = "Injects a parasite into hit creeps. The parasite increases creep's vulnerability to %s towers and causes %s damage after a delay.\n" % [nature_string, decay_string]
	ability.description_full = "Injects a parasite into hit creeps. The parasite increases creep's vulnerability to %s towers by %s and deals this tower's attack damage as %s damage after a delay of 3 seconds. Vulnerability stacks with multiple Parasites.\n" % [nature_string, vuln_value, decay_string] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s %s vulnerability\n" % [vuln_value_add, nature_string]

	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	parasite_bt = BuffType.new("parasite_bt", 0, 0, true, self)
	parasite_bt.set_buff_icon("res://resources/icons/generic_icons/amber_mosquito.tres")
	parasite_bt.set_buff_tooltip("Slumbering Parasite\nIncreases damage taken from Nature towers and deals Decay damage when the parasite surfaces.")


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

#	NOTE: need to divide by tower's buff duration because
#	duration will later be multiplied by tower's buff
#	duration, when buff is applied. Final result will be
#	that duration is 3 seconds.
	parasite_bt.apply_custom_timed(tower, target, 0, 3.0 / tower.get_prop_buff_duration())
	target.modify_property(Modification.Type.MOD_DMG_FROM_NATURE, _stats.vuln_value + level * _stats.vuln_value_add)

	await Utils.create_manual_timer(3.0, self).timeout

	if Utils.unit_is_valid(target):
		tower.do_custom_attack_damage(target, tower.get_current_attack_damage_with_bonus(), tower.calc_attack_multicrit(0, 0, 0), AttackType.enm.DECAY)
		Effect.create_simple_at_unit("res://src/effects/crypt_fiend_eggsack.tscn", target)
		target.modify_property(Modification.Type.MOD_DMG_FROM_NATURE, -_stats.vuln_value - level * _stats.vuln_value_add)
