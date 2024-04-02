# Spiderling
extends ItemBehavior


var boekie_spiderling_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Spiderling Poison[/color]\n"
	text += "When the carrier of this item attacks there is a 25% attackspeed adjusted chance that the attacked creep is slowed by 5% for 4 seconds.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	boekie_spiderling_bt = BuffType.new("boekie_spiderling_bt", 4, 0, false, self)
	boekie_spiderling_bt.set_buff_icon("star.tres") 
	boekie_spiderling_bt.set_stacking_group("boekieSpiderlingSlow")
	boekie_spiderling_bt.set_buff_tooltip("Webbed\nReduces movement speed.")
	var mod: Modifier = Modifier.new() 
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.05, 0) 
	boekie_spiderling_bt.set_buff_modifier(mod) 


func on_attack(event: Event):
	var tower: Tower = item.get_carrier() 
	var speed: float = tower.get_base_attackspeed()  

	if tower.calc_chance(0.25 * speed) == true:
		CombatLog.log_item_ability(item, event.get_target(), "Spiderling Poison")
		boekie_spiderling_bt.apply(tower, event.get_target(), 1)
