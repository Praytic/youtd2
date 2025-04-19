extends ItemBehavior


var slow_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	slow_bt = BuffType.new("slow_bt", 4, 0, false, self)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/spider_web.tres") 
	slow_bt.set_buff_tooltip(tr("Y2QA"))
	var mod: Modifier = Modifier.new() 
	mod.add_modification(ModificationType.enm.MOD_MOVESPEED, -0.05, 0) 
	slow_bt.set_buff_modifier(mod) 


func on_attack(event: Event):
	var tower: Tower = item.get_carrier() 
	var speed: float = tower.get_base_attack_speed()  

	if tower.calc_chance(0.25 * speed) == true:
		CombatLog.log_item_ability(item, event.get_target(), "Spiderling Poison")
		slow_bt.apply(tower, event.get_target(), 1)
