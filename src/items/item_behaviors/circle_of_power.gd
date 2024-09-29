extends ItemBehavior


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Circle of Power[/color]\n"
	text += "Every 5 seconds, if the carrier has less mana than it had 5 seconds ago, the carrier has a 25% chance to restore mana to what it was before.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 5)



func on_pickup():
	item.user_real = item.get_carrier().get_mana()


func periodic(_event: Event):
	var u: Unit = item.get_carrier()
	var cur_mana: float = u.get_mana()

	if cur_mana < item.user_real && u.calc_chance(0.25):
		CombatLog.log_item_ability(item, null, "Circle of Power")
		u.set_mana(item.user_real)
		var effect: int = Effect.create_simple_at_unit("res://src/effects/spell_aima.tscn", u)
		Effect.set_color(effect, Color.GOLD)
	else:
		item.user_real = cur_mana
