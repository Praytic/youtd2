# Golden Trident
extends Item

var MB: MultiboardValues


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Golden Hit[/color]\n"
	text += "Grants 2 gold for each multicrit on a critical attack. Gold gain is base attack speed adjusted and scales with bounty received.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	MB = MultiboardValues.new(1)
	MB.set_key(1, "Golden Trident")


func on_attack(event: Event):
	var itm: Item = self

	var tower: Tower = itm.get_carrier()
	var gold_bonus: float = 2.0

	if event.get_number_of_crits() > 0:
		gold_bonus = gold_bonus * event.get_number_of_crits() * tower.get_base_attack_speed() * tower.get_prop_bounty_received()

		tower.get_player().give_gold(int(gold_bonus), tower, true, true)


func on_create():
	var itm: Item = self

	itm.user_real = 0.00


func on_tower_details() -> MultiboardValues:
	var itm: Item = self

	MB.set_value(0, Utils.format_float(itm.user_real, 1))

	return MB
