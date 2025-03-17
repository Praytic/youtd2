extends TowerBehavior


var rocket_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {rocket_damage = 400, rocket_damage_add = 10, aoe_radius = 150},
		2: {rocket_damage = 1200, rocket_damage_add = 30, aoe_radius = 160},
		3: {rocket_damage = 2400, rocket_damage_add = 60, aoe_radius = 170},
		4: {rocket_damage = 4000, rocket_damage_add = 100, aoe_radius = 180},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func rocket_hit(p: Projectile, _t: Unit):
	p.do_spell_damage_pb_aoe(_stats.aoe_radius, _stats.rocket_damage + _stats.rocket_damage_add * tower.get_level(), 0)
	var effect: int = Effect.add_special_effect("res://src/effects/frag_boom_spawn.tscn", Vector2(p.get_x(), p.get_y()))
	Effect.set_scale(effect, 2)


func tower_init():
	rocket_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 750, self)
	rocket_pt.set_event_on_interpolation_finished(rocket_hit)
#	NOTE: -70% from tower specials +95% from this = 125%
#	total damage to mass
	rocket_pt.set_bonus_to_size(CreepSize.enm.MASS, 0.95)


func on_attack(event: Event):
	if !tower.calc_chance(0.30 + 0.006 * tower.get_level()):
		return

	CombatLog.log_ability(tower, event.get_target(), "Rocket Strike")

	Projectile.create_linear_interpolation_from_unit_to_unit(rocket_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), tower, event.get_target(), 0.25, true)
