extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 0.35, damage_add = 0.010},
		2: {damage = 0.45, damage_add = 0.013},
		3: {damage = 0.55, damage_add = 0.016},
		4: {damage = 0.65, damage_add = 0.019},
		5: {damage = 0.75, damage_add = 0.022},
		}


func get_extra_tooltip_text() -> String:
	var damage: String = String.num(_stats.damage * 100, 2)
	var damage_add: String = String.num(_stats.damage_add * 100, 2)

	var text: String = ""

	text += "[color=GOLD]Banish[/color]\n"
	text += "Magic, undead and nature creeps damaged by this tower suffer an additional %s%% of that damage as spelldamage.\n" % damage
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s%% damage" % damage_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage, 1.0, 0.0)


func on_damage(event: Event):
	var tower: Tower = self

	var creep: Unit = event.get_target()

	if creep.get_category() <= CreepCategory.enm.NATURE:
		tower.do_spell_damage(creep, event.damage * (_stats.damage + (_stats.damage_add * tower.get_level())), tower.calc_spell_crit_no_bonus())
		SFX.sfx_at_unit("Abilities\\Spells\\NightElf\\ManaBurn\\ManaBurnTarget.mdl", creep)
