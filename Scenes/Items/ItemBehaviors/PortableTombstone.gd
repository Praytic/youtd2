extends ItemBehavior


var multiboard: MultiboardValues


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Curse of the Grave[/color]\n"
	text += "This item has a 0.25% attackspeed adjusted chance on attack to kill a non boss, non champion target immediately.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.01% chance\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Tombstone Kills")


func on_attack(event: Event):
	var tower: Tower = item.get_carrier()
	var creep: Unit = event.get_target()

	if creep.get_size() < CreepSize.enm.CHAMPION && tower.calc_chance((0.0025 + (tower.get_level() * 0.0001)) * tower.get_base_attackspeed()):
		CombatLog.log_item_ability(item, null, "Curse of the Grave")

		tower.kill_instantly(creep)
		SFX.sfx_at_unit("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", creep)
		item.user_int = item.user_int + 1


func on_create():
#	number of innocent creeps slaughtered mercilessly.
	item.user_int = 0


func on_tower_details() -> MultiboardValues:
	var tombstone_kills_text: String = Utils.format_float(item.user_int, 0)
	multiboard.set_value(0, tombstone_kills_text)
	
	return multiboard
