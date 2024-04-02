# Jungle Stalker's Doll
extends ItemBehavior


var poussix_doll_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Bloodthirst[/color]\n"
	text += "When the carrier kills a unit it becomes enraged for 3 seconds. While enraged, it has 20% bonus attackspeed. Cannot retrigger while active!"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% attackspeed\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.025, 0.001)


func item_init():
	poussix_doll_bt = BuffType.new("poussix_doll_bt", 0, 0, true, self)
	poussix_doll_bt.set_buff_icon("winged_man.tres")
	poussix_doll_bt.set_buff_tooltip("Enraged\nIncreases attack speed.")
	poussix_doll_bt.set_stacking_group("poussix_doll_bt")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.20, 0.004)
	poussix_doll_bt.set_buff_modifier(mod)


func on_kill(event: Event):
	var tower: Tower = item.get_carrier()

	if tower.get_buff_of_type(poussix_doll_bt) == null:
		SFX.sfx_at_unit("StampedMissileDeath.mdl", event.get_target())
		poussix_doll_bt.apply_custom_timed(tower, tower, tower.get_level(), 3.0)

