extends TowerBehavior


var curse_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {dmg_increase = 0.02, dmg_increase_add = 0.0004},
		2: {dmg_increase = 0.04, dmg_increase_add = 0.0008},
		3: {dmg_increase = 0.06, dmg_increase_add = 0.0012},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	curse_bt = BuffType.new("curse_bt", 0, 0, false, self)
	curse_bt.set_buff_icon("res://resources/icons/generic_icons/open_wound.tres")
	curse_bt.set_buff_tooltip(tr("O4H7"))


# NOTE: buff is used only to keep track of stacks and as
# visual indicator. MOD_DMG_FROM_DARKNESS modifier is
# applied directly. It's possible to rework this script so
# that modifier is attached to buff but it's tricky.
func on_attack(event: Event):
	var target: Unit = event.get_target()
	var buff: Buff = target.get_buff_of_type(curse_bt)

	var active_stacks: int
	if buff != null:
		active_stacks = buff.get_level()
	else:
		active_stacks = 0

	if active_stacks < 10:
		var new_stacks: int = active_stacks + 1
		
		target.modify_property(Modification.Type.MOD_DMG_FROM_DARKNESS, _stats.dmg_increase + tower.get_level() * _stats.dmg_increase_add)

		buff = curse_bt.apply_to_unit_permanent(tower, target, new_stacks)
		buff.set_displayed_stacks(new_stacks)
