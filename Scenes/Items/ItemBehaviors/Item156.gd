# Sign of Energy Infusion
extends ItemBehavior


# TODO: check whether this item assumes that
# get_base_mana_regen_bonus_percent starts from 0.0 or 1.0.
# Current implementation is that it starts from 1.0


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Infuse with Regeneration[/color]\n"
	text += "Every 5th time the carrier of this item deals damage, the damage is increased by its percentual mana regeneration.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var carrier: Tower = item.get_carrier()
	var regen: float = carrier.get_base_mana_regen_bonus_percent()
	
	item.user_int = item.user_int + 1

	if item.user_int >= 5:
		CombatLog.log_item_ability(item, null, "Infuse with Regeneration")
		
		event.damage = event.damage * regen
		item.user_int = 0
		var damage_text: String = Utils.format_float(event.damage, 0)
		carrier.get_player().display_small_floating_text(damage_text, carrier, Color8(255, 0, 255), 40.0)


func on_create():
	item.user_int = 0
