# Glaive of Supreme Follow Up
extends Item

# TODO: implement add_modified_attack_crit(). Disabled until
# then.

var BT: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Follow Up[/color]\n"
	text += "Whenever this tower attacks it has a 10% chance to gain 300% attackspeed until next attack. The next attack will crit for sure but deals 50% less crit damage.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func attack(event: Event):
	var B: Buff = event.get_buff()
	var t: Tower = B.get_buffed_unit()

	if B.user_int == 0:
		# t.add_modified_attack_crit(0.00, 0.5 + t.get_level() / 100.0)
		B.remove_buff()
	else:
		B.user_int = 0


func item_init():
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 3.0, 0.04)
	
	BT = BuffType.new("item162_bt", 30, 0, true, self)
	BT.set_buff_icon("@@0@@")
	BT.set_buff_modifier(mod)
	BT.add_event_on_attack(attack)
	BT.set_buff_tooltip("Follow Up\nThis tower's next attack will be faster and will always be critical.")


func on_attack(event: Event):
	var itm: Item = self
