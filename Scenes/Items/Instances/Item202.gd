# Optimist's Preserved Face
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Optimist Hunting Season[/color]\n"
	text += "The carrier of this item's damage is modified by the amount of hp the creep has left. The range goes from +75% damage when the creep has full hp to -50% damage when the creep has no hp left.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage, 1.0, 0.0)


func on_damage(event: Event):
	var itm: Item = self

	var u: Unit = event.get_target()
	var r: float = Unit.get_unit_state(u, Unit.State.LIFE) / Unit.get_unit_state(u, Unit.State.MAX_LIFE)
	event.damage = event.damage * (1.75 - (1.25 * (1-r)))
