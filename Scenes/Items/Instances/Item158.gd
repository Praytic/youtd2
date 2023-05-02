# Mining Tools
extends Item


var drol_digItemMulti: MultiboardValues


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Mining[/color]\n"
	text += "Every 15 seconds there is a 40%% chance to find 3 gold.\n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+2%% chance\n"
	text += "+1 gold at lvl 25\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 15)


func item_init():
	drol_digItemMulti = MultiboardValues.new(1)
	drol_digItemMulti.set_key(0, "Gold found")


func on_create():
	var itm: Item = self
	itm.user_int = 0


func on_tower_details() -> MultiboardValues:
	var itm: Item = self
	
#	Show total gold digged up
	drol_digItemMulti.set_value(0, str(itm.user_int))
	return drol_digItemMulti


func periodic(_event: Event):
	var itm: Item = self

	var tower: Tower = itm.get_carrier()
	var target_effect: int

	target_effect = Effect.create_scaled("Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl", tower.get_visual_position().x, tower.get_visual_position().y, 0, 0, 0.8)
	Effect.set_lifetime(target_effect, 0.1)

	if tower.calc_chance(0.40 + tower.get_level() * 0.02):
		if tower.get_level() < 25:
			tower.getOwner().give_gold(3, tower, false, true)
			itm.user_int = itm.user_int + 3
		else:
			tower.getOwner().give_gold(4, tower, false, true)
			itm.user_int = itm.user_int + 4
