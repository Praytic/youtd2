# Spiderling
extends Item


var boekie_spiderling_slow: BuffType


func get_extra_tooltip_text() -> String:
	return "[color=gold]Spiderling Poison[/color]\nWhen the carrier of this item attacks there is a 25% attackspeed adjusted chance that the attacked creep is slowed by 5% for 4 seconds."

func _item_init():
	var buff_type: BuffType = TriggersBuffType.new()
	buff_type.add_event_on_attack(self, "_on_attack", 1.0, 0.0)
	_buff_type_list.append(buff_type)

	var m: Modifier = Modifier.new() 

	m.add_modification(Modification.Type.MOD_MOVESPEED, -0.05, 0) 
	boekie_spiderling_slow = BuffType.new("boekie_spiderling_slow", 4, 0, false)
	boekie_spiderling_slow.set_buff_icon("@@0@@") 
	boekie_spiderling_slow.set_buff_modifier(m) 
	boekie_spiderling_slow.set_stacking_group("boekieSpiderlingSlow")


func _on_attack(event: Event):
	var itm = self

	var tower: Tower = itm.get_carrier() 
	var speed: float = tower.get_base_attack_speed()  

	if tower.calc_chance(0.25 * speed) == true:
		boekie_spiderling_slow.apply(tower, event.get_target(), 1)
