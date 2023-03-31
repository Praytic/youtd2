extends Tower

# TODO: add tier stats for blizzard damage and wave count,
# when blizzard spell/cast is implemented and has setters
# for those values.

var Troll_blizzardslow: BuffType
var Troll_blizzard: Cast
var cb_stun: BuffType


func _get_tier_stats() -> Dictionary:
	return {
		1: {slow_chance = 0.30, slow = -0.07, slow_add = -0.001, slow_duration = 4.0, stun_chance = 0.10, stun_duration = 0.25, blizzard_damage = 60, blizzard_damage_add = 6, blizzard_radius = 200, blizzard_wave_count = 5},
		2: {slow_chance = 0.35, slow = -0.09, slow_add = -0.0001, slow_duration = 4.5, stun_chance = 0.15, stun_duration = 0.50, blizzard_damage = 333, blizzard_damage_add = 12, blizzard_radius = 300, blizzard_wave_count = 6},
		3: {slow_chance = 0.40, slow = -0.11, slow_add = -0.0001, slow_duration = 5.0, stun_chance = 0.20, stun_duration = 0.75, blizzard_damage = 572, blizzard_damage_add = 25, blizzard_radius = 400, blizzard_wave_count = 7},
		4: {slow_chance = 0.45, slow = -0.14, slow_add = -0.0001, slow_duration = 5.5, stun_chance = 0.25, stun_duration = 1.00, blizzard_damage = 1000, blizzard_damage_add = 50, blizzard_radius = 500, blizzard_wave_count = 8},
	}


func load_specials():
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, -0.5, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.25, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.25, 0.0)
	add_modifier(modifier)


func on_autocast(event: Event):
	var tower: Tower = self

	var u: Unit = event.get_target()
	Troll_blizzard.point_cast_from_caster_on_point(tower, u.position.x, u.position.y, 1.00 + int(tower.get_level()) * 0.1, tower.calc_spell_crit_no_bonus())



func on_blizzard(event: Event, U: DummyUnit):
	if U.get_caster().calc_chance(_stats.slow_chance + int(U.get_caster().get_level()) * 0.01):
		Troll_blizzardslow.apply_only_timed(U.get_caster(), event.get_target(), _stats.slow_duration)
	if U.get_caster().calc_chance(_stats.stun_chance + int(U.get_caster().get_level()) * 0.001):
		cb_stun.apply_only_timed(U.get_caster(), event.get_target(), _stats.stun_duration)


func tower_init():
	var mod2: Modifier = Modifier.new()
	Troll_blizzardslow = BuffType.new("Troll_blizzardslow", 0.0, 0.0, false)
	mod2.add_modification(Modification.Type.MOD_MOVESPEED, _stats.slow, _stats.slow_add)
	Troll_blizzardslow.set_buff_modifier(mod2)
	Troll_blizzard = Cast.new("@@0@@", "blizzard", 9.00)
	Troll_blizzard.set_damage_event(on_blizzard)
	Troll_blizzardslow.set_stacking_group("cedi_troll_blizzard")
	Troll_blizzardslow.set_buff_icon("@@2@@")

	cb_stun = CbStun.new("cb_stun", 0, 0, false)

	var autocast: Autocast = Autocast.make()
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.cast_range = 900
	autocast.target_self = true
	autocast.target_art = ""
	autocast.cooldown = 10
	autocast.is_extended = false
	autocast.mana_cost = 95
	autocast.buff_type = 0
	autocast.target_type = null
	autocast.auto_range = 900
	autocast.handler = on_autocast

	add_autocast(autocast)

	Troll_blizzard.data.blizzard.damage_base = _stats.blizzard_damage
	Troll_blizzard.data.blizzard.damage_add = _stats.blizzard_damage_add
	Troll_blizzard.data.blizzard.radius = _stats.blizzard_radius
	Troll_blizzard.data.blizzard.wave_count = _stats.blizzard_wave_count
