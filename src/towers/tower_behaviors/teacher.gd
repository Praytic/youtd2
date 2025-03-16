extends TowerBehavior


var multiboard: MultiboardValues
var green_pt: ProjectileType
var blue_pt: ProjectileType
var red_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {exp_received = 0.20, exp_teach = 1.0},
		2: {exp_received = 0.35, exp_teach = 1.3},
		3: {exp_received = 0.45, exp_teach = 1.5},
		4: {exp_received = 0.60, exp_teach = 1.8},
		5: {exp_received = 0.70, exp_teach = 2.0},
		6: {exp_received = 0.80, exp_teach = 2.2},
	}


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var exp_teach: String = Utils.format_float(_stats.exp_teach, 2)
	
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Knowledge"
	ability.icon = "res://resources/icons/dioramas/pyramid.tres"
	ability.description_short = "Whenever this tower attacks, it has a chance to grant experience to a random nearby tower.\n"
	ability.description_full = "Whenever this tower attacks, it has a 10%% chance to grant %s experience to a random tower in 600 range\n" % exp_teach \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.6% chance"
	ability.radius = 600
	ability.target_type = TargetType.new(TargetType.TOWERS)
	list.append(ability)

	return list


func hit(p: Projectile, result: Unit):
	if result == null:
		return

	var t: Tower = p.get_caster()

	if result.get_instance_id() == p.user_int:
		result.add_exp(p.user_real)

		if p.user_int2 == t.get_instance_id():
			t.user_real2 = t.user_real2 + p.user_real * result.get_prop_exp_received()


func teacher_attack(xp: float):
	var in_range: Iterate
	var result: Unit
	var pt: ProjectileType
	var p: Projectile
	var i: int

	if tower.calc_chance(0.10 + 0.006 * tower.get_level()):
		in_range = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 600)

		result = in_range.next_random()

		if result == tower:
			result = in_range.next_random()

		if result != null:
			i = Globals.synced_rng.randi_range(1, 3)

			if i == 1:
				pt = green_pt
			elif i == 2:
				pt = red_pt
			elif i == 3:
				pt = blue_pt

			CombatLog.log_ability(tower, result, "Knowledge")

			p = Projectile.create_from_unit_to_unit(pt, tower, 1.0, 1.0, tower, result, true, false, true)
			p.set_projectile_scale(0.7)
			p.user_real = xp
			p.user_int = result.get_instance_id()
			p.user_int2 = tower.get_instance_id()


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, _stats.exp_received, 0)


func tower_init():
	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Xp Granted")

	green_pt = ProjectileType.create("path_to_projectile_sprite", 20.0, 450.00, self)
	green_pt.disable_explode_on_hit()
	green_pt.enable_homing(hit, 0)
	blue_pt = ProjectileType.create("path_to_projectile_sprite", 20.0, 450.00, self)
	blue_pt.disable_explode_on_hit()
	blue_pt.enable_homing(hit, 0)
	red_pt = ProjectileType.create("path_to_projectile_sprite", 20.0, 450.00, self)
	red_pt.disable_explode_on_hit()
	red_pt.enable_homing(hit, 0)


func on_attack(_event: Event):
	teacher_attack(_stats.exp_teach)
	tower.set_animation_by_index(tower, 3)


func on_create(preceding_tower: Tower):
	var preceding: Tower = preceding_tower

	if preceding != null && preceding.get_family() == tower.get_family():
		tower.user_real2 = preceding.user_real2
	else:
		tower.user_real2 = 0


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, Utils.format_float(tower.user_real2, 1))
	return multiboard
