# Basics of Calculus
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Learn[/color]\n"
	text += "Grants a tower 1 experience.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.04 experience\n"
	text += " \n"
	text += "15s cooldown\n"

	return text


func item_init():
	var autocast: Autocast = Autocast.make()
	autocast.display_name = "Learn"
	autocast.caster_art = ""
	autocast.target_art = "AlimTarget.mdl"
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.target_self = true
	autocast.cooldown = 15
	autocast.is_extended = false
	autocast.mana_cost = 0
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.cast_range = 200
	autocast.auto_range = 200
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_autocast(event: Event):
	var itm: Item = self
	event.get_target().add_exp(1.0 * itm.get_carrier().get_level() * 0.04)
