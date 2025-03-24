extends TowerBehavior


# NOTE: fixed description of "Morphling Strike". It now
# explicitly states that projectiles will be launched only
# if tower has at least 25 stacks of one of the Morph buffs.


var might_bt: BuffType
var swiftness_bt: BuffType
var adapt_bt: BuffType
var dot_bt: BuffType
var swift_strike_bt: BuffType
var damage_pt: ProjectileType
var speed_pt: ProjectileType
var multiboard: MultiboardValues
var evolve_count: int = 0


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	might_bt = BuffType.new("might_bt", -1, 0, true, self)
	var might_bt_mod: Modifier = Modifier.new()
	might_bt_mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.02)
	might_bt_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, -0.02)
	might_bt.set_buff_modifier(might_bt_mod)
	might_bt.set_buff_icon("res://resources/icons/generic_icons/biceps.tres")
	might_bt.set_buff_tooltip(tr("MUTT"))

	swiftness_bt = BuffType.new("swiftness_bt", -1, 0, true, self)
	var swiftness_bt_mod: Modifier = Modifier.new()
	swiftness_bt_mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, -0.02)
	swiftness_bt_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.02)
	swiftness_bt.set_buff_modifier(swiftness_bt_mod)
	swiftness_bt.set_buff_icon("res://resources/icons/generic_icons/sprint.tres")
	swiftness_bt.set_buff_tooltip(tr("STJ0"))

	adapt_bt = BuffType.new("adapt_bt", -1, 0, true, self)
	adapt_bt.set_buff_icon("res://resources/icons/generic_icons/atomic_slashes.tres")
	adapt_bt.set_buff_tooltip(tr("K488"))

	dot_bt = BuffType.new("dot_bt", 5, 0, false, self)
	dot_bt.set_buff_icon("res://resources/icons/generic_icons/triple_scratches.tres")
	dot_bt.add_periodic_event(dot_bt_periodic, 1.0)
	dot_bt.set_buff_tooltip(tr("LWRJ"))

	swift_strike_bt = BuffType.new("swift_strike_bt", 8, 0.1, false, self)
	var swift_strike_bt_mod: Modifier = Modifier.new()
	swift_strike_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.2, -0.004)
	swift_strike_bt_mod.add_modification(Modification.Type.MOD_DMG_FROM_NATURE, 0.15, 0.002)
	swift_strike_bt.set_buff_modifier(swift_strike_bt_mod)
	swift_strike_bt.set_buff_icon("res://resources/icons/generic_icons/amber_mosquito.tres")
	swift_strike_bt.set_buff_tooltip(tr("AZW0"))

	damage_pt = ProjectileType.create("path_to_projectile_sprite", 4, 800, self)
	damage_pt.enable_homing(damage_pt_on_hit, 0)

	speed_pt = ProjectileType.create("path_to_projectile_sprite", 4, 800, self)
	speed_pt.enable_homing(speed_pt_on_hit, 0)

	multiboard = MultiboardValues.new(2)
	var evolve_label: String = tr("R92N")
	var morph_level_label: String = tr("V3M2")
	multiboard.set_key(0, evolve_label)
	multiboard.set_key(1, morph_level_label)


func on_attack(_event: Event):
	var damage_buff: Buff = tower.get_buff_of_type(might_bt)
	var speed_buff: Buff = tower.get_buff_of_type(swiftness_bt)
	var adapt_buff: Buff = tower.get_buff_of_type(adapt_bt)

	if adapt_buff == null:
		if damage_buff != null && damage_buff.get_level() < 50:
			var might_buff: Buff = might_bt.apply(tower, tower, damage_buff.get_level() + 1)
			might_buff.set_displayed_stacks(might_buff.get_level())
		elif speed_buff != null && speed_buff.get_level() < 50:
			var swiftness_buff: Buff = swiftness_bt.apply(tower, tower, speed_buff.get_level() + 1)
			swiftness_buff.set_displayed_stacks(swiftness_buff.get_level())


