extends TowerBehavior


# NOTE: the fact that this tower hits 8 creeps is stated in
# original tooltip for "Soulfire" ability. Usually it's
# stated more explicitly than that. Check if this tower in
# original game actually attacked 8 creeps or not.


var evil_device_bt: BuffType
var soulfire_bt: BuffType
var awaken_bt: BuffType
var soulflame_pt: ProjectileType
var multiboard: MultiboardValues
var awaken_count: int = 0

const AURA_RANGE: int = 350


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var soulfire: AbilityInfo = AbilityInfo.new()
	soulfire.name = "Soulfire"
	soulfire.icon = "res://resources/icons/fire/flame_purple.tres"
	soulfire.description_short = "Chance to burn hit creeps, dealing spell damage.\n"
	soulfire.description_full = "20% chance to burn hit creeps, dealing 1000 spell damage per second for 5 seconds. This effect stacks.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.4% chance\n" \
	+ "+40 spell damage\n"
	list.append(soulfire)

	var soul_consumption: AbilityInfo = AbilityInfo.new()
	soul_consumption.name = "Soul Consumption"
	soul_consumption.icon = "res://resources/icons/tower_icons/dark_battery.tres"
	soul_consumption.description_short = "When a creep dies under the effect of [color=GOLD]Soulfire[/color], [color=GOLD]Soulfire[/color] spreads to nearby creeps.\n"
	soul_consumption.description_full = "When a creep dies under the effect of [color=GOLD]Soulfire[/color], [color=GOLD]Soulfire[/color] spreads to nearby creeps within 200 range. The creep is consumed by the tower, restoring 5 mana.\n"
	list.append(soul_consumption)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	tower.set_target_count(8)

	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, -0.40, 0.01)


func tower_init():
	evil_device_bt = BuffType.create_aura_effect_type("evil_device_bt", true, self)
	evil_device_bt.set_buff_icon("res://resources/icons/generic_icons/pokecog.tres")
	evil_device_bt.add_event_on_create(evil_device_bt_on_create)
	evil_device_bt.add_event_on_cleanup(evil_device_bt_on_cleanup)
	evil_device_bt.add_periodic_event(evil_device_bt_periodic, 5)
	evil_device_bt.set_buff_tooltip("Evil Device\nIncreases attack speed, trigger changes, spell damage, spell crit chance and attack damage.")

	soulfire_bt = BuffType.new("soulfire_bt", 5, 0, false, self)
	soulfire_bt.set_buff_icon("res://resources/icons/generic_icons/burning_dot.tres")
	soulfire_bt.add_periodic_event(soulfire_bt_periodic, 1)
	soulfire_bt.add_event_on_death(soulfire_bt_on_death)
	soulfire_bt.set_buff_tooltip("Soulfire\nDeals damage over time.")

	awaken_bt = BuffType.new("awaken_bt", 3, 0, true, self)
	var awaken_bt_mod: Modifier = Modifier.new()
	awaken_bt_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.50, 0.02)
	awaken_bt.set_buff_modifier(awaken_bt_mod)
	awaken_bt.set_buff_icon("res://resources/icons/generic_icons/semi_closed_eye.tres")
	awaken_bt.set_buff_tooltip("Awaken\nIncreases attack speed.")

	soulflame_pt = ProjectileType.create("path_to_projectile_sprite", 5, 9000, self)

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Awaken Cast")


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	autocast.title = "Awaken"
	autocast.icon = "res://resources/icons/magic/fire.tres"
	autocast.description_short = "Increases the attack speed of nearby towers and permanently increases the attack speed of this tower.\n"
	autocast.description = "Increases the attack speed of towers within 350 range by 50% for 3 seconds and permanently increases the attack speed of this tower by 1%.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+2% attack speed\n"
	autocast.caster_art = "UCancelDeath.mdl"
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 900
	autocast.auto_range = 900
	autocast.cooldown = 4
	autocast.mana_cost = 50
	autocast.target_self = false
	autocast.is_extended = true
	autocast.buff_type = null
	autocast.buff_target_type = null
	autocast.handler = on_autocast

	return [autocast]


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var darkness_string: String = Element.convert_to_colored_string(Element.enm.DARKNESS)

	aura.name = "Evil Device"
	aura.icon = "res://resources/icons/mechanical/battery.tres"
	aura.description_short = "Increases attack stats of nearby Common and Uncommon %s towers.\n" % darkness_string
	aura.description_full = "Attack speed, trigger chances, spell damage, spell crit chance and spell crit damage bonuses on this tower are applied to Common and Uncommon %s towers in %d range at a rate of 50%%.\n" % [darkness_string, AURA_RANGE] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+2% stats\n"

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS + TargetType.ELEMENT_DARKNESS + TargetType.RARITY_UNCOMMON + TargetType.RARITY_COMMON)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = evil_device_bt

	return [aura]


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var soulfire_chance: float = 0.2 + 0.004 * tower.get_level()

	if !tower.calc_chance(soulfire_chance):
		return

	ashbringer_soulfire_apply(target, 1)


