extends Tower


var cedi_sniper_rocket: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {rocket_damage = 400, rocket_damage_add = 10, aoe_radius = 150},
		2: {rocket_damage = 1200, rocket_damage_add = 30, aoe_radius = 160},
		3: {rocket_damage = 2400, rocket_damage_add = 60, aoe_radius = 170},
		4: {rocket_damage = 4000, rocket_damage_add = 100, aoe_radius = 180},
	}


func get_extra_tooltip_text() -> String:
	var rocket_damage: String = Utils.format_float(_stats.rocket_damage, 2)
	var rocket_damage_add: String = Utils.format_float(_stats.rocket_damage_add, 2)
	var text: String = ""

	text += "[color=GOLD]Rocket Strike[/color]\n"
	text += "30%% chance to fire a rocket towards the attacked unit. On impact it deals %s damage in a 150 AoE. Deals 125%% damage to mass creeps.\n" % rocket_damage
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% chance\n"
	text += "+%s damage\n" % rocket_damage_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, -0.70, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NORMAL, -0.30, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_CHAMPION, 0.20, 0.016)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_BOSS, 0.50, 0.04)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.20, 0.016)


func rocket_hit(p: Projectile, _t: Unit):
	var tower: Tower = self
	p.do_spell_damage_pb_aoe(_stats.aoe_radius, _stats.rocket_damage + _stats.rocket_damage_add * tower.get_level(), 0)
	var effect: int = Effect.add_special_effect("NeutralBuildingExplosion.mdl", p.position.x, p.position.y)
	Effect.destroy_effect_after_its_over(effect)


func tower_init():
	cedi_sniper_rocket = ProjectileType.create_interpolate("RocketMissile.mdl", 750)
	cedi_sniper_rocket.set_event_on_interpolation_finished(rocket_hit)
#	NOTE: -70% from tower specials +95% from this = 125%
#	total damage to mass
	cedi_sniper_rocket.set_bonus_to_size(CreepSize.enm.MASS, 0.95)


func on_attack(event: Event):
	var tower: Tower = self

	if !tower.calc_chance(0.30 + 0.006 * tower.get_level()):
		return

	Projectile.create_linear_interpolation_from_unit_to_unit(cedi_sniper_rocket, tower, 1.0, tower.calc_spell_crit_no_bonus(), tower, event.get_target(), 0.25, true)
