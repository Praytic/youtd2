# Circle of Power
extends Item


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Circle of Power[/color]\n"
	text += "Every 5 seconds, if the carrier of this item has less mana than it had 5 seconds ago, the carrier has a 25% chance to restore mana to what it was before.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 5)



func on_pickup():
	var itm: Item = self
	itm.user_real = itm.get_carrier().get_mana()


func periodic(_event: Event):
	var itm: Item = self
	var u: Unit = itm.get_carrier()
	var cur_mana: float = u.get_mana()

	if cur_mana < itm.user_real && u.calc_chance(0.25):
		CombatLog.log_item_ability(self, null, "Circle of Power")
		u.set_mana(itm.user_real)
		var effect: int = Effect.create_simple_at_unit("AImaTarget.mdl", u)
		Effect.destroy_effect_after_its_over(effect)
	else:
		itm.user_real = cur_mana
