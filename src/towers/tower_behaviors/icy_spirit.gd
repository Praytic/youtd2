extends TowerBehavior


# NOTE: changed the script a bit. Original script
# implementes nova delay via periodic events. Changed to use
# await instead.


var slow_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {nova_dmg = 350, nova_dmg_add = 17.5},
		2: {nova_dmg = 910, nova_dmg_add = 45.5},
		3: {nova_dmg = 2100, nova_dmg_add = 105},
	}


const NOVA_CHANCE: float = 0.25
const NOVA_CHANCE_ADD: float = 0.005
const NOVA_RANGE: float = 900
const NOVA_AOE_RADIUS: float = 200
const NOVA_MOD_MOVESPEED: float = 0.125
const NOVA_MOD_MOVESPEED_ADD: float = 0.005
const NOVA_SLOW_DURATION: float = 4.0


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	var slow_bt_mod: Modifier = Modifier.new()
	slow_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, -NOVA_MOD_MOVESPEED, -NOVA_MOD_MOVESPEED_ADD)

	slow_bt = BuffType.new("slow_bt", NOVA_SLOW_DURATION, 0, false, self)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/amber_mosquito.tres")
	slow_bt.set_buff_modifier(slow_bt_mod)
	slow_bt.set_buff_tooltip("Nova Storm\nReduces movement speed.")


func on_attack(_event: Event):
	var level: int = tower.get_level()

	var nova_chance: float = NOVA_CHANCE + NOVA_CHANCE_ADD * level

	if !tower.calc_chance(nova_chance):
		return

	CombatLog.log_ability(tower, null, "Nova Storm")

	var nova_count: int
	if level < 15:
		nova_count = 3
	elif level < 25:
		nova_count = 4
	else:
		nova_count = 5

	for i in range(0, nova_count):
#		Check that tower still exists, could have been sold
#		during await.
		if !Utils.unit_is_valid(tower):
			return

		var creeps_near_tower: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), NOVA_RANGE)
		var main_target: Unit = creeps_near_tower.next_random()

		if main_target != null:
			tower.do_spell_damage_aoe_unit(main_target, NOVA_AOE_RADIUS, _stats.nova_dmg + (level * _stats.nova_dmg_add), tower.calc_spell_crit_no_bonus(), 0.5)
			Effect.create_simple_at_unit("res://src/effects/frost_bolt_missile.tscn", main_target)

			var creeps_near_target: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), main_target, NOVA_AOE_RADIUS)

			while true:
				var aoe_target = creeps_near_target.next()

				if aoe_target == null:
					break

				slow_bt.apply(tower, aoe_target, level)

		await Utils.create_manual_timer(0.1, self).timeout
