# Magic Conductor
extends Item

var boekie_magicConductor_buff: BuffType

func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Conduct Magic[/color]\n"
	text += "Whenever the carrier of this item is targeted by a spell it gains +20% attackspeed for 10 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.5% attackspeed\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_spell_targeted(on_spell_target)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.20, 0.005)
	boekie_magicConductor_buff = BuffType.new("boekie_magicConductor_buff", 0.0, 0.0, true, self)
	boekie_magicConductor_buff.set_buff_modifier(m)
	boekie_magicConductor_buff.set_buff_icon("@@0@@")
	boekie_magicConductor_buff.set_stacking_group("boekie_magicConductor")
	boekie_magicConductor_buff.set_buff_tooltip("Magical Conduction\nThis unit is affected by Magic Conductor; it has increased attack speed.")


func on_spell_target(_event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrie()
	var lvl: int = tower.get_level()

	boekie_magicConductor_buff.apply_custom_timed(tower, tower, lvl, 10.0)
