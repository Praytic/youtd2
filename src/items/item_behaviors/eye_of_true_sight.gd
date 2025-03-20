extends ItemBehavior


var true_sight_bt: BuffType


func item_init():
	true_sight_bt = MagicalSightBuff.new("true_sight_bt", 900, self)
	true_sight_bt.set_buff_tooltip(tr("SH63"))


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	if event.get_target().is_invisible():
		event.damage = event.damage * (1.2 + 0.008 * item.get_carrier().get_level())


func on_pickup():
	var carrier: Unit = item.get_carrier()
	true_sight_bt.apply_to_unit_permanent(carrier, carrier, 0)	
