extends Tower


var limfa_teacherboard: MultiboardValues
var knowledge_green: ProjectileType
var knowledge_blue: ProjectileType
var knowledge_red: ProjectileType


func _get_tier_stats() -> Dictionary:
	return {
		1: {exp_received = 0.20, exp_teach = 1.0},
		2: {exp_received = 0.35, exp_teach = 1.3},
		3: {exp_received = 0.45, exp_teach = 1.5},
		4: {exp_received = 0.60, exp_teach = 1.8},
		5: {exp_received = 0.70, exp_teach = 2.0},
		6: {exp_received = 0.80, exp_teach = 2.2},
	}


func hit(p: Projectile, result: Unit):
	var t: Tower = p.get_caster()

	if result.get_uid() == p.user_int:
		result.add_exp(p.user_real)

		if p.user_int2 == t.get_uid():
			t.user_real2 = t.user_real2 + p.user_real * result.get_prop_exp_received()


func teacher_attack(tower: Tower, xp: float):
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
			i = randi_range(1, 3)

			if i == 1:
				pt = knowledge_green
			elif i == 2:
				pt = knowledge_red
			elif i == 3:
				pt = knowledge_blue

			p = Projectile.create_from_unit_to_unit(pt, tower, 1.0, 1.0, tower, result, true, false, true)
			p.setScale(0.7)
			p.user_real = xp
			p.user_int = result.get_uid()
			p.user_int2 = tower.get_uid()

			in_range.destroy()


func _load_triggers(triggers_buff: Buff):
	triggers_buff.add_event_on_attack(self, "on_attack", 1.0, 0.0)


func _tower_init():
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, _stats.exp_gain, 0)
	add_modifier(specials_modifier)

	limfa_teacherboard = MultiboardValues.new(1)
	limfa_teacherboard.set_key(0, "Xp Granted")

	knowledge_green = ProjectileType.create("Objects\\InventoryItems\\tomeGreen\\tomeGreen.mdl", 20.0, 450.00) 
	knowledge_green.enable_free_rotation()
	knowledge_green.disable_explode_on_hit()
	knowledge_green.enable_homing(hit, 0)
	knowledge_blue = ProjectileType.create("Objects\\InventoryItems\\tomeBlue\\tomeBlue.mdl", 20.0, 450.00) 
	knowledge_blue.enable_free_rotation()
	knowledge_blue.disable_explode_on_hit()
	knowledge_blue.enable_homing(hit, 0)
	knowledge_red = ProjectileType.create("Objects\\InventoryItems\\tomeRed\\tomeRed.mdl", 20.0, 450.00) 
	knowledge_red.enable_free_rotation()
	knowledge_red.disable_explode_on_hit()
	knowledge_red.enable_homing(hit, 0)

#	TODO: implement event.get_preceding_tower(). Supposed to
#	be tower from previous tier when tower is upgraded.
	# var preceding: Tower = event.get_preceding_tower()
	var tower: Tower = self
	var preceding: Tower = null

	if preceding != null && preceding.get_family() == tower.get_family():
		tower.user_real2 = preceding.user_real2
	else:
		tower.user_real2 = 0


func on_attack(_event: Event):
	var tower: Tower = self

	teacher_attack(tower, _stats.exp_teach)
	set_animation_by_index(tower, 3)


func on_tower_details() -> MultiboardValues:
	var tower = self

	limfa_teacherboard.set_value(0, Utils.format_float(tower.user_real_2, 1))
	return limfa_teacherboard
