extends TowerBehavior


var rock_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 150, damage_add = 5, rock_range = 300},
		2: {damage = 600, damage_add = 20, rock_range = 350},
		3: {damage = 1200, damage_add = 40, rock_range = 400},
		4: {damage = 1950, damage_add = 65, rock_range = 450},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []

	var damage: String = Utils.format_float(_stats.damage, 2)
	var damage_add: String = Utils.format_float(_stats.damage_add, 2)
	var rock_range: String = Utils.format_float(_stats.rock_range, 2)
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Rock Throw"
	ability.icon = "res://resources/icons/tower_variations/MossyAcidSprayer_gray.tres"
	ability.description_short = "Whenever this tower attacks, it has a chance to throw a rock towards the target. On impact, the rock deals AoE spell damage.\n"
	ability.description_full = "Whenever this tower attacks, it has a 30%% chance to throw a rock towards the target. On impact the rock deals %s spell damage in a %s AoE.\n" % [damage, rock_range] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.6% chance\n" \
	+ "+%s damage\n" % damage_add

	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func rock_hit(p: Projectile, _target: Unit):
	p.do_spell_damage_pb_aoe(_stats.rock_range, _stats.damage + _stats.damage_add * tower.get_level(), 0)
	var effect: int = Effect.add_special_effect("ImpaleTargetDust.mdl", Vector2(p.get_x(), p.get_y()))
	Effect.destroy_effect_after_its_over(effect)


func tower_init():
	rock_pt = ProjectileType.create_interpolate("RockBoltMissle.mdl", 750, self)
	rock_pt.set_event_on_interpolation_finished(rock_hit)


func on_attack(event: Event):
	if !tower.calc_chance(0.3 + 0.06 * tower.get_level()):
		return

	CombatLog.log_ability(tower, event.get_target(), "Rock Thorw")

	Projectile.create_linear_interpolation_from_unit_to_unit(rock_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), tower, event.get_target(), 0.25, true)
