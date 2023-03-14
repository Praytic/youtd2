# Spiderling
extends Item

# TODO: visual



func _item_init():
	var buff: Buff = TriggersBuff.new()
	buff.add_event_on_attack(self, "_on_attack", 1.0, 0.0)
	_buff_list.append(buff)


# TODO: does goldcost on website mean that each time this
# trigger is called, gold is reduced by gold cost and if
# there's not enough gold, the trigger stops?
func _on_attack(event: Event):
	var itm = self

	var m: Modifier = Modifier.new() 
	
	m.add_modification(Unit.ModType.MOD_MOVESPEED, -0.05, 0) 
	var boekie_spiderling_slow: Buff = Buff.new("boekie_spiderling_slow", 4, 0, false)
	boekie_spiderling_slow.set_buff_icon("@@0@@") 
	boekie_spiderling_slow.set_buff_modifier(m) 
	boekie_spiderling_slow.set_stacking_group("boekieSpiderlingSlow")

	var tower: Tower = itm.get_carrier() 
	var speed: float = tower.get_base_attack_speed()  

	if tower.calc_chance(0.25 * speed) == true:
		boekie_spiderling_slow.apply(tower, event.get_target(), 1)
