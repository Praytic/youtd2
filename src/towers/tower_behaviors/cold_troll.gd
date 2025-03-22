extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] Fixed bug where tooltip had
# incorrect value (but logic was correct). For tier 1 troll,
# Blizzard spell, tooltip says level bonus is "+0.1% slow"
# when it's really "+0.01% slow" like it is for all other
# tiers.


var slow_bt: BuffType
var blizzard_st: SpellType
var stun_bt: BuffType


const SLOW_CHANCE_ADD: float = 0.01
const STUN_CHANCE_ADD: float = 0.001


func get_tier_stats() -> Dictionary:
	return {
		1: {slow_chance = 0.30, mod_movespeed = 0.07, mod_movespeed_add = 0.0001, slow_duration = 4.0, stun_chance = 0.10, stun_duration = 0.25, blizzard_damage = 60, blizzard_radius = 200, blizzard_wave_count = 5, damage_ratio_add = 0.1},
		2: {slow_chance = 0.35, mod_movespeed = 0.09, mod_movespeed_add = 0.0001, slow_duration = 4.5, stun_chance = 0.15, stun_duration = 0.50, blizzard_damage = 333, blizzard_radius = 300, blizzard_wave_count = 6, damage_ratio_add = 0.036},
		3: {slow_chance = 0.40, mod_movespeed = 0.11, mod_movespeed_add = 0.0001, slow_duration = 5.0, stun_chance = 0.20, stun_duration = 0.75, blizzard_damage = 572, blizzard_radius = 400, blizzard_wave_count = 7, damage_ratio_add = 0.033},
		4: {slow_chance = 0.45, mod_movespeed = 0.14, mod_movespeed_add = 0.0001, slow_duration = 5.5, stun_chance = 0.25, stun_duration = 1.00, blizzard_damage = 1000, blizzard_radius = 500, blizzard_wave_count = 8, damage_ratio_add = 0.05},
	}


func on_autocast(event: Event):
	var u: Unit = event.get_target()
	blizzard_st.point_cast_from_caster_on_point(tower, Vector2(u.get_x(), u.get_y()), 1.00 + int(tower.get_level()) * _stats.damage_ratio_add, tower.calc_spell_crit_no_bonus())


# NOTE: OnBlizzard() in original script
func blizzard_st_on_damage(event: Event, _dummy: DummyUnit):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	var slow_chance: float = _stats.slow_chance + SLOW_CHANCE_ADD * level
	var stun_chance: float = _stats.stun_chance + STUN_CHANCE_ADD * level

	if tower.calc_chance(slow_chance):
		slow_bt.apply(tower, target, level)

	if tower.calc_chance(stun_chance):
		stun_bt.apply(tower, target, level)


func tower_init():
	var mod2: Modifier = Modifier.new()
	slow_bt = BuffType.new("slow_bt", _stats.slow_duration, 0.0, false, self)
	mod2.add_modification(Modification.Type.MOD_MOVESPEED, -_stats.mod_movespeed, -_stats.mod_movespeed_add)
	slow_bt.set_buff_modifier(mod2)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")

	slow_bt.set_buff_tooltip(tr("UPAM"))

	stun_bt = CbStun.new("stun_bt", _stats.stun_duration, 0, false, self)

	blizzard_st = SpellType.new(SpellType.Name.BLIZZARD, 9.00, self)
	blizzard_st.set_damage_event(blizzard_st_on_damage)
	blizzard_st.data.blizzard.damage = _stats.blizzard_damage
	blizzard_st.data.blizzard.radius = _stats.blizzard_radius
	blizzard_st.data.blizzard.wave_count = _stats.blizzard_wave_count
