# Spiderling
extends Item


func _item_init():
	var buff_type: BuffType = TriggersBuffType.new()
	buff_type.add_event_on_attack(self, "_on_attack", 1.0, 0.0)
	_buff_type_list.append(buff_type)


func _on_attack(event: Event):
	var itm = self

	var m: Modifier = Modifier.new() 
	
	m.add_modification(Modification.Type.MOD_MOVESPEED, -0.05, 0) 
	var boekie_spiderling_slow: Buff = Buff.new("boekie_spiderling_slow", 4, 0, false)
	boekie_spiderling_slow.set_buff_icon("@@0@@") 
	boekie_spiderling_slow.set_buff_modifier(m) 
	boekie_spiderling_slow.set_stacking_group("boekieSpiderlingSlow")

	var tower: Tower = itm.get_carrier() 
	var speed: float = tower.get_base_attack_speed()  

	if tower.calc_chance(0.25 * speed) == true:
		boekie_spiderling_slow.apply(tower, event.get_target(), 1)
