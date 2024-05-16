extends TowerBehavior


# NOTE: original script implements "attacks random target"
# ability using aura. Changed implementation to use a
# simpler method with same behavior.


var intense_heat_bt: BuffType
var aura_bt: BuffType
var lingering_flames_bt: BuffType

const AURA_RANGE: int = 350


func get_ability_info_list() -> Array[AbilityInfo]:	
	var list: Array[AbilityInfo] = []
	
	var uncontrollable: AbilityInfo = AbilityInfo.new()
	uncontrollable.name = "Uncontrollable Flames"
	uncontrollable.icon = "res://resources/icons/hud/dice.tres"
	uncontrollable.description_short = "The tower attacks a random creep in range with each attack.\n"
	uncontrollable.description_full = "The tower attacks a random creep in range with each attack.\n"
	list.append(uncontrollable)

	var lingering: AbilityInfo = AbilityInfo.new()
	lingering.name = "Lingering Flame"
	lingering.icon = "res://resources/icons/fire/fire_bowl_01.tres"
	lingering.description_short = "Whenever this tower hits a creep, it inflicts the target with [color=GOLD]Lingering Flame[/color], which deals periodic spell damage.\n"
	lingering.description_full = "Whenever this tower hits a creep, it inflicts the target with [color=GOLD]Lingering Flame[/color], dealing 100 spell damage per second for 10 seconds. This effect stacks.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+2 spell damage\n"
	list.append(lingering)

	var feed: AbilityInfo = AbilityInfo.new()
	feed.name = "Feed the Flames"
	feed.icon = "res://resources/icons/elements/fire.tres"
	feed.description_short = "This tower fuels itself in various ways, restoring mana and raising maximum mana.\n"
	feed.description_full = "This tower fuels itself in various ways. Gains 1% of maximum mana on attack. Whenever [color=GOLD]Lingering Flame[/color] deals damage, there is a 20% chance to gain 0.5% of maximum mana per stack. On kill, gains 4% of total mana and maximum mana is increased by 10.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.4% chance\n"
	list.append(feed)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_kill(on_kill)


func load_specials(_modifier: Modifier):
	tower.set_attack_style_splash({300: 1.0})


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/hammer_drop.tres")
	aura_bt.add_event_on_create(aura_bt_on_create)
	aura_bt.add_periodic_event(aura_bt_periodic, 5.0)
	aura_bt.add_event_on_cleanup(aura_bt_on_cleanup)
	aura_bt.set_buff_tooltip("Flames of the Forge\nIncreases attack speed, trigger chances, spell damage, spell crit chance and spell crit damage.")

	intense_heat_bt = BuffType.new("intense_heat_bt", 4, 0, true, self)
	var intense_heat_bt_mod: Modifier = Modifier.new()
	intense_heat_bt_mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.0, 0.0005)
	intense_heat_bt_mod.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.0, 0.0005)
	intense_heat_bt.set_buff_modifier(intense_heat_bt_mod)
	intense_heat_bt.set_buff_icon("res://resources/icons/generic_icons/flame.tres")
	intense_heat_bt.set_buff_tooltip("Intense Heat\nIncreases attack crit chance and spell crit chance.")

	lingering_flames_bt = BuffType.new("lingering_flames_bt", 10, 0, false, self)
	lingering_flames_bt.add_periodic_event(lingering_flames_bt_periodic, 1.0)
	lingering_flames_bt.set_buff_tooltip("Lingering Flames\nDeals damage over time.")


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()
	
	autocast.title = "Intense Heat"
	autocast.icon = "res://resources/icons/orbs/orb_fire.tres"
	autocast.description_short = "Expends all mana to unleash a wave of heat, dealing spell damage.\n"
	autocast.description = "Expends all mana to unleash a wave of heat, dealing [color=GOLD][mana x 7][/color] spell damage and applying [color=GOLD]Lingering Flame[/color] to all creeps in 1000 range. Increases the attack and spell crit chance of nearby towers within 350 range by [color=GOLD][mana / 300]%[/color] for 4 seconds.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.2 spell damage per mana\n"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 1000
	autocast.auto_range = 1000
	autocast.cooldown = 5
	autocast.mana_cost = 100
	autocast.target_self = false
	autocast.is_extended = true
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast

	return [autocast]


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var fire_string: String = Element.convert_to_colored_string(Element.enm.FIRE)
	
	aura.name = "Flames of the Forge"
	aura.icon = "res://resources/icons/tower_icons/CruelFire.tres"
	aura.description_short = "A portion of attack speed, trigger chances, spell damage, spell crit chance and spell crit damage bonuses of this tower are applied to nearby Common and Uncommon %s towers.\n" % fire_string
	aura.description_full = "Attack speed, trigger chances, spell damage, spell crit chance and spell crit damage bonuses of this tower are applied to Common and Uncommon %s towers in %d range at a rate of 50%%.\n" % [fire_string, AURA_RANGE] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+2% stats\n"

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS + TargetType.ELEMENT_FIRE + TargetType.RARITY_COMMON + TargetType.RARITY_UNCOMMON)
	aura.target_self = true
	aura.level = 1
	aura.level_add = 0
	aura.power = 1
	aura.power_add = 0
	aura.aura_effect = aura_bt

	return [aura]


