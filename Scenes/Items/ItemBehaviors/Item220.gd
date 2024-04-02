# Nermind's Eye
extends ItemBehavior


var cedi_nermind_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Nermind's Eye[/color]\n"
	text += "Reveals invisible enemies in 750 range.\n"

	return text


func item_init():
	cedi_nermind_bt = MagicalSightBuff.new("cedi_nermind_bt", 750, self)
	cedi_nermind_bt.set_buff_tooltip("Nermind's Eye\nReveals invisible units in range.")


func on_pickup():
	var carrier: Unit = item.get_carrier()
	cedi_nermind_bt.apply_to_unit_permanent(carrier, carrier, 0)	
