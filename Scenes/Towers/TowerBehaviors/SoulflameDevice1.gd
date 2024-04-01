extends TowerBehavior


# NOTE: the fact that this tower hits 8 creeps is stated in
# original tooltip for "Soulfire" ability. Usually it's
# stated more explicitly than that. Check if this tower in
# original game actually attacked 8 creeps or not.


var example_bt: BuffType
var ash_soulflame_aura_bt: BuffType
var ash_soulflame_soulfire_bt: BuffType
var ash_soulflame_awaken_bt: BuffType
var soulflame_pt: ProjectileType
var multiboard: MultiboardValues
var awaken_count: int = 0


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Soulfire[/color]\n"
	text += "Chance to ignite the enemy's soul, dealing 1000 spell damage per second for 5 seconds. This effect stacks.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% chance\n"
	text += "+40 spell damage\n"
	text += " \n"

	text += "[color=GOLD]Soul Consumption[/color]\n"
	text += "When an enemy dies under the effect of Soulfire, Soulfire spreads to nearby enemies within 200 range. The enemy is consumed by the tower, restoring 5 mana.\n"
	text += " \n"

	text += "[color=GOLD]Evil Device - Aura[/color]\n"
	text += "Attack speed, trigger chances, spell damage, spell crit chance and spell crit damage bonuses on this tower are applied to Common and Uncommon Darkness towers in 350 range at a rate of 50%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+2% stats\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Soulfire[/color]\n"
	text += "Chance to ignite the enemy's soul.\n"
	text += " \n"

	text += "[color=GOLD]Soul Consumption[/color]\n"
	text += "When an enemy dies under the effect of Soulfire, Soulfire spreads to nearby enemies.\n"
	text += " \n"

	text += "[color=GOLD]Evil Device - Aura[/color]\n"
	text += "Increases attack stats of nearby Common and Uncommon Darkness towers.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "Increases the attack speed of towers within 350 range by 50% for 3 seconds and permanently increases the attack speed of this tower by 1%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+2% attack speed\n"

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "Increases the attack speed of nearby towers and permanently increases the attack speed of this tower.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	tower.set_target_count(8)

	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, -0.40, 0.01)


func tower_init():
	ash_soulflame_aura_bt = BuffType.create_aura_effect_type("ash_soulflame_aura_bt", true, self)
	ash_soulflame_aura_bt.set_buff_icon("gear_1.tres")
	ash_soulflame_aura_bt.add_event_on_create(ash_soulflame_aura_bt_on_create)
	ash_soulflame_aura_bt.add_event_on_cleanup(ash_soulflame_aura_bt_on_cleanup)
	ash_soulflame_aura_bt.add_periodic_event(ash_soulflame_aura_bt_periodic, 5)
	ash_soulflame_aura_bt.set_buff_tooltip("Evil Device\nIncreases attack speed, trigger changes, spell damage, spell crit chance and attack damage.")

	ash_soulflame_soulfire_bt = BuffType.new("ash_soulflame_soulfire_bt", 5, 0, false, self)
	var ash_soulflame_soulfire_bt_mod: Modifier = Modifier.new()
	ash_soulflame_soulfire_bt_mod.add_modification(Modification.Type.MOD_ARMOR, 0.0, 0.0)
	ash_soulflame_soulfire_bt.set_buff_modifier(ash_soulflame_soulfire_bt_mod)
	ash_soulflame_soulfire_bt.set_buff_icon("fireball.tres")
	ash_soulflame_soulfire_bt.add_periodic_event(ash_soulflame_soulfire_bt_periodic, 1)
	ash_soulflame_soulfire_bt.add_event_on_death(ash_soulflame_soulfire_bt_on_death)
	ash_soulflame_soulfire_bt.set_buff_tooltip("Soulfire\nDeals damage over time.")

	ash_soulflame_awaken_bt = BuffType.new("ash_soulflame_awaken_bt", 3, 0, true, self)
	var ash_soulflame_awaken_bt_mod: Modifier = Modifier.new()
	ash_soulflame_awaken_bt_mod.add_modification(Modification.Type.MOD_ARMOR, 0.0, 0.0)
	ash_soulflame_awaken_bt.set_buff_modifier(ash_soulflame_awaken_bt_mod)
	ash_soulflame_awaken_bt.set_buff_icon("eye.tres")
	ash_soulflame_awaken_bt.set_buff_tooltip("Awaken\nIncreases attack speed.")

	soulflame_pt = ProjectileType.create("AvengerMissile.mdl", 5, 9000, self)

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Awaken Cast")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Awaken"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
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
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast
	tower.add_autocast(autocast)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 350
	aura.target_type = TargetType.new(TargetType.TOWERS + TargetType.ELEMENT_DARKNESS + TargetType.RARITY_UNCOMMON + TargetType.RARITY_COMMON)
	aura.target_self = false
	aura.level = 1
	aura.level_add = 0
	aura.power = 1
	aura.power_add = 0
	aura.aura_effect = ash_soulflame_aura_bt

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

		ash_soulflame_awaken_bt.apply(tower, next, tower.get_level())

	awaken_count += 1
	tower.modify_property(Modification.Type.MOD_ATTACKSPEED, 0.01)


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, str(awaken_count))

	return multiboard


