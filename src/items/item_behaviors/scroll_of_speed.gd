extends ItemBehavior


var speed_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 40)


func item_init():
	speed_bt = BuffType.new("speed_bt", 0.0, 0.0, true, self)
	speed_bt.set_buff_icon("res://resources/icons/generic_icons/hammer_drop.tres")
	speed_bt.set_buff_tooltip(tr("P7Z5"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_ATTACKSPEED, 0.1, 0)
	speed_bt.set_buff_modifier(mod)


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

			speed_bt.apply_custom_timed(tower, next, lvl * 2, 4.0)

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
