extends Tower


# NOTE: fixed description of "Morphling Strike". It now
# explicitly states that projectiles will be launched only
# if tower has at least 25 stacks of one of the Morph buffs.


var dave_morph_damage_bt: BuffType
var dave_morph_speed_bt: BuffType
var dave_morph_adapt_bt: BuffType
var dave_morph_dot_bt: BuffType
var dave_morph_slow_bt: BuffType
var damage_pt: ProjectileType
var speed_pt: ProjectileType
var example_multiboard: MultiboardValues
var evolve_count: int = 0


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Evolve[/color]\n"
	text += "Every time it casts Morphling Strike, this tower permanently gains 0.2% base damage and 0.1% attack speed if \"Morph: Might\" has at least 25 stacks, or 0.2% attack speed and 0.1% base damage if \"Morph: Swiftness\" has at least 25 stacks.  Can evolve a maximum of 500 times.\n"
	text += " \n"

	text += "[color=GOLD]Morphling Strike[/color]\n"
	text += "Every time this tower damages a unit, if it has at least 25 stacks of \"Morph: Might\" or \"Morph: Swiftness\", there is a 20% chance to launch 3 projectiles to random creeps in 900 range, dealing 2000 spell damage to them. On impact, if \"Morph: Might\" has at least 25 stacks, the projectiles deal additional spell damage equal to 25% of the tower's damage per second for 5 seconds; if \"Morph: Swiftness\" has at least 25 stacks, they slow the targets by 20% and increase the damage they receive from nature by 15% for 8 seconds. \n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+60 damage\n"
	text += "+0.8% damage per second\n"
	text += "+0.4% slow\n"
	text += "+0.2% damage from nature\n"
	text += "+0.6% chance\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Evolve[/color]\n"
	text += "Every time it casts Morphling Strike, this tower permanently gains power, depending on current Morph stacks.\n"
	text += " \n"

	text += "[color=GOLD]Morphling Strike[/color]\n"
	text += "Every time this tower damages a unit, it has a chance to launch 3 projectiles to random creeps. \n"

	return text


func get_autocast_might_description() -> String:
	var text: String = ""

	text += "Activates \"Morph: Might\". As long as this buff is on this tower gains 2% base damage and loses 2% attack speed on every attack, up to a maximum of 50 times. Removes \"Morph: Swiftness\" and resets its bonus when activated.\n"

	return text


func get_autocast_might_description_short() -> String:
	var text: String = ""

	text += "Activates \"Morph: Might\".\n"

	return text


func get_autocast_swiftness_description() -> String:
	var text: String = ""

	text += "Activates \"Morph: Swiftness\". As long as this buff is on this tower gains 2% attack speed and loses 2% base damage on every attack, up to a maximum of 50 times. Removes \"Morph: Might\" and resets its bonus when activated."

	return text


func get_autocast_swiftness_description_short() -> String:
	var text: String = ""

	text += "Activates \"Morph: Swiftness\".\n"

	return text


func get_autocast_adapt_description() -> String:
	var text: String = ""

	text += "Stops the effect of morphs, leaving the current buff on the tower. Using the spell again removes Adapt.\n"

	return text


func get_autocast_adapt_description_short() -> String:
	var text: String = ""

	text += "Stops the effect of morphs.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func get_ability_ranges() -> Array[Tower.RangeData]:
	return [Tower.RangeData.new("Morphling Strike", 900, TargetType.new(TargetType.CREEPS))]


