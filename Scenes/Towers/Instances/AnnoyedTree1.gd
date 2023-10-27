extends Tower


var boekie_tree_rock: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 150, damage_add = 5, rock_range = 300},
		2: {damage = 600, damage_add = 20, rock_range = 350},
		3: {damage = 1200, damage_add = 40, rock_range = 400},
		4: {damage = 1950, damage_add = 65, rock_range = 450},
	}


func get_ability_description() -> String:
	var damage: String = Utils.format_float(_stats.damage, 2)
	var damage_add: String = Utils.format_float(_stats.damage_add, 2)
	var rock_range: String = Utils.format_float(_stats.rock_range, 2)

	var text: String = ""

	text += "[color=GOLD]Rock Throw[/color]\n"
	text += "30%% chance to throw a rock towards the attacked unit. On impact it deals %s spell damage in a %s AoE. \n" % [damage, rock_range]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% chance\n"
	text += "+%s damage\n" % damage_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Rock Throw[/color]\n"
	text += "Chance to throw a rock towards the target.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func rock_hit(p: Projectile, _target: Unit):
	var tower: Tower = self
	p.do_spell_damage_pb_aoe(_stats.rock_range, _stats.damage + _stats.damage_add * tower.get_level(), 0)
	var effect: int = Effect.add_special_effect("ImpaleTargetDust.mdl", p.position.x, p.position.y)
	Effect.destroy_effect_after_its_over(effect)


func tower_init():
	boekie_tree_rock = ProjectileType.create_interpolate("RockBoltMissle.mdl", 750, self)
	boekie_tree_rock.set_event_on_interpolation_finished(rock_hit)


func on_attack(event: Event):
	var tower: Tower = self

	if !tower.calc_chance(0.3 + 0.06 * tower.get_level()):
		return

	Projectile.create_linear_interpolation_from_unit_to_unit(boekie_tree_rock, tower, 1.0, tower.calc_spell_crit_no_bonus(), tower, event.get_target(), 0.25, true)
