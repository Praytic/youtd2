extends ItemBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] Renamed
# "Mini Furbolg"=>"Mini Forest Troll"


var rampage_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	rampage_bt = BuffType.new("rampage_bt", 4, 0, true, self)
	rampage_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	rampage_bt.set_buff_tooltip(tr("R5MU"))
	var mod: Modifier = Modifier.new() 
	mod.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.00, 0.0) 
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.25, 0.0) 
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.05, 0.0) 
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.40, 0.0) 
	rampage_bt.set_buff_modifier(mod) 


func on_attack(_event: Event):
	var tower: Tower = item.get_carrier()

	if !(tower.get_buff_of_type(rampage_bt) != null) && tower.calc_chance(0.14 * tower.get_base_attack_speed()):
		CombatLog.log_item_ability(item, null, "Rampage")
		rampage_bt.apply(tower, tower, tower.get_level())
