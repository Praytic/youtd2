# Spear of Loki
extends Item


# NOTE: in original script, item is used as caster for
# cb_stun. Changed to tower itself because in our engine
# Item is not a Unit.


var cb_stun: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Tricky Weapon[/color]\n"
	text += "Each attack there is a 15% chance the carrier gets stunned for 1 second.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.50, 0.01)


func item_init():
	cb_stun = CbStun.new("item_264_stun", 0, 0, false, self)


func on_attack(_event: Event):
	var itm: Item = self

	var twr: Tower = itm.get_carrier()

	if Utils.rand_chance(0.15 / twr.get_prop_trigger_chances()):
		cb_stun.apply_only_timed(twr, twr, 1)
