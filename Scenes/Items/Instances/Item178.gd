# Dark Matter Trident
extends Item


var neg: BuffType
var pos: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Drain Physical Energy[/color]\n"
	text += "Whenever the carrier of this item hits a creep, the carrier gains 2% attackspeed and the creep is slowed by 2%. Both effects are attackspeed adjusted, last 5 seconds and stack up to 20 times.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.1 second duration\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func item_init():
	var m_neg: Modifier = Modifier.new()
	m_neg.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.0002)

	neg = BuffType.new("item178_neg", 2.5, 0.0, false, self)
	neg.set_buff_icon("@@0@@")
	neg.set_buff_modifier(m_neg)

	var m_pos: Modifier = Modifier.new()
	m_pos.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.0002)

	pos = BuffType.new("item178_pos", 2.5, 0.0, true, self)
	pos.set_buff_icon("@@1@@")
	pos.set_buff_modifier(m_pos)


func on_damage(event: Event):
	var itm: Item = self
	var B: Buff
	var T: Tower
	var C: Creep
	var level_add: int
	var dur: float

	if event.is_main_target():
		T = itm.get_carrier()
		C = event.get_target()
		level_add = int(100.0 * T.get_current_attack_speed())
		dur = 5 + 0.1 * T.get_level()

		B = T.get_buff_of_type(pos)
		if B != null:
			pos.apply_custom_timed(T, T, min(level_add + B.get_level(), 2000), dur)
		else:
			pos.apply_custom_timed(T, T, level_add, dur)

		B = C.get_buff_of_type(neg)
		if B != null:
			neg.apply_custom_timed(T, T, min(level_add + B.get_level(), 2000), dur)
		else:
			neg.apply_custom_timed(T, T, level_add, dur)


