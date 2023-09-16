# Sign of Energy Infusion
extends Item


# TODO: check whether this item assumes that
# get_base_mana_regen_bonus_percent starts from 0.0 or 1.0.
# Current implementation is that it starts from 1.0


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Infuse with Regeneration[/color]\n"
	text += "Every 5th time the carrier of this item deals damage, the damage is increased by its percentual mana regeneration.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var itm: Item = self
	var carrier: Tower = itm.get_carrier()
	var regen: float = 2.0 + carrier.get_base_mana_regen_bonus_percent()
	
	itm.user_int = itm.user_int + 1

	if itm.user_int >= 5:
		event.damage = event.damage * regen
		itm.user_int = 0
		var damage_text: String = Utils.format_float(event.damage, 0)
		carrier.get_player().display_small_floating_text(damage_text, carrier, 255, 0, 255, 40.0)


func on_create():
	var itm: Item = self
	itm.user_int = 0
