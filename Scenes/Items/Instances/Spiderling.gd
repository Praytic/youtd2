extends Item

# TODO: visual


var on_attack_buff: Buff = null


func _add_to_tower_subclass():
	var on_attack_buff: Buff = Buff.new("spiderling_buff")
	on_attack_buff.add_event_handler(self, "_on_attack", 1.0)
	on_attack_buff.apply_to_unit_permanent(get_carrier(), get_carrier(), 0, false)


func _remove_to_tower_subclass():
	if on_attack_buff != null:
		on_attack_buff.expire()


# TODO: does goldcost on website mean that each time this
# trigger is called, gold is reduced by gold cost and if
# there's not enough gold, the trigger stops?
func _on_attack(event: Event):
	var itm = self

    var m: Modifier = Modifier.new() 
    
    m.add_modification(Modification.Type.MOD_MOVESPEED, -0.05, 0) 
    var boekie_spiderling_slow: Buff = Buff.new(boekie_spiderling_slow)
    boekie_spiderling_slow.set_buff_icon("@@0@@") 
    boekie_spiderling_slow.set_buff_modifier(m) 
    boekie_spiderling_slow.set_stacking_group("boekieSpiderlingSlow")

	var tower: Tower = itm.get_carrier() 
	var speed: float = tower.get_base_attack_speed()  

    if tower.calc_chance(0.25 * speed) == true:
    	boekie_spiderling_slow.apply_to_unit(tower, event.get_target(), 1, 4, 0, false)    
