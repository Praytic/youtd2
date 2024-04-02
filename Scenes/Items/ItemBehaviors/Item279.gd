# Magic Conductor
extends ItemBehavior

var boekie_magic_conductor_bt: BuffType

func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Conduct Magic[/color]\n"
	text += "Whenever the carrier of this item is targeted by a spell it gains +20% attackspeed for 10 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.5% attackspeed\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_spell_targeted(on_spell_target)


func item_init():
	boekie_magic_conductor_bt = BuffType.new("boekie_magic_conductor_bt", 0.0, 0.0, true, self)
	boekie_magic_conductor_bt.set_buff_icon("orb_swirly.tres")
	boekie_magic_conductor_bt.set_buff_tooltip("Magical Conduction\nIncreases attack speed.")
	boekie_magic_conductor_bt.set_stacking_group("boekie_magicConductor")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.20, 0.005)
	boekie_magic_conductor_bt.set_buff_modifier(mod)


func on_spell_target(_event: Event):
	var tower: Tower = item.get_carrier()
	var lvl: int = tower.get_level()

	CombatLog.log_item_ability(item, null, "Conduct Magic")
	boekie_magic_conductor_bt.apply_custom_timed(tower, tower, lvl, 10.0)
