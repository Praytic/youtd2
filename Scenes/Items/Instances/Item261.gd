# Vampiric Skull
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Vampiric Absorption[/color]\n"
	text += "The skull's carrier restores 7% of its maximum mana whenever it kills a creep."

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func on_kill(event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	tower.add_mana_perc(0.07)
	var effect: int = Effect.create_simple_at_unit("VampPotionCaster.mdl", tower)
	Effect.destroy_effect(effect)