func ash_soulflame_aura_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	ash_soulflame_aura_bt_update(buff)


func ash_soulflame_aura_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Tower = buff.get_buffed_unit()

	buffed_tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -buff.user_real)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, -buff.user_real2)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_DAMAGE, -buff.user_real3)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, -buff.user_int / 1000.0)
	buffed_tower.modify_property(Modification.Type.MOD_TRIGGER_CHANCES, -buff.user_int2 / 1000.0)


func ash_soulflame_aura_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	ash_soulflame_aura_bt_update(buff)


func ash_soulflame_aura_bt_update(buff: Buff):
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
	var attackspeed_innate: float = 0.0 + caster_level * Constants.INNATE_MOD_ATTACKSPEED_LEVEL_ADD

	buff.user_real = (caster.get_prop_spell_damage_dealt() - 1.0) * caster_level_factor
	buff.user_real2 = (caster.get_spell_crit_chance() - spell_crit_chance_innate) * caster_level_factor
	buff.user_real3 = (caster.get_spell_crit_damage() - spell_crit_dmg_innate) * caster_level_factor
	buff.user_int = int((caster.get_base_attackspeed() - attackspeed_innate) * caster_level_factor * 1000.0)
	buff.user_int2 = int((caster.get_prop_trigger_chances() - 1.0) * caster_level_factor * 1000.0)

	buffed_tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, buff.user_real)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, buff.user_real2)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_DAMAGE, buff.user_real3)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, buff.user_int / 1000.0)
	buffed_tower.modify_property(Modification.Type.MOD_TRIGGER_CHANCES, buff.user_int2 / 1000.0)


func ash_soulflame_soulfire_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var power: int = buff.get_power()
	var damage: float = (1000 + 40 * tower.get_level()) * power

	tower.do_spell_damage(buffed_unit, damage, tower.calc_spell_crit_no_bonus())


func ash_soulflame_soulfire_bt_on_death(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), buffed_unit, 200)

	var effect: int = Effect.create_simple_at_unit("DeathCoilSpecialArt.mdl", buffed_unit)
	Effect.destroy_effect_after_its_over(effect)

	ashbringer_consumption_missile(buffed_unit)

	tower.add_mana(5.0)

	var nearby_count: int = it.count()

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		var power_gain: int = buff.get_power() / nearby_count
		ashbringer_soulfire_apply(next, power_gain)


func ashbringer_consumption_missile(target: Unit):
	var destination_pos: Vector2 = tower.get_visual_position()

	Projectile.create_from_unit_to_point(soulflame_pt, target, 0, 0, target, destination_pos, false, true)


func ashbringer_soulfire_apply(target: Unit, power_gain: int):
	var b: Buff = target.get_buff_of_type(ash_soulflame_soulfire_bt)

	if power_gain < 1:
		power_gain = 1

	var power: int
	if b != null:
		power = b.get_power() + power_gain
	else:
		power = power_gain

	ash_soulflame_soulfire_bt.apply_custom_power(tower, target, 1, power)
