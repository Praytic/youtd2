extends TowerBehavior


var cold_feet_bt: BuffType
var cold_arms_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {dmg_increase = 200},
		2: {dmg_increase = 250},
		3: {dmg_increase = 300},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func on_cleanup(event: Event):
	var b: Buff = event.get_buff()
	b.get_buffed_unit().user_int = 0


func tower_init():
	var cold_feet_bt_mod: Modifier = Modifier.new()
	var cold_arms_bt_mod: Modifier = Modifier.new()

	cold_feet_bt = BuffType.new("cold_feet_bt", 6, 0, true, self)
	cold_feet_bt_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0, -0.001)
	cold_feet_bt.set_buff_modifier(cold_feet_bt_mod)
	cold_feet_bt.set_buff_icon("res://resources/icons/generic_icons/barefoot.tres")
	cold_feet_bt.add_event_on_cleanup(on_cleanup)
	cold_feet_bt.set_buff_tooltip(tr("RHKN"))

	cold_arms_bt = BuffType.new("cold_arms_bt", 6, 0, true, self)
	cold_arms_bt_mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0, 0.001)
	cold_arms_bt.set_buff_modifier(cold_arms_bt_mod)
	cold_arms_bt.set_buff_icon("res://resources/icons/generic_icons/biceps.tres")
	cold_arms_bt.set_buff_tooltip(tr("ED2V"))


func on_attack(_event: Event):
	var active_stack_count: int = tower.user_int
	var new_stack_count: int = min(active_stack_count + 1, 10)
	tower.user_int = new_stack_count
	
	var cold_feet_per_stack: int
	if tower.get_level() < 15:
		cold_feet_per_stack = 50
	elif tower.get_level() < 25:
		cold_feet_per_stack = 40
	else:
		cold_feet_per_stack = 30

	var cold_feet_buff_level: int = cold_feet_per_stack * new_stack_count
	var cold_arms_buff_level: int = _stats.dmg_increase * new_stack_count
	var cold_feet_buff: Buff = cold_feet_bt.apply(tower, tower, cold_feet_buff_level)
	var cold_arms_buff: Buff = cold_arms_bt.apply(tower, tower, cold_arms_buff_level)

	cold_feet_buff.set_displayed_stacks(new_stack_count)
	cold_arms_buff.set_displayed_stacks(new_stack_count)


func on_create(_preceding_tower: Tower):
	tower.user_int = 0
