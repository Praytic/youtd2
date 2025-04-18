extends TowerBehavior


# NOTE: in original script an EventTypeList is used to add
# "on_damage" event handler. Changed script to add handler
# directly to tower.

# NOTE: [ORIGINAL_GAME_BUG] fixed bug in poison buff logic.
# Original script compares the spell_damage_dealt stat of
# active buff's caster with current tower. If current tower
# has higher spell_damage_dealt stat, the buff will be
# replaced. The problem is that original script didn't
# consider the case where there is one Cute Small Spider
# tower and it's spell_damage_dealt stat changes frequently
# because of buffs from another tower or items. The buff
# will get replaced everytime spell_damage_dealt stat
# changes. If tower's spell_damage_dealt stat went up and
# down frequently, then buff would get reset frequently.
# This would cause the buff's periodic timer for damage to
# get constantly reset. If spell_damage_dealt stat changed
# every second, then it's possible for poison damage ticks
# to never happen at all!


var poison_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 30, damage_add = 1.5, max_damage = 150, max_damage_add = 7.5},
		2: {damage = 90, damage_add = 4.5, max_damage = 450, max_damage_add = 22.5},
		3: {damage = 270, damage_add = 13.5, max_damage = 1350, max_damage_add = 67.5},
		4: {damage = 750, damage_add = 37.5, max_damage = 3750, max_damage_add = 187.5},
	}


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


# NOTE: D1000_Spider_Damage() in original script
func poison_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var poison_damage: float = buff.user_real
	
	tower.do_spell_damage(target, poison_damage, tower.calc_spell_crit_no_bonus())


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	var active_buff: Buff = target.get_buff_of_type(poison_bt)
	
	var active_stacks: int = 0
	var active_damage: float = 0
	var active_damage_cap: float = 0
	var active_spell_damage_dealt: float = -1
	if active_buff != null:
		active_stacks = active_buff.user_int
		active_damage = active_buff.user_real
		active_damage_cap = active_buff.user_real2
		active_spell_damage_dealt = active_buff.user_real3

	var new_stacks: int = min(active_stacks + 1, 5)
	var added_damage: float = _stats.damage + _stats.damage_add * level
	var this_damage_cap: float = _stats.max_damage + _stats.max_damage_add * level
	var new_damage_cap: float = max(active_damage_cap, this_damage_cap)
	var new_damage: float = min(active_damage + added_damage, new_damage_cap)
	var new_spell_damage_dealt: float = tower.get_prop_spell_damage_dealt()

#	NOTE: [ORIGINAL_GAME_DEVIATION] in original game, the
#	spell power comparison and buff replacement did not
#	consider the tier of the tower. Add it so that higher
#	tier towers always have prio.
	if active_buff != null && active_buff.get_caster() != tower:
		var active_tier: int = active_buff.get_tower_tier()
		var new_tier: int = tower.get_tier()

		var this_tower_is_more_powerful: bool = new_tier >= active_tier && new_spell_damage_dealt > active_spell_damage_dealt

		if this_tower_is_more_powerful:
			active_buff.remove_buff()

	active_buff = poison_bt.apply(tower, target, 1)
	active_buff.user_int = new_stacks
	active_buff.set_displayed_stacks(new_stacks)
	active_buff.user_real = new_damage
	active_buff.user_real2 = new_damage_cap
	if new_spell_damage_dealt > active_spell_damage_dealt:
		active_buff.user_real3 = new_spell_damage_dealt


func tower_init():
	poison_bt = BuffType.new("poison_bt", 5, 0.05, false, self)
	poison_bt.set_buff_icon("res://resources/icons/generic_icons/poison_gas.tres")
	poison_bt.add_periodic_event(poison_bt_periodic, 1)
	poison_bt.set_buff_tooltip(tr("TTST"))
