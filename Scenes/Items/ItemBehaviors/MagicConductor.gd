extends ItemBehavior

var conduction_bt: BuffType

func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Conduct Magic[/color]\n"
	text += "Whenever the carrier is targeted by a spell, it gains +20% attack speed for 10 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.5% attack speed\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_spell_targeted(on_spell_target)


func item_init():
	conduction_bt = BuffType.new("conduction_bt", 0.0, 0.0, true, self)
	conduction_bt.set_buff_icon("res://Resources/Icons/GenericIcons/rolling_energy.tres")
	conduction_bt.set_buff_tooltip("Magical Conduction\nIncreases attack speed.")
	conduction_bt.set_stacking_group("boekie_magicConductor")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.20, 0.005)
	conduction_bt.set_buff_modifier(mod)


func on_spell_target(_event: Event):
	var tower: Tower = item.get_carrier()
	var lvl: int = tower.get_level()

	CombatLog.log_item_ability(item, null, "Conduct Magic")
	conduction_bt.apply_custom_timed(tower, tower, lvl, 10.0)
