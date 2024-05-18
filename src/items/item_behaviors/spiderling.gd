extends ItemBehavior


var slow_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Spiderling Poison[/color]\n"
	text += "Whenever the carrier attacks, there is a 25% attack speed adjusted chance to slow the main target by 5% for 4 seconds.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	slow_bt = BuffType.new("slow_bt", 4, 0, false, self)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/spider_web.tres") 
	slow_bt.set_buff_tooltip("Webbed\nReduces movement speed.")
	var mod: Modifier = Modifier.new() 
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.05, 0) 
	slow_bt.set_buff_modifier(mod) 


func on_attack(event: Event):
	var tower: Tower = item.get_carrier() 
	var speed: float = tower.get_base_attack_speed()  

	if tower.calc_chance(0.25 * speed) == true:
		CombatLog.log_item_ability(item, event.get_target(), "Spiderling Poison")
		slow_bt.apply(tower, event.get_target(), 1)