func on_autocast(_event: Event):
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.TOWERS), tower, 350)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		awaken_bt.apply(tower, next, tower.get_level())

	awaken_count += 1
	tower.modify_property(Modification.Type.MOD_ATTACKSPEED, 0.01)


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, str(awaken_count))

	return multiboard


func evil_device_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	evil_device_bt_update(buff)


func evil_device_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Tower = buff.get_buffed_unit()

	buffed_tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -buff.user_real)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, -buff.user_real2)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_DAMAGE, -buff.user_real3)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, -buff.user_int / 1000.0)
	buffed_tower.modify_property(Modification.Type.MOD_TRIGGER_CHANCES, -buff.user_int2 / 1000.0)


func evil_device_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	evil_device_bt_update(buff)


func evil_device_bt_update(buff: Buff):
	var buffed_tower: Tower = buff.get_buffed_unit()
	var caster: Unit = buff.get_caster()
	var caster_level: int = caster.get_level()
	var caster_level_factor: float = 0.5 + 0.02 * caster_level

	buffed_tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -buff.user_real)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, -buff.user_real2)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_DAMAGE, -buff.user_real3)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, -buff.user_int / 1000.0)
	buffed_tower.modify_property(Modification.Type.MOD_TRIGGER_CHANCES, -buff.user_int2 / 1000.0)

	var spell_crit_chance_innate: float = Constants.INNATE_MOD_SPELL_CRIT_CHANCE - caster_level * Constants.INNATE_MOD_SPELL_CRIT_CHANCE_LEVEL_ADD
	var spell_crit_dmg_innate: float = Constants.INNATE_MOD_SPELL_CRIT_DAMAGE - caster_level * Constants.INNATE_MOD_SPELL_CRIT_DAMAGE_LEVEL_ADD
#	NOTE: 1.0 is 0.0 in original script. Changed it to 1.0
#	because in youtd2 get_attack_speed_modifier() is based
#	around 1.0.
	var attack_speed_innate: float = 1.0 + caster_level * Constants.INNATE_MOD_ATTACKSPEED_LEVEL_ADD

	buff.user_real = (caster.get_prop_spell_damage_dealt() - 1.0) * caster_level_factor
	buff.user_real2 = (caster.get_spell_crit_chance() - spell_crit_chance_innate) * caster_level_factor
	buff.user_real3 = (caster.get_spell_crit_damage() - spell_crit_dmg_innate) * caster_level_factor
	buff.user_int = int((caster.get_attack_speed_modifier() - attack_speed_innate) * caster_level_factor * 1000.0)
	buff.user_int2 = int((caster.get_prop_trigger_chances() - 1.0) * caster_level_factor * 1000.0)

	buffed_tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, buff.user_real)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, buff.user_real2)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_DAMAGE, buff.user_real3)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, buff.user_int / 1000.0)
	buffed_tower.modify_property(Modification.Type.MOD_TRIGGER_CHANCES, buff.user_int2 / 1000.0)


func soulfire_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var stack_count: int = buff.user_int
	var damage_per_stack = 1000 + 40 * tower.get_level()
	var damage: float = damage_per_stack * stack_count

	tower.do_spell_damage(buffed_unit, damage, tower.calc_spell_crit_no_bonus())


func soulfire_bt_on_death(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), buffed_unit, 200)

	Effect.create_simple_at_unit("res://src/effects/death_coil.tscn", buffed_unit)

	ashbringer_consumption_missile(buffed_unit)

	tower.add_mana(5.0)

	var nearby_count: int = it.count()

	var stack_count_on_dead_creep: int
	if buff != null:
		stack_count_on_dead_creep = buff.user_int
	else:
		stack_count_on_dead_creep = 0

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		var stack_gain: int = floori(Utils.divide_safe(stack_count_on_dead_creep, nearby_count))
		ashbringer_soulfire_apply(next, stack_gain)


func ashbringer_consumption_missile(target: Unit):
	var destination_pos: Vector3 = Vector3(tower.get_x(), tower.get_y(), 215)

	Projectile.create_from_unit_to_point(soulflame_pt, target, 0, 0, target, destination_pos, false, true)


func ashbringer_soulfire_apply(target: Unit, stack_gain: int):
	var buff: Buff = target.get_buff_of_type(soulfire_bt)

	if stack_gain < 1:
		stack_gain = 1

	var active_stack_count: int = 0
	if buff != null:
		active_stack_count = buff.user_int

	var new_stack_count: int = active_stack_count + stack_gain

	buff = soulfire_bt.apply(tower, target, 1)
	buff.user_int = new_stack_count
	buff.set_displayed_stacks(new_stack_count)
