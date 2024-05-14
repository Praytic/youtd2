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


func get_ability_info_list() -> Array[AbilityInfo]:
	var nature_string: String = Element.convert_to_colored_string(Element.enm.NATURE)

	var list: Array[AbilityInfo] = []
	
	var morphling_strike: AbilityInfo = AbilityInfo.new()
	morphling_strike.name = "Morphling Strike"
	morphling_strike.icon = "res://Resources/Icons/misc/poison_01.tres"
	morphling_strike.description_short = "Every time this tower damages a unit, it has a chance to launch 3 projectiles to random creeps.\n"
	morphling_strike.description_full = "Every time this tower damages a unit, if it has at least 25 stacks of [color=GOLD]Morph: Might[/color] or [color=GOLD]Morph: Swiftness[/color], there is a 20%% chance to launch 3 projectiles to random creeps in 900 range, dealing 2000 spell damage to them. On impact, if [color=GOLD]Morph: Might[/color] has at least 25 stacks, the projectiles deal additional spell damage equal to 25%% of the tower's damage per second for 5 seconds; if [color=GOLD]Morph: Swiftness[/color] has at least 25 stacks, they slow the targets by 20%% and increase the damage they receive from %s by 15%% for 8 seconds.\n" % nature_string \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+60 damage\n" \
	+ "+0.8% damage per second\n" \
	+ "+0.4% slow\n" \
	+ "+0.2%% damage from %s\n" % nature_string \
	+ "+0.6% chance\n"
	list.append(morphling_strike)

	var evolve: AbilityInfo = AbilityInfo.new()
	evolve.name = "Evolve"
	evolve.icon = "res://Resources/Icons/plants/tree.tres"
	evolve.description_short = "Every time it casts [color=GOLD]Morphling Strike[/color], this tower permanently gains power, depending on current Morph stacks.\n"
	evolve.description_full = "Every time it casts Morphling Strike, this tower permanently gains 0.2% base damage and 0.1% attack speed if [color=GOLD]Morph: Might[/color] has at least 25 stacks, or 0.2% attack speed and 0.1% base damage if [color=GOLD]Morph: Swiftness[/color] has at least 25 stacks.  Can evolve a maximum of 500 times.\n"
	list.append(evolve)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func get_ability_ranges() -> Array[RangeData]:
	return [RangeData.new("Morphling Strike", 900, TargetType.new(TargetType.CREEPS))]


func tower_init():
	might_bt = BuffType.new("might_bt", -1, 0, true, self)
	var might_bt_mod: Modifier = Modifier.new()
	might_bt_mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.02)
	might_bt_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, -0.02)
	might_bt.set_buff_modifier(might_bt_mod)
	might_bt.set_buff_icon("res://Resources/Icons/GenericIcons/biceps.tres")
	might_bt.set_buff_tooltip("Morph: Might\nIncreases attack damage and reduces attack speed after each attack.")

	swiftness_bt = BuffType.new("swiftness_bt", -1, 0, true, self)
	var swiftness_bt_mod: Modifier = Modifier.new()
	swiftness_bt_mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, -0.02)
	swiftness_bt_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.02)
	swiftness_bt.set_buff_modifier(swiftness_bt_mod)
	swiftness_bt.set_buff_icon("res://Resources/Icons/GenericIcons/sprint.tres")
	swiftness_bt.set_buff_tooltip("Morph: Swiftness\nIncreases attack speed and reduces attack damage after each attack.")

	adapt_bt = BuffType.new("adapt_bt", -1, 0, true, self)
	adapt_bt.set_buff_icon("res://Resources/Icons/GenericIcons/atomic_slashes.tres")
	adapt_bt.set_buff_tooltip("Adapt\nGetting read to adapt to new Morph.")

	dot_bt = BuffType.new("dot_bt", 5, 0, false, self)
	dot_bt.set_buff_icon("res://Resources/Icons/GenericIcons/triple_scratches.tres")
	dot_bt.add_periodic_event(dot_bt_periodic, 1.0)
	dot_bt.set_buff_tooltip("Mighty Strike\nDeals damage over time.")

	swift_strike_bt = BuffType.new("swift_strike_bt", 8, 0.1, false, self)
	var swift_strike_bt_mod: Modifier = Modifier.new()
	swift_strike_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.2, -0.004)
	swift_strike_bt_mod.add_modification(Modification.Type.MOD_DMG_FROM_NATURE, 0.15, 0.002)
	swift_strike_bt.set_buff_modifier(swift_strike_bt_mod)
	swift_strike_bt.set_buff_icon("res://Resources/Icons/GenericIcons/amber_mosquito.tres")
	swift_strike_bt.set_buff_tooltip("Swift Strike\nIncreases damage taken from Nature towers.")

	damage_pt = ProjectileType.create("SpiritOfVengeanceMissile.mdl", 4, 800, self)
	damage_pt.enable_homing(damage_pt_on_hit, 0)

	speed_pt = ProjectileType.create("ChimaeraAcidMissile.mdl", 4, 800, self)
	speed_pt.enable_homing(speed_pt_on_hit, 0)

	multiboard = MultiboardValues.new(2)
	multiboard.set_key(0, "Evolve")
	multiboard.set_key(1, "Morph level")


