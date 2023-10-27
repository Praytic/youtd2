extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 0.35, damage_add = 0.010},
		2: {damage = 0.45, damage_add = 0.013},
		3: {damage = 0.55, damage_add = 0.016},
		4: {damage = 0.65, damage_add = 0.019},
		5: {damage = 0.75, damage_add = 0.022},
		}


func get_ability_description() -> String:
	var damage: String = Utils.format_percent(_stats.damage, 2)
	var damage_add: String = Utils.format_percent(_stats.damage_add, 2)

	var text: String = ""

	text += "[color=GOLD]Banish[/color]\n"
	text += "Magic, undead and nature creeps damaged by this tower suffer an additional %s of that damage as spelldamage.\n" % damage
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage" % damage_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Banish[/color]\n"
	text += "Magic, undead and nature creeps suffer spell damage when hit by this tower.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var tower: Tower = self

	var creep: Unit = event.get_target()

	if creep.get_category() <= CreepCategory.enm.NATURE:
		tower.do_spell_damage(creep, event.damage * (_stats.damage + (_stats.damage_add * tower.get_level())), tower.calc_spell_crit_no_bonus())
		SFX.sfx_at_unit("Abilities\\Spells\\NightElf\\ManaBurn\\ManaBurnTarget.mdl", creep)
