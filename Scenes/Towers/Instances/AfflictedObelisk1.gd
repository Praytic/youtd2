extends Tower


# NOTE: fixed multiple errors in original script. The
# parasite buff should be a debuff, so friendly argument for
# buff constructor should be false. When debuff is applied,
# the duration needs to be divided by target's property not
# tower's. Also changed the property to debuff duration
# because I changed the buff to debuff.


var dummy_obelisk_debuff: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {vuln_value = 0.025, vuln_value_add = 0.0005},
		2: {vuln_value = 0.030, vuln_value_add = 0.0006},
		3: {vuln_value = 0.035, vuln_value_add = 0.0007},
		4: {vuln_value = 0.040, vuln_value_add = 0.0008},
	}


func get_ability_description() -> String:
	var vuln_value: String = Utils.format_percent(_stats.vuln_value, 2)
	var vuln_value_add: String = Utils.format_percent(_stats.vuln_value_add, 2)

	var text: String = ""

	text += "[color=GOLD]Slumbering Parasite[/color]\n"
	text += "On attack this tower injects an ancient parasite into its target, which surfaces after 3 seconds dealing this tower's attackdamage as Decay damage to the target. Each parasite increases the creep's vulnerability to Nature towers by %s.\n" % vuln_value
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s Nature vulnerability\n" % vuln_value_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Slumbering Parasite[/color]\n"
	text += "This tower deals additional Decay damage after a short delay and increases target's vulnerability to Nature.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	dummy_obelisk_debuff = BuffType.new("dummy_obelisk_debuff", 0, 0, false, self)
	dummy_obelisk_debuff.set_buff_icon("@@0@@")
	dummy_obelisk_debuff.set_buff_tooltip("Slumbering Parasite\nThis unit is infected with a parasite; it has increased vulnerability to Nature towers and it will take damage when the parasite surfaces.")


func on_damage(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

#	applying the dummy buff to show the effect on the unot
	dummy_obelisk_debuff.apply_custom_timed(tower, target, 0, 3.0 / target.get_prop_debuff_duration())
	target.modify_property(Modification.Type.MOD_DMG_FROM_NATURE, _stats.vuln_value + level * _stats.vuln_value_add)

	await get_tree().create_timer(3.0).timeout

	if Utils.unit_is_valid(target):
		tower.do_custom_attack_damage(target, tower.get_current_attack_damage_with_bonus(), tower.calc_attack_multicrit(0, 0, 0), AttackType.enm.DECAY)
		SFX.sfx_at_unit("CryptFiendEggsack.mdl", target)
		target.modify_property(Modification.Type.MOD_DMG_FROM_NATURE, -_stats.vuln_value - level * _stats.vuln_value_add)
