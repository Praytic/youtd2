extends Tower


var limfa_teacherboard: MultiboardValues
var knowledge_green: ProjectileType
var knowledge_blue: ProjectileType
var knowledge_red: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {exp_received = 0.20, exp_teach = 1.0},
		2: {exp_received = 0.35, exp_teach = 1.3},
		3: {exp_received = 0.45, exp_teach = 1.5},
		4: {exp_received = 0.60, exp_teach = 1.8},
		5: {exp_received = 0.70, exp_teach = 2.0},
		6: {exp_received = 0.80, exp_teach = 2.2},
	}


func get_extra_tooltip_text() -> String:
	var exp_teach: String = Utils.format_float(_stats.exp_teach, 2)

	var text: String = ""

	text += "[color=GOLD]Knowledge[/color]\n"
	text += "When the teacher attacks there's a 10%% chance a random tower in 600 range will learn from her, gaining %s experience. \n" % exp_teach
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% chance"

	return text


func hit(p: Projectile, result: Unit):
	var t: Tower = p.get_caster()

	if result.get_instance_id() == p.user_int:
		result.add_exp(p.user_real)

		if p.user_int2 == t.get_instance_id():
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
			p.user_int = result.get_instance_id()
			p.user_int2 = tower.get_instance_id()


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, _stats.exp_received, 0)


func tower_init():
	limfa_teacherboard = MultiboardValues.new(1)
	limfa_teacherboard.set_key(0, "Xp Granted")

	knowledge_green = ProjectileType.create("Objects\\InventoryItems\\tomeGreen\\tomeGreen.mdl", 20.0, 450.00, self)
	knowledge_green.disable_explode_on_hit()
	knowledge_green.enable_homing(hit, 0)
	knowledge_blue = ProjectileType.create("Objects\\InventoryItems\\tomeBlue\\tomeBlue.mdl", 20.0, 450.00, self)
	knowledge_blue.disable_explode_on_hit()
	knowledge_blue.enable_homing(hit, 0)
	knowledge_red = ProjectileType.create("Objects\\InventoryItems\\tomeRed\\tomeRed.mdl", 20.0, 450.00, self)
	knowledge_red.disable_explode_on_hit()
	knowledge_red.enable_homing(hit, 0)


func on_attack(_event: Event):
	var tower: Tower = self

	teacher_attack(tower, _stats.exp_teach)
	set_animation_by_index(tower, 3)


func on_create(preceding_tower: Tower):
	var preceding: Tower = preceding_tower
	var tower: Tower = self

	if preceding != null && preceding.get_family() == tower.get_family():
		tower.user_real2 = preceding.user_real2
	else:
		tower.user_real2 = 0


func on_tower_details() -> MultiboardValues:
	var tower = self

	limfa_teacherboard.set_value(0, Utils.format_float(tower.user_real2, 1))
	return limfa_teacherboard
