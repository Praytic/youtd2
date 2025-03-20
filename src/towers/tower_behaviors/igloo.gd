extends TowerBehavior


var extreme_cold_bt: BuffType
var stun_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {stun_duration = 0.4, cold_damage = 700, cold_damage_add = 35, cold_slow = 0.20},
		2: {stun_duration = 0.8, cold_damage = 1500, cold_damage_add = 75, cold_slow = 0.25},
		3: {stun_duration = 1.2, cold_damage = 2800, cold_damage_add = 140, cold_slow = 0.30},
	}


const COLD_SLOW_ADD: float = 0.004
const COLD_SLOW_DURATION: float = 4
const COLD_RANGE: float = 900


func load_triggers(triggers: BuffType):
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, COLD_RANGE, TargetType.new(TargetType.CREEPS))


func boekie_igloo_end(event: Event):
	var buff: Buff = event.get_buff()
	stun_bt.apply_only_timed(buff.get_caster(), buff.get_buffed_unit(), _stats.stun_duration)


func tower_init():
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_MOVESPEED, -_stats.cold_slow, -COLD_SLOW_ADD)
	extreme_cold_bt = BuffType.new("extreme_cold_bt", COLD_SLOW_DURATION, 0, false, self)
	extreme_cold_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	extreme_cold_bt.set_buff_modifier(modifier)
	extreme_cold_bt.add_event_on_expire(boekie_igloo_end)
	extreme_cold_bt.set_buff_tooltip("Extreme Cold\nReduces movement speed and stuns creep when the debuff expires.")

	stun_bt = CbStun.new("igloo_stun", 0, 0, false, self)


func on_unit_in_range(event: Event):
	var creep: Unit = event.get_target()
	var level: int = tower.get_level()
	var damage: float = _stats.cold_damage + _stats.cold_damage_add * level

	tower.do_spell_damage(creep, damage, tower.calc_spell_crit_no_bonus())
	extreme_cold_bt.apply(tower, creep, level)

	Effect.create_scaled("res://src/effects/frost_armor_damage.tscn", Vector3(creep.get_x(), creep.get_y(), 30), 0, 3)
