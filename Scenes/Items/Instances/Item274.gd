# Portable Tombstone
extends Item

var boekie_tombstonejibs: MultiboardValues


func get_extra_tooltip_text() -> String:
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
	boekie_tombstonejibs = MultiboardValues.new(1)
	boekie_tombstonejibs.set_key(0, "Tombstone Kills")


func on_attack(event: Event):
	var itm: Item = self

	var tower: Tower = itm.get_carrier()
	var creep: Unit = event.get_target()

	if creep.get_size() < CreepSize.enm.CHAMPION && tower.calc_chance((0.0025 + (tower.get_level() * 0.0001)) * tower.get_base_attack_speed()):
		tower.kill_instantly(creep)
		SFX.sfx_at_unit("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", creep)
		itm.user_int = itm.user_int + 1


func on_create():
	var itm: Item = self

#	number of innocent creeps slaughtered mercilessly.
	itm.user_int = 0


func on_tower_details() -> MultiboardValues:
	var itm: Item = self

	boekie_tombstonejibs.set_value(0, str(itm.user_int))
	return boekie_tombstonejibs
