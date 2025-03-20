extends ItemBehavior


func on_autocast(event: Event):
	event.get_target().add_exp(1.0 + item.get_carrier().get_level() * 0.04)
