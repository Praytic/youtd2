# Chrono Jumper
extends Item


# TODO: implement. Very complicated script. Don't have to
# translate word for word, can do custom stuff to make it
# easier to implement.


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Chrono Jump[/color]\n"
	text += "Tower makes a leap through space to a target free location for 10 seconds, then returns to its original position. Increases attackspeed by 10% for the duration.\n"
	text += " \n"
	text += "30s cooldown\n"

	return text
