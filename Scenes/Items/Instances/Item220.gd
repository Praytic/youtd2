# Nermind's Eye
extends Item


var nerminds_eye: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Nermind's Eye[/color]\n"
	text += "Reveals invisible enemies in 750 range.\n"

	return text


func item_init():
	nerminds_eye = MagicalSightBuff.new("nerminds_eye", 750, self)
	nerminds_eye.set_buff_tooltip("Nermind's Eye\nThis unit has Nermind's Eye; it will reveal invisible units in range.")


func on_pickup():
	var itm: Item = self
	var carrier: Unit = itm.get_carrier()
	nerminds_eye.apply_to_unit_permanent(carrier, carrier, 0)	
