# Sleeve of Rage
extends ItemBehavior


var enraged_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Ancient Rage[/color]\n"
	text += "On attack this tower will enrage for 1.5 seconds gaining 0.5% increased attackspeed 1% attack damage and 0.25% spell damage. This effect stacks up to 120 times.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	enraged_bt = BuffType.new("enraged_bt", 5, 0, true, self)
	enraged_bt.set_buff_icon("winged_man.tres")
	enraged_bt.set_buff_tooltip("Enraged\nIncreases attack speed, spell damage and attack damage.")
	enraged_bt.set_stacking_group("sir_sleeve_group")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.005)
	mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.0, 0.0025)
	mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, 0.01)
	enraged_bt.set_buff_modifier(mod)


func on_attack(_event: Event):
	var tower: Tower = item.get_carrier()
	var b: Buff = tower.get_buff_of_type(enraged_bt)

	var level: int
	if b != null:
		level = b.get_level()
	else:
		level = 0

	if level < 120:
		enraged_bt.apply_advanced(tower, tower, 1 + level, level, 1.5)
	else:
		b.refresh_duration()
