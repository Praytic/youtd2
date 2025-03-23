extends TowerBehavior


var multiboard: MultiboardValues
var green_pt: ProjectileType
var blue_pt: ProjectileType
var red_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {exp_teach = 1.0},
		2: {exp_teach = 1.3},
		3: {exp_teach = 1.5},
		4: {exp_teach = 1.8},
		5: {exp_teach = 2.0},
		6: {exp_teach = 2.2},
	}


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


func tower_init():
	multiboard = MultiboardValues.new(1)
	var xp_granted_label: String = tr("WXGT")
	multiboard.set_key(0, xp_granted_label)

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
