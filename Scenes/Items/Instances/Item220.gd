# Nermind's Eye
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Nermind's Eye[/color]\n"
	text += "Reveals invisible enemies in 750 range.\n"

	return text


func item_init():
	var buff: BuffType = MagicalSightBuff.new("nerminds_eye_magical_sight", 750, self)
	buff.set_buff_tooltip("Nermind's Eye\nThis unit has Nermind's Eye; it will reveal invisible units in range.")
	add_buff(buff)
