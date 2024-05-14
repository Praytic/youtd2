extends TowerBehavior

# NOTE: some stats are multiplied by 1000

var slow_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {dmg_to_undead_add = 0.002, aoe_damage = 50, aoe_damage_add = 2, slow_value = 50, slow_value_add = 2, slow_duration_add = 0.02},
		2: {dmg_to_undead_add = 0.004, aoe_damage = 200, aoe_damage_add = 8, slow_value = 60, slow_value_add = 4, slow_duration_add = 0.04},
		3: {dmg_to_undead_add = 0.006, aoe_damage = 550, aoe_damage_add = 24, slow_value = 80, slow_value_add = 6, slow_duration_add = 0.06},
		4: {dmg_to_undead_add = 0.008, aoe_damage = 1000, aoe_damage_add = 48, slow_value = 100, slow_value_add = 8, slow_duration_add = 0.08},
		5: {dmg_to_undead_add = 0.010, aoe_damage = 1800, aoe_damage_add = 96, slow_value = 120, slow_value_add = 10, slow_duration_add = 0.10},
	}


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, -0.25, 0.002)


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var aoe_damage: String = Utils.format_float(_stats.aoe_damage, 2)
	var aoe_damage_add: String = Utils.format_float(_stats.aoe_damage_add, 2)
	var slow_value: String = Utils.format_percent(_stats.slow_value * 0.1 * 0.01, 2)
	var slow_value_add: String = Utils.format_percent(_stats.slow_value_add * 0.1 * 0.01, 2)
	var slow_duration_add: String = Utils.format_float(_stats.slow_duration_add, 2)

	autocast.title = "Soul Chill"
	autocast.icon = "res://Resources/Icons/fire/flame_blue_glowing.tres"
	autocast.description_short = "Deals spell damage and slows units in a small area.\n"
	autocast.description = "Chills the souls of all creeps in 250 AoE of the target, dealing %s spell damage and slowing them by %s for 4 seconds.\n" % [aoe_damage, slow_value] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage\n" % aoe_damage_add \
	+ "+%s slow\n" % slow_value_add \
	+ "+%s seconds duration\n" % slow_duration_add
	autocast.cooldown = 1
	autocast.mana_cost = 20
	autocast.target_type = null
	autocast.caster_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.is_extended = false
	autocast.auto_range = 900
	autocast.cast_range = 900
	autocast.num_buffs_before_idle = 0
	autocast.target_art = "Abilities\\Spells\\Undead\\RaiseSkeletonWarrior\\RaiseSkeleton.mdl"
	autocast.buff_type = null
	autocast.target_self = false
	autocast.handler = on_autocast

	return [autocast]

	
func tower_init():
	var slow_bt_mod: Modifier = Modifier.new()
	slow_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0, -0.001)
	slow_bt = BuffType.new("slow_bt", 0, 0, false, self)
	slow_bt.set_buff_icon("res://Resources/Icons/GenericIcons/foot_trip.tres")
	slow_bt.set_buff_modifier(slow_bt_mod)
	slow_bt.set_buff_tooltip("Slowed\nReduces movement speed.")


func on_autocast(event: Event):
	var targ: Unit = event.get_target()
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), targ, 250)
	var next: Unit

	var calculated_slow: float = _stats.slow_value + tower.get_level() * _stats.slow_value_add
	var duration: float = 4.0 + tower.get_level() * _stats.slow_duration_add
	var spelldmg: float = _stats.aoe_damage + tower.get_level() * _stats.aoe_damage_add

	while true:
		next = it.next()

		if next == null:
			break

		slow_bt.apply_custom_timed(tower, next, int(calculated_slow), duration)
		tower.do_spell_damage(next, spelldmg, tower.calc_spell_crit_no_bonus())

	SFX.sfx_at_unit("Abilities\\Spells\\Undead\\RaiseSkeletonWarrior\\RaiseSkeleton.mdl", targ)