func on_damage(event: Event):
	var morphling_strike_chance: float = 0.2 + 0.006 * tower.get_level()

	if !tower.calc_chance(morphling_strike_chance):
		return

	var pt: ProjectileType = null
	var projectile_scale: float = 1.0

	var damage_buff: Buff = tower.get_buff_of_type(might_bt)
	var speed_buff: Buff = tower.get_buff_of_type(swiftness_bt)

	if damage_buff != null && damage_buff.get_level() >= 25:
		pt = damage_pt
		projectile_scale = 1.6

		if evolve_count < 500:
			tower.modify_property(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.002)
			tower.modify_property(Modification.Type.MOD_ATTACKSPEED, 0.001)
			evolve_count += 1
	elif speed_buff != null && speed_buff.get_level() >= 25:
		pt = speed_pt

		if evolve_count < 500:
			tower.modify_property(Modification.Type.MOD_ATTACKSPEED, 0.002)
			tower.modify_property(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.001)
			evolve_count += 1

	if pt != null:
		CombatLog.log_ability(tower, event.get_target(), "Morphling Strike")
		
		var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 900)

		var count: int = 0

		while true:
			var next: Unit = it.next()

			if next == null:
				break

			count += 1

			if count == 4:
				break

			var p: Projectile = Projectile.create_from_unit_to_unit(pt, tower, 1, 1, tower, next, true, false, false)
			p.set_projectile_scale(projectile_scale)


func on_autocast_might(_event: Event):
	var speed_buff: Buff = tower.get_buff_of_type(swiftness_bt)
	var damage_buff: Buff = tower.get_buff_of_type(might_bt)

	if damage_buff == null:
		if speed_buff != null:
			speed_buff.remove_buff()

		might_bt.apply(tower, tower, 0)


func on_autocast_swiftness(_event: Event):
	var speed_buff: Buff = tower.get_buff_of_type(swiftness_bt)
	var damage_buff: Buff = tower.get_buff_of_type(might_bt)

	if speed_buff == null:
		if damage_buff != null:
			damage_buff.remove_buff()

		swiftness_bt.apply(tower, tower, 0)


func on_autocast_adapt(_event: Event):
	var adapt_buff: Buff = tower.get_buff_of_type(adapt_bt)

	if adapt_buff == null:
		adapt_bt.apply(tower, tower, 0)
	elif adapt_buff != null:
		adapt_buff.remove_buff()


func on_tower_details() -> MultiboardValues:
	var damage_buff: Buff = tower.get_buff_of_type(might_bt)
	var speed_buff: Buff = tower.get_buff_of_type(swiftness_bt)

	multiboard.set_value(0, str(evolve_count))
	
	var damage_buff_level: int = 0
	if damage_buff != null:
		damage_buff_level = damage_buff.get_level()
		multiboard.set_value(1, str(damage_buff_level))

	var speed_buff_level: int = 0
	if speed_buff != null:
		speed_buff_level = speed_buff.get_level()
		multiboard.set_value(1, str(speed_buff_level))

	return multiboard


# NOTE: "morphSpeedHit()" in original script
func speed_pt_on_hit(_p: Projectile, target: Unit):
	if target == null:
		return

	var level: int = tower.get_level()
	var damage: float = 2000 + 60 * level

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())
	swift_strike_bt.apply(tower, target, level)


# NOTE: "morphDamageHit()" in original script
func damage_pt_on_hit(_p: Projectile, target: Unit):
	if target == null:
		return

	var level: int = tower.get_level()
	var damage: float = 2000 + 60 * level

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())
	dot_bt.apply(tower, target, level)


# NOTE: "dot()" in original script
func dot_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var level: int = tower.get_level()
	var damage: float = tower.get_current_attack_damage_with_bonus() * (0.25 + 0.008 * level)
	tower.do_spell_damage(buffed_unit, damage, tower.calc_spell_crit_no_bonus())
