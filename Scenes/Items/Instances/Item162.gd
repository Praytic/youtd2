# Glaive of Supreme Follow Up
extends Item


# NOTE: original script uses buff.userInt as a flag so that
# attack() f-n does nothing the first time it is called and
# does something the second time it is called. This is to
# solve some issue which exists in original script engine.
# In current engine this is not needed and causes a bug
# where follow up attack to happen twice. So it was removed.


var BT: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Follow Up[/color]\n"
	text += "Whenever this tower attacks it has a 10% chance to gain 300% attackspeed until next attack. The next attack will crit for sure but deals 50% less crit damage.\n"
	text += "\n"
	text += "[color=GOLD]Level Bonus:[/color]\n"
	text += "+0.4% chance\n"
	text += "+4% attackspeed\n"
	text += "+1% crit damage\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func attack(event: Event):
	var B: Buff = event.get_buff()
	var t: Tower = B.get_buffed_unit()

	t.add_modified_attack_crit(0.00, 0.5 + t.get_level() / 100.0)
	B.remove_buff()


func item_init():
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 3.0, 0.04)
	
	BT = BuffType.new("item162_bt", 30, 0, true, self)
	BT.set_buff_icon("@@0@@")
	BT.set_buff_modifier(mod)
	BT.add_event_on_attack(attack)
	BT.set_buff_tooltip("Follow Up\nThis unit is affected by Follow Up; it's next attack will be faster and will always be critical.")


func on_attack(_event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()

	if !tower.calc_chance(0.1 + 0.004 * tower.get_level()):
		return

	BT.apply(itm.get_carrier(), itm.get_carrier(), itm.get_carrier().get_level())
