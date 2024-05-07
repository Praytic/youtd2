extends TowerBehavior


var rocket_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {rocket_damage = 400, rocket_damage_add = 10, aoe_radius = 150},
		2: {rocket_damage = 1200, rocket_damage_add = 30, aoe_radius = 160},
		3: {rocket_damage = 2400, rocket_damage_add = 60, aoe_radius = 170},
		4: {rocket_damage = 4000, rocket_damage_add = 100, aoe_radius = 180},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var rocket_damage: String = Utils.format_float(_stats.rocket_damage, 2)
	var rocket_damage_add: String = Utils.format_float(_stats.rocket_damage_add, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Rocket Strike"
	ability.icon = "res://Resources/Textures/ItemIcons/1_unused_bullet.tres"
	ability.description_short = "Has a chance to deal splash damage when attacking.\n"
	ability.description_full = "30%% chance to fire a rocket towards the attacked unit. On impact it deals %s damage in a 150 AoE. Deals 125%% damage to mass creeps.\n" % rocket_damage \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.6% chance\n" \
	+ "+%s damage\n" % rocket_damage_add
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, -0.70, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NORMAL, -0.30, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_CHAMPION, 0.20, 0.016)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_BOSS, 0.50, 0.04)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.20, 0.016)


func rocket_hit(p: Projectile, _t: Unit):
	p.do_spell_damage_pb_aoe(_stats.aoe_radius, _stats.rocket_damage + _stats.rocket_damage_add * tower.get_level(), 0)
	var effect: int = Effect.add_special_effect("NeutralBuildingExplosion.mdl", Vector2(p.get_x(), p.get_y()))
	Effect.destroy_effect_after_its_over(effect)


func tower_init():
	rocket_pt = ProjectileType.create_interpolate("RocketMissile.mdl", 750, self)
	rocket_pt.set_event_on_interpolation_finished(rocket_hit)
#	NOTE: -70% from tower specials +95% from this = 125%
#	total damage to mass
	rocket_pt.set_bonus_to_size(CreepSize.enm.MASS, 0.95)


func on_attack(event: Event):
	if !tower.calc_chance(0.30 + 0.006 * tower.get_level()):
		return

	CombatLog.log_ability(tower, event.get_target(), "Rocket Strike")

	Projectile.create_linear_interpolation_from_unit_to_unit(rocket_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), tower, event.get_target(), 0.25, true)
