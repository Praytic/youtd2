extends ItemBehavior


var cripple_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Cripple[/color]\n"
	text += "This artifact slows the attacked creep by 10% for 5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% slow\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	cripple_bt = BuffType.new("cripple_bt", 0, 0, false, self)
	cripple_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	cripple_bt.set_buff_tooltip("Cripple\nReduces movement speed.")
	var mod: Modifier = Modifier.new() 
	mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.001) 
	cripple_bt.set_buff_modifier(mod) 


func on_attack(event: Event):
	var tower: Tower = item.get_carrier()

	cripple_bt.apply_custom_timed(tower, event.get_target(), 100 + tower.get_level() * 4, 5)
