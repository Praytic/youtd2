extends ItemBehavior


# NOTE: reworked this script a bit because it seems that the
# original was coded when Iterate didn't have next_random()
# yet so the original script had to do a bunch of extra
# stuff.


var stun_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 8)


func item_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)
	stun_bt.set_special_effect("res://src/effects/purge_buff_target.tscn", 50, 1.0, Color(Color.GREEN, 0.75))


func periodic(_event: Event):
	var tower: Tower = item.get_carrier()
	var iterate: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1000)
	var loop_counter: int = 3

	CombatLog.log_item_ability(item, null, "Activate Trap")

	while true:
		var creep: Unit = iterate.next_random()

		if creep == null:
			break

		loop_counter = loop_counter - 1

		if tower.get_level() == 25:
			stun_bt.apply_only_timed(tower, creep, 1.0)
		else:
			stun_bt.apply_only_timed(tower, creep, 0.5)

		if loop_counter == 0:
			break
