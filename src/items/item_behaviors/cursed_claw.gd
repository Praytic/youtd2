extends ItemBehavior


var cripple_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	cripple_bt = BuffType.new("cripple_bt", 0, 0, false, self)
	cripple_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	cripple_bt.set_buff_tooltip(tr("ARXM"))
	var mod: Modifier = Modifier.new() 
	mod.add_modification(ModificationType.enm.MOD_MOVESPEED, -0.10, -0.004) 
	cripple_bt.set_buff_modifier(mod) 


func on_attack(event: Event):
	var tower: Tower = item.get_carrier()
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	cripple_bt.apply(tower, target, level)
