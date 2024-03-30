# Soul Extractor
extends ItemBehavior


var cb_stun: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Stunning Souls[/color]\n"
	text += "Gains 2 charges on kill. Spends 1 charge on damage to stun for 1.5 seconds.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_kill(on_kill)


func item_init():
	cb_stun = CbStun.new("item_268_stun", 0, 0, false, self)


func on_damage(event: Event):
	var target: Unit = event.get_target()

	if item.user_int > 0:
		cb_stun.apply_only_timed(item.get_carrier(), target, 1.5)
		item.user_int = item.user_int - 1
		item.set_charges(item.user_int)


func on_pickup():
	item.user_int = 0


func on_kill(_event: Event):
	item.user_int = item.user_int + 2
	item.set_charges(item.user_int)
