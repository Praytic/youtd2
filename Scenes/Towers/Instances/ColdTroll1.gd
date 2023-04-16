extends Tower


var Troll_blizzardslow: BuffType
var Troll_blizzard: Cast
var cb_stun: BuffType


func _get_tier_stats() -> Dictionary:
	return {
		1: {slow_chance = 0.30, slow = -0.07, slow_add = -0.001, slow_duration = 4.0, stun_chance = 0.10, stun_duration = 0.25, blizzard_damage = 60, blizzard_radius = 200, blizzard_wave_count = 5, damage_ratio_add = 0.1},
		2: {slow_chance = 0.35, slow = -0.09, slow_add = -0.0001, slow_duration = 4.5, stun_chance = 0.15, stun_duration = 0.50, blizzard_damage = 333, blizzard_radius = 300, blizzard_wave_count = 6, damage_ratio_add = 0.036},
		3: {slow_chance = 0.40, slow = -0.11, slow_add = -0.0001, slow_duration = 5.0, stun_chance = 0.20, stun_duration = 0.75, blizzard_damage = 572, blizzard_radius = 400, blizzard_wave_count = 7, damage_ratio_add = 0.033},
		4: {slow_chance = 0.45, slow = -0.14, slow_add = -0.0001, slow_duration = 5.5, stun_chance = 0.25, stun_duration = 1.00, blizzard_damage = 1000, blizzard_radius = 500, blizzard_wave_count = 8, damage_ratio_add = 0.05},
	}


func get_extra_tooltip_text() -> String:
	var blizzard_wave_count: String = String.num(_stats.blizzard_wave_count, 2)
	var blizzard_damage: String = String.num(_stats.blizzard_damage, 2)
	var blizzard_radius: String = String.num(_stats.blizzard_radius, 2)
	var slow_chance: String = String.num(_stats.slow_chance * 100, 2)
	var slow: String = String.num(_stats.slow * -1 * 100, 2)
	var slow_duration: String = String.num(_stats.slow_duration, 2)
	var stun_chance: String = String.num(_stats.stun_chance * 100, 2)
	var stun_duration: String = String.num(_stats.stun_duration, 2)
	var blizzard_damage_add: String = String.num(round(_stats.blizzard_damage * _stats.damage_ratio_add), 2)
	var slow_add: String = String.num(_stats.slow_add * -1 * 100, 2)

	return "[color=gold]Blizzard[/color]\nSummons %s waves of icy spikes which fall down to earth. Each wave deals %s damage in an AoE of %s. Each time a unit is damaged by this spell there is a chance of %s%% to slow the unit by %s%% for %s seconds and a chance of %s%% to stun the unit for %s seconds.\n[color=orange]Level Bonus:[/color]\n+%s damage\n+%s%% slow\n+1%% chance for slow\n+0.1%% chance for stun\n\nMana cost: 95, 900 range, 10s cooldown" % [blizzard_wave_count, blizzard_damage, blizzard_radius, slow_chance, slow, slow_duration, stun_chance, stun_duration, blizzard_damage_add, slow_add]


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, -0.5, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.25, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.25, 0.0)


func on_autocast(event: Event):
	var tower: Tower = self

	var u: Unit = event.get_target()
	Troll_blizzard.point_cast_from_caster_on_point(tower, u.position.x, u.position.y, 1.00 + int(tower.get_level()) * _stats.damage_ratio_add, tower.calc_spell_crit_no_bonus())



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

	Troll_blizzard.data.blizzard.damage = _stats.blizzard_damage
	Troll_blizzard.data.blizzard.radius = _stats.blizzard_radius
	Troll_blizzard.data.blizzard.wave_count = _stats.blizzard_wave_count
