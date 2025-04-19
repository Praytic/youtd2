extends ItemBehavior


var boost_bt: BuffType
var drain_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func item_init():
	boost_bt = BuffType.new("boost_bt", 2.5, 0.0, true, self)
	boost_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	boost_bt.set_buff_tooltip(tr("2MER"))
	var boost_bt_mod: Modifier = Modifier.new()
	boost_bt_mod.add_modification(ModificationType.enm.MOD_ATTACKSPEED, 0.0, 0.0002)
	boost_bt.set_buff_modifier(boost_bt_mod)

	drain_bt = BuffType.new("drain_bt", 2.5, 0.0, false, self)
	drain_bt.set_buff_icon("res://resources/icons/generic_icons/energy_breath.tres")
	drain_bt.set_buff_tooltip(tr("3KMZ"))
	var drain_bt_mod: Modifier = Modifier.new()
	drain_bt_mod.add_modification(ModificationType.enm.MOD_MOVESPEED, 0.0, -0.0002)
	drain_bt.set_buff_modifier(drain_bt_mod)


func on_damage(event: Event):
	if !event.is_main_target():
		return

	var tower: Tower = item.get_carrier()
	var creep: Creep = event.get_target()
	var level_add: int = int(100.0 * tower.get_current_attack_speed())
	var duration: float = 5 + 0.1 * tower.get_level()

	var positive_buff: Buff = tower.get_buff_of_type(boost_bt)
	if positive_buff != null:
		boost_bt.apply_custom_timed(tower, tower, min(level_add + positive_buff.get_level(), 2000), duration)
	else:
		boost_bt.apply_custom_timed(tower, tower, level_add, duration)

	positive_buff = tower.get_buff_of_type(boost_bt)
	if positive_buff != null:
		var stack_count: int = positive_buff.get_level() / 100
		positive_buff.set_displayed_stacks(stack_count)

	var negative_buff: Buff = creep.get_buff_of_type(drain_bt)
	if negative_buff != null:
		drain_bt.apply_custom_timed(tower, creep, min(level_add + negative_buff.get_level(), 2000), duration)
	else:
		drain_bt.apply_custom_timed(tower, creep, level_add, duration)

	negative_buff = creep.get_buff_of_type(drain_bt)
	if negative_buff != null:
		var stack_count: int = negative_buff.get_level() / 100
		negative_buff.set_displayed_stacks(stack_count)
