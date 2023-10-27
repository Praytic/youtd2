# Spider Brooch
extends Item


var drol_broach: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Silver Threads[/color]\n"
	text += "Attacks have a 15% attack speed adjusted chance to cover the target creep in a silvered web, increasing its item quality by 40% for 5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1% item quality\n"
	text += "+0.1 seconds duration\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func item_init():
	var m: Modifier = Modifier.new()
	drol_broach = BuffType.new("drol_broach", 5.0, 0.1, false, self)
	m.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_DEATH, 0.4, 0.01)
	drol_broach.set_buff_modifier(m)
	drol_broach.set_buff_icon("@@0@@")
	drol_broach.set_buff_tooltip("Silver Threads\nThis unit is covered by Silver Threads; it will drop items of higher quality.")


func on_damage(event: Event):
	var itm: Item = self

	var tower: Tower = itm.get_carrier()

	if tower.calc_chance(0.15 * tower.get_base_attack_speed()):
		drol_broach.apply(tower, event.get_target(), tower.get_level())
