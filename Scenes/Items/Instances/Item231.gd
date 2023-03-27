# Currency Converter
extends Item


func _item_init():
	var buff_type: BuffType = TriggersBuffType.new()
	buff_type.add_periodic_event(self, "_on_periodic", 1.0)
	_buff_type_list.append(buff_type)


func _on_periodic(event: Event):
	var itm = self

	var tower: Tower = itm.get_carrier()
	var lvl: int = tower.get_level()
	event.enable_advanced(15 - lvl * 0.3, false)
	if tower.get_exp() >= 2.0:
		Utils.sfx_on_unit("UI\\Feedback\\GoldCredit\\GoldCredit.mdl", tower, "head")
		tower.remove_exp_flat(2)
		tower.getOwner().give_gold(7, tower, true, true)
	else:
		Utils.display_floating_text("Not enough credits!", tower, 255, 0, 0)
