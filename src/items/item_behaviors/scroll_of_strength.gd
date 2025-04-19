extends ItemBehavior


var strength_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 40)


func item_init():
	strength_bt = BuffType.new("strength_bt", 0.0, 0.0, true, self)
	strength_bt.set_buff_icon("res://resources/icons/generic_icons/biceps.tres")
	strength_bt.set_buff_tooltip(tr("0I23"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_DAMAGE_BASE_PERC, 0.1, 0)
	strength_bt.set_buff_modifier(mod)


func on_autocast(_event: Event):
	var tower: Tower = item.get_carrier()
	var lvl: int = tower.get_level()
	var it: Iterate
	var next: Unit

	if item.user_int > 0:
		it = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 350)

		while true:
			next = it.next()

			if next == null:
				break

			strength_bt.apply_custom_timed(tower, next, lvl * 2, 4.0)

		item.user_int = item.user_int - 1

	item.set_charges(item.user_int)
	await Utils.create_manual_timer(0.1, self).timeout
	item.set_charges(item.user_int)


func on_create():
	item.set_charges(10)
#	The item will use the userInt for charges, cause charges are bugged.
	item.user_int = 10


func periodic(_event: Event):
	item.user_int = item.user_int + 3

	if item.user_int >= 11:
		item.user_int = 10

	item.set_charges(item.user_int)
	await Utils.create_manual_timer(0.1, self).timeout
	item.set_charges(item.user_int)
