# Stasis Trap
extends Item


# NOTE: reworked this script a bit because it seems that the
# original was coded when Iterate didn't have next_random()
# yet so the original script had to do a bunch of extra
# stuff.


var cb_stun: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Activate Trap[/color]\n"
	text += "Every 8 seconds this trap stuns 3 creeps in 1000 range for 0.5 seconds.\n"
	text += " \n"
	text += "Level Bonus:\n"
	text += "+0.5 seconds stun at level 25"

	return text

func load_triggers(triggers: BuffType):
	triggers.add_event_periodic(periodic, 8)


func item_init():
	cb_stun = CbStun.new("cb_stun", 0, 0, false, self)


func periodic(_event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	var lvl: int = tower.get_level()
	var iterate: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1000)
	var loop_counter: int = 3

	while true:
		var creep: Unit = iterate.next_random()

		if creep == null:
			break

		loop_counter = loop_counter - 1

		if tower.get_level() == 25:
			cb_stun.apply_only_timed(tower, creep, 1.0)
		else:
			cb_stun.apply_only_timed(tower, creep, 0.5)

		Utils.sfx_at_unit("feralspirittarget.mdl", creep)

		if loop_counter == 0:
			break
