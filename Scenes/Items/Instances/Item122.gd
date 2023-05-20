# Medallion of Opulence
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Greed Is Good[/color]\n"
	text += "On attack there is a 20% attackspeed adjusted chance to deal 10% of your current gold as spelldamage to the target."

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack, 1.0, 0.0)


func on_attack(event: Event):
	var itm: Item = self

	var tower: Tower = itm.get_carrier() 
	var speed: float = tower.get_base_attack_speed()

	if tower.calc_chance(0.2 * speed) == true:
		tower.do_spell_damage(event.get_target(), Utils.get_player_state(tower.getOwner().get_the_player(), PlayerState.enm.RESOURCE_GOLD) * (0.10), tower.calc_spell_crit_no_bonus())
