# Medallion of Opulence
extends Item


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Greed Is Good[/color]\n"
	text += "On attack there is a 20% attackspeed adjusted chance to deal 10% of your current gold as spelldamage to the target.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func on_attack(event: Event):
	var itm: Item = self

	var tower: Tower = itm.get_carrier() 
	var speed: float = tower.get_base_attack_speed()

	if tower.calc_chance(0.2 * speed) == true:
		CombatLog.log_item_ability(self, event.get_target(), "Greed Is Good")
		tower.do_spell_damage(event.get_target(), Utils.get_player_state(tower.get_player().get_the_player(), PlayerState.enm.RESOURCE_GOLD) * (0.10), tower.calc_spell_crit_no_bonus())