func tower_init():
	dave_morph_damage_bt = BuffType.new("dave_morph_damage_bt", -1, 0, true, self)
	var dave_morph_damage_bt_mod: Modifier = Modifier.new()
	dave_morph_damage_bt_mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.02)
	dave_morph_damage_bt_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, -0.02)
	dave_morph_damage_bt.set_buff_modifier(dave_morph_damage_bt_mod)
	dave_morph_damage_bt.set_buff_icon("@@1@@")
	dave_morph_damage_bt.set_buff_tooltip("Morph: Might\nIncreases attack damage and reduces attack speed after each attack.")

	dave_morph_speed_bt = BuffType.new("dave_morph_speed_bt", 5, 0, true, self)
	var dave_morph_speed_bt_mod: Modifier = Modifier.new()
	dave_morph_speed_bt_mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, -0.02)
	dave_morph_speed_bt_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.02)
	dave_morph_speed_bt.set_buff_modifier(dave_morph_speed_bt_mod)
	dave_morph_speed_bt.set_buff_icon("@@0@@")
	dave_morph_speed_bt.set_buff_tooltip("Morph: Swiftness\nIncreases attack speed and reduces attack damage after each attack.")

	dave_morph_adapt_bt = BuffType.new("dave_morph_adapt_bt", -1, 0, true, self)
	dave_morph_adapt_bt.set_buff_icon("@@2@@")
	dave_morph_adapt_bt.set_buff_tooltip("Adapt\nGetting read to adapt to new Morph.")

	dave_morph_dot_bt = BuffType.new("dave_morph_dot_bt", 5, 0, false, self)
	dave_morph_dot_bt.set_buff_icon("@@4@@")
	dave_morph_dot_bt.add_periodic_event(dave_morph_dot_bt_periodic, 1.0)
	dave_morph_dot_bt.set_buff_tooltip("Mighty Strike\nDeals damage over time.")

	dave_morph_slow_bt = BuffType.new("dave_morph_slow_bt", 8, 0.1, false, self)
	var dave_morph_slow_bt_mod: Modifier = Modifier.new()
	dave_morph_slow_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.2, -0.004)
	dave_morph_slow_bt_mod.add_modification(Modification.Type.MOD_DMG_FROM_NATURE, 0.15, 0.002)
	dave_morph_slow_bt.set_buff_modifier(dave_morph_slow_bt_mod)
	dave_morph_slow_bt.set_buff_icon("@@3@@")
	dave_morph_slow_bt.set_buff_tooltip("Swift Strike\nIncreases damage taken from Nature towers.")

	damage_pt = ProjectileType.create("SpiritOfVengeanceMissile.mdl", 4, 800, self)
	damage_pt.enable_homing(damage_pt_on_hit, 0)

	speed_pt = ProjectileType.create("ChimaeraAcidMissile.mdl", 4, 800, self)
	speed_pt.enable_homing(speed_pt_on_hit, 0)

	example_multiboard = MultiboardValues.new(2)
	example_multiboard.set_key(0, "Evolve")
	example_multiboard.set_key(1, "Morph level")

	var autocast_might: Autocast = Autocast.make()
	autocast_might.title = "Morph: Might"
	autocast_might.description = get_autocast_might_description()
	autocast_might.description_short = get_autocast_might_description_short()
	autocast_might.icon = "res://path/to/icon.png"
	autocast_might.caster_art = ""
	autocast_might.target_art = ""
	autocast_might.autocast_type = Autocast.Type.AC_TYPE_NOAC_IMMEDIATE
	autocast_might.num_buffs_before_idle = 1
	autocast_might.cast_range = 0
	autocast_might.auto_range = 0
	autocast_might.cooldown = 1
	autocast_might.mana_cost = 0
	autocast_might.target_self = true
	autocast_might.is_extended = false
	autocast_might.buff_type = dave_morph_damage_bt
	autocast_might.target_type = TargetType.new(TargetType.TOWERS)
	autocast_might.handler = on_autocast_might
	add_autocast(autocast_might)

	var autocast_swiftness: Autocast = Autocast.make()
	autocast_swiftness.title = "Morph: Swiftness"
	autocast_swiftness.description = get_autocast_swiftness_description()
	autocast_swiftness.description_short = get_autocast_swiftness_description_short()
	autocast_swiftness.icon = "res://path/to/icon.png"
	autocast_swiftness.caster_art = ""
	autocast_swiftness.target_art = ""
	autocast_swiftness.autocast_type = Autocast.Type.AC_TYPE_NOAC_IMMEDIATE
	autocast_swiftness.num_buffs_before_idle = 1
	autocast_swiftness.cast_range = 0
	autocast_swiftness.auto_range = 0
	autocast_swiftness.cooldown = 1
	autocast_swiftness.mana_cost = 0
	autocast_swiftness.target_self = true
	autocast_swiftness.is_extended = false
	autocast_swiftness.buff_type = dave_morph_speed_bt
	autocast_swiftness.target_type = TargetType.new(TargetType.TOWERS)
	autocast_swiftness.handler = on_autocast_swiftness
	add_autocast(autocast_swiftness)

	var autocast_adapt: Autocast = Autocast.make()
	autocast_adapt.title = "Adapt"
	autocast_adapt.description = get_autocast_adapt_description()
	autocast_adapt.description_short = get_autocast_adapt_description_short()
	autocast_adapt.icon = "res://path/to/icon.png"
	autocast_adapt.caster_art = ""
	autocast_adapt.target_art = ""
	autocast_adapt.autocast_type = Autocast.Type.AC_TYPE_NOAC_IMMEDIATE
	autocast_adapt.num_buffs_before_idle = 0
	autocast_adapt.cast_range = 0
	autocast_adapt.auto_range = 0
	autocast_adapt.cooldown = 1
	autocast_adapt.mana_cost = 0
	autocast_adapt.target_self = true
	autocast_adapt.is_extended = false
	autocast_adapt.buff_type = dave_morph_adapt_bt
	autocast_adapt.target_type = TargetType.new(TargetType.TOWERS)
	autocast_adapt.handler = on_autocast_adapt
	add_autocast(autocast_adapt)