func create_autocasts() -> Array[Autocast]:
	var list: Array[Autocast] = []

	var autocast_might: Autocast = Autocast.make()
	autocast_might.title = "Morph: Might"
	autocast_might.icon = "res://Resources/Icons/trinkets/trinket_07.tres"
	autocast_might.description_short = "Activates [color=GOLD]Morph: Might[/color].\n"
	autocast_might.description = "Activates [color=GOLD]Morph: Might[/color]. As long as this buff is on this tower gains 2% base damage and loses 2% attack speed on every attack, up to a maximum of 50 times. Removes [color=GOLD]Morph: Swiftness[/color] and resets its bonus when activated.\n"
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
	autocast_might.buff_type = might_bt
	autocast_might.target_type = TargetType.new(TargetType.TOWERS)
	autocast_might.handler = on_autocast_might
	list.append(autocast_might)

	var autocast_swiftness: Autocast = Autocast.make()
	autocast_swiftness.title = "Morph: Swiftness"
	autocast_swiftness.icon = "res://Resources/Icons/trinkets/trinket_08.tres"
	autocast_swiftness.description_short = "Activates [color=GOLD]Morph: Swiftness[/color].\n"
	autocast_swiftness.description = "Activates [color=GOLD]Morph: Swiftness[/color]. As long as this buff is on this tower gains 2% attack speed and loses 2% base damage on every attack, up to a maximum of 50 times. Removes [color=GOLD]Morph: Might[/color] and resets its bonus when activated."
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
	autocast_swiftness.buff_type = swiftness_bt
	autocast_swiftness.target_type = TargetType.new(TargetType.TOWERS)
	autocast_swiftness.handler = on_autocast_swiftness
	list.append(autocast_swiftness)

	var autocast_adapt: Autocast = Autocast.make()
	autocast_adapt.title = "Adapt"
	autocast_adapt.icon = "res://Resources/Icons/trinkets/trinket_01.tres"
	autocast_adapt.description_short = "Stops the effect of morphs.\n"
	autocast_adapt.description = "Stops the effect of morphs, leaving the current [color=GOLD]Morph[/color] buff on the tower. Using the spell again removes [color=GOLD]Adapt[/color].\n"
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
	autocast_adapt.buff_type = adapt_bt
	autocast_adapt.target_type = TargetType.new(TargetType.TOWERS)
	autocast_adapt.handler = on_autocast_adapt
	list.append(autocast_adapt)

	return list


func on_attack(_event: Event):
	var damage_buff: Buff = tower.get_buff_of_type(might_bt)
	var speed_buff: Buff = tower.get_buff_of_type(swiftness_bt)
	var adapt_buff: Buff = tower.get_buff_of_type(adapt_bt)

	if adapt_buff == null:
		if damage_buff != null && damage_buff.get_level() < 50:
			print("apply might!")
			print("tower.get_buff_of_type(might_bt)=", tower.get_buff_of_type(might_bt))
			might_bt.apply(tower, tower, damage_buff.get_level() + 1)
			print("tower.get_buff_of_type(might_bt)=", tower.get_buff_of_type(might_bt))
		elif speed_buff != null && speed_buff.get_level() < 50:
			swiftness_bt.apply(tower, tower, speed_buff.get_level() + 1)


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
