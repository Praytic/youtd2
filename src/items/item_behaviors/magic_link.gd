extends ItemBehavior


func on_autocast(event: Event):
	event.get_target().add_exp_flat(item.get_carrier().remove_exp_flat(30))