func on_attack(_event: Event):
	var tower: Tower = self
	var damage_buff: Buff = tower.get_buff_of_type(dave_morph_damage_bt)
	var speed_buff: Buff = tower.get_buff_of_type(dave_morph_speed_bt)
	var adapt_buff: Buff = tower.get_buff_of_type(dave_morph_adapt_bt)

	if adapt_buff == null:
		if damage_buff != null && damage_buff.get_level() < 50:
			dave_morph_damage_bt.apply(tower, tower, damage_buff.get_level() + 1)
		elif speed_buff != null && speed_buff.get_level() < 50:
			dave_morph_speed_bt.apply(tower, tower, speed_buff.get_level() + 1)


func on_damage(event: Event):
	var tower: Tower = self
	var morphling_strike_chance: float = 0.2 + 0.006 * tower.get_level()

	if !tower.calc_chance(morphling_strike_chance):
		return

	var pt: ProjectileType = null
	var projectile_scale: float = 1.0

	var damage_buff: Buff = tower.get_buff_of_type(dave_morph_damage_bt)
	var speed_buff: Buff = tower.get_buff_of_type(dave_morph_speed_bt)

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
		CombatLog.log_ability(self, event.get_target(), "Morphling Strike")
		
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
			p.setScale(projectile_scale)


func on_autocast_might(_event: Event):
	var tower: Tower = self
	var speed_buff: Buff = tower.get_buff_of_type(dave_morph_speed_bt)
	var damage_buff: Buff = tower.get_buff_of_type(dave_morph_damage_bt)

	if damage_buff == null:
		if speed_buff != null:
			speed_buff.remove_buff()

		dave_morph_damage_bt.apply(tower, tower, 0)


func on_autocast_swiftness(_event: Event):
	var tower: Tower = self
	var speed_buff: Buff = tower.get_buff_of_type(dave_morph_speed_bt)
	var damage_buff: Buff = tower.get_buff_of_type(dave_morph_damage_bt)

	if speed_buff == null:
		if damage_buff != null:
			damage_buff.remove_buff()

		dave_morph_speed_bt.apply(tower, tower, 0)


func on_autocast_adapt(_event: Event):
	var tower: Tower = self
	var adapt_buff: Buff = tower.get_buff_of_type(dave_morph_adapt_bt)

	if adapt_buff == null:
		dave_morph_adapt_bt.apply(tower, tower, 0)
	elif adapt_buff != null:
		adapt_buff.remove_buff()


func on_tower_details() -> MultiboardValues:
	var tower: Tower = self
	var damage_buff: Buff = tower.get_buff_of_type(dave_morph_damage_bt)
	var speed_buff: Buff = tower.get_buff_of_type(dave_morph_speed_bt)

	example_multiboard.set_value(0, str(evolve_count))
	
	var damage_buff_level: int = 0
	if damage_buff != null:
		damage_buff_level = damage_buff.get_level()
		example_multiboard.set_value(1, str(damage_buff_level))

	var speed_buff_level: int = 0
	if speed_buff != null:
		speed_buff_level = speed_buff.get_level()
		example_multiboard.set_value(1, str(speed_buff_level))

	return example_multiboard


# NOTE: "morphSpeedHit()" in original script
func speed_pt_on_hit(_p: Projectile, target: Unit):
	if target == null:
		return

	var tower: Tower = self
	var level: int = tower.get_level()
	var damage: float = 2000 + 60 * level

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())
	dave_morph_slow_bt.apply(tower, target, level)


# NOTE: "morphDamageHit()" in original script
func damage_pt_on_hit(_p: Projectile, target: Unit):
	if target == null:
		return

	var tower: Tower = self
	var level: int = tower.get_level()
	var damage: float = 2000 + 60 * level

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())
	dave_morph_dot_bt.apply(tower, target, level)


# NOTE: "dot()" in original script
func dave_morph_dot_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var tower: Tower = self
	var buffed_unit: Unit = buff.get_buffed_unit()
	var level: int = tower.get_level()
	var damage: float = tower.get_current_attack_damage_with_bonus() * (0.25 + 0.008 * level)
	tower.do_spell_damage(buffed_unit, damage, tower.calc_spell_crit_no_bonus())
