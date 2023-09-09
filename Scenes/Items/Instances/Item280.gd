# Unyielding Maul
extends Item


# NOTE: original script implemented miss effect via "attack"
# event. Not sure how that's supposed to work because
# setting event.damage to 0 in attack event should have no
# effect. At least it has no effect in the godot engine, so
# I changed to this script to use "damage" event. Maybe it
# does work in JASS engine that way, need to test this item
# in original game and change how attack event is handled in
# godot engine if needed.


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Miss[/color]\n"
	text += "The wielder has a 10% chance to miss an attack.\n"

	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.25, 0.0)



func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var itm: Item = self
	var tower: Unit = itm.get_carrier()

	if !tower.calc_chance(0.90):
		event.damage = 0
		tower.get_player().display_floating_text_x("Miss", tower, 255, 0, 0, 255, 0.05, 0.0, 2.0)