func on_attack(_event: Event):
	var iterator: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), tower.get_range())
	var random_unit: Unit = iterator.next_random()

	tower.add_mana_perc(0.01)

	tower.issue_target_order(random_unit)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	ashbringer_linger_apply(target)


func on_kill(_event: Event):
	tower.modify_property(Modification.Type.MOD_MANA, 10)
	tower.add_mana_perc(0.04)


func on_autocast(_event: Event):
	var damagecast: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), tower, 1000)
	var buffcast: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.TOWERS), tower, 350)
	var tower_mana: float = tower.get_mana()
	var fxscale: float = 0.8 + min(tower_mana, 3000) / 3000 * 0.9

#	NOTE: increase scale because original one is too small
	fxscale *= 5

	var effect: int = Effect.create_scaled("SmallFlameSpawn.mdl", tower.get_position_wc3(), 270, fxscale)
	Effect.set_lifetime(effect, 6.6)

	while true:
		var next: Unit = damagecast.next()

		if next == null:
			break

		ashbringer_linger_apply(next)
		var damage: float = (7 + 0.2 * tower.get_level()) * tower_mana
		tower.do_spell_damage(next, damage, tower.calc_spell_crit_no_bonus())
		var damage_effect: int = Effect.create_simple_on_unit("FireTrapUp.mdl", next, Unit.BodyPart.ORIGIN)
		Effect.set_lifetime(damage_effect, 3.0)

	while true:
		var next: Unit = buffcast.next()

		if next == null:
			break

		intense_heat_bt.apply(tower, next, int(tower_mana / 15.0))

	tower.subtract_mana(tower_mana, true)


func ashbringer_linger_apply(target: Unit):
	var buff: Buff = target.get_buff_of_type(lingering_flames_bt)
	
	var power: int = 0
	if buff != null:
		power = buff.get_power() + 1
	else:
		power = 1

	lingering_flames_bt.apply_custom_power(tower, target, 1, power)


func lingering_flames_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var power: int = buff.get_power()
	var damage: float = (100 + 2 * tower.get_level()) * power
	var gain_mana_chance: float = 0.2 + 0.004 * tower.get_level()

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())

	if tower.calc_chance(gain_mana_chance):
		tower.add_mana_perc(0.005 * power)


func aura_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	ashbringer_heart_update(buff)


func aura_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	ashbringer_heart_update(buff)


func ashbringer_heart_update(buff: Buff):
	var caster: Tower = buff.get_caster()
	var buffed_tower: Tower = buff.get_buffed_unit()
	var caster_level: float = caster.get_level()
	var caster_level_factor: float = 0.5 + 0.02 * caster_level

	buffed_tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -buff.user_real)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, -buff.user_real2)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_DAMAGE, -buff.user_real3)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, -buff.user_int / 1000.0)
	buffed_tower.modify_property(Modification.Type.MOD_TRIGGER_CHANCES, -buff.user_int2 / 1000.0)

	var spell_crit_innate: float = Constants.INNATE_MOD_SPELL_CRIT_CHANCE - caster_level * Constants.INNATE_MOD_SPELL_CRIT_CHANCE_LEVEL_ADD
	var spell_dmg_innate: float = Constants.INNATE_MOD_SPELL_CRIT_DAMAGE - caster_level * Constants.INNATE_MOD_SPELL_CRIT_DAMAGE_LEVEL_ADD
	var attack_speed_innate: float = 0.0 + caster_level * Constants.INNATE_MOD_ATTACKSPEED_LEVEL_ADD
	buff.user_real = (caster.get_prop_spell_damage_dealt() - 1.0) * caster_level_factor
	buff.user_real = (caster.get_spell_crit_chance() - spell_crit_innate) * caster_level_factor
	buff.user_real = (caster.get_spell_crit_chance() - spell_dmg_innate) * caster_level_factor
	buff.user_int = int((caster.get_base_attack_speed() - attack_speed_innate) * caster_level_factor * 1000)
	buff.user_int2 = int((caster.get_prop_trigger_chances() - 1.0) * caster_level_factor * 1000)

	buffed_tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, buff.user_real)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, buff.user_real2)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_DAMAGE, buff.user_real3)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, buff.user_int / 1000.0)
	buffed_tower.modify_property(Modification.Type.MOD_TRIGGER_CHANCES, buff.user_int2 / 1000.0)


func aura_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Tower = buff.get_buffed_unit()

	buffed_tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -buff.user_real)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, -buff.user_real2)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_DAMAGE, -buff.user_real3)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, -buff.user_int / 1000.0)
	buffed_tower.modify_property(Modification.Type.MOD_TRIGGER_CHANCES, -buff.user_int2 / 1000.0)
