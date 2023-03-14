# Currency Converter
extends Item

# TODO: visual

var on_periodic_buff: Buff = null


func _add_to_tower_subclass():
	on_periodic_buff = TriggersBuff.new()
	on_periodic_buff.add_periodic_event(self, "_on_periodic", 1.0)
	on_periodic_buff.apply_to_unit_permanent(get_carrier(), get_carrier(), 0)


func _remove_from_tower_subclass():
	if on_periodic_buff != null:
		on_periodic_buff.expire()


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
