extends ItemBehavior


var enraged_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	enraged_bt = BuffType.new("enraged_bt", 1.5, 0, true, self)
	enraged_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	enraged_bt.set_buff_tooltip(tr("0JUJ"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_ATTACKSPEED, 0.0, 0.005)
	mod.add_modification(ModificationType.enm.MOD_SPELL_DAMAGE_DEALT, 0.0, 0.0025)
	mod.add_modification(ModificationType.enm.MOD_DAMAGE_ADD_PERC, 0.0, 0.01)
	enraged_bt.set_buff_modifier(mod)


func on_attack(_event: Event):
	var tower: Tower = item.get_carrier()
	var buff: Buff = tower.get_buff_of_type(enraged_bt)

	var active_stacks: int
	if buff != null:
		active_stacks = buff.get_level()
	else:
		active_stacks = 0

	var new_stacks: int = active_stacks + 1
	new_stacks = min(new_stacks, 120)

	buff = enraged_bt.apply(tower, tower, new_stacks)
	buff.set_displayed_stacks(new_stacks)
