# Wise Man's Cooking Recipe
extends Item


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Learning to Kill[/color]\n"
	text += "The tower gains 1 additional experience for each kill.\n"

	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.05, 0.0)


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func on_kill(_event: Event):
	var itm: Item = self
	itm.get_carrier().add_exp(1)
