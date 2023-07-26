extends Tower


var boekie_tree_rock: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 1.5, damage_add = 0.05, rock_range = 300},
		2: {damage = 6.0, damage_add = 0.20, rock_range = 350},
		3: {damage = 12.0, damage_add = 0.40, rock_range = 400},
		4: {damage = 19.5, damage_add = 0.65, rock_range = 450},
	}


func get_extra_tooltip_text() -> String:
	var damage: String = str(_stats.damage * 100)
	var damage_add: String = str(_stats.damage_add * 100)
	var rock_range: String = str(_stats.rock_range)

	var text: String = ""

	text += "[color=GOLD]Rock Throw[/color]\n"
	text += "30%% chance to throw a rock towards the attacked unit. On impact it deals %s spell damage in a %s AoE. \n" % [damage, rock_range]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6%% chance\n"
	text += "+%s damage\n" % damage_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func rock_hit(p: Projectile, _target: Unit):
	p.do_spell_damage_pb_aoe(p.user_real, 100, 0)
	var effect: int = Effect.add_special("ImpaleTargetDust.mdl", p.position.x, p.position.y)
	Effect.destroy_effect(effect)


func tower_init():
	boekie_tree_rock = ProjectileType.create_interpolate("RockBoltMissle.mdl", 750)
	boekie_tree_rock.set_event_on_interpolation_finished(rock_hit)


func on_attack(event: Event):
	var tower: Tower = self

	if !tower.calc_chance(0.3 + 0.06 * tower.get_level()):
		return

	Projectile.create_linear_interpolation_from_unit_to_unit(boekie_tree_rock, tower, _stats.damage + tower.get_level() * _stats.damage_add, tower.calc_spell_crit_no_bonus(), tower, event.get_target(), 0.25, true).user_real = _stats.rock_range
