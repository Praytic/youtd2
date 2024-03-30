# Nermind's Eye
extends ItemBehavior


var nerminds_eye: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Nermind's Eye[/color]\n"
	text += "Reveals invisible enemies in 750 range.\n"

	return text


func item_init():
	nerminds_eye = MagicalSightBuff.new("nerminds_eye", 750, self)
	nerminds_eye.set_buff_tooltip("Nermind's Eye\nReveals invisible units in range.")


func on_pickup():
	var carrier: Unit = item.get_carrier()
	nerminds_eye.apply_to_unit_permanent(carrier, carrier, 0)	
