extends Tower


# NOTE: original script implements "attacks random target"
# ability using aura. Changed implementation to use a
# simpler method with same behavior.


var ashbringer_intense_bt: BuffType
var ashbringer_heart_aura_bt: BuffType
var ashbringer_linger_bt: BuffType
var ashbringer_attackrandom_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Uncontrollable Flames[/color]\n"
	text += "The tower attacks a random enemy in range with each attack. Enemies hit are inflicted with Lingering Flame, dealing 100 spell damage per second for 10 seconds. This effect stacks.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+2 spell damage\n"
	text += " \n"

	text += "[color=GOLD]Flames of the Forge - Aura[/color]\n"
	text += "Attack speed, trigger chances, spell damage, spell crit chance and spell crit damage bonuses on this tower are applied to Common and Uncommon Fire towers in 350 range at a rate of 50%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+2% stats\n"
	text += " \n"

	text += "[color=GOLD]Feed the Flames[/color]\n"
	text += "This tower fuels itself in various ways. Gains 1% of maximum mana on attack. Whenever Lingering Flame deals damage, there is a 20% chance to gain 0.5% of maximum mana per stack. On kill, gains 4% of total mana and maximum mana is increased by 10.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% chance\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Uncontrollable Flames[/color]\n"
	text += "The tower attacks a random enemy in range with each attack.\n"
	text += " \n"

	text += "[color=GOLD]Flames of the Forge - Aura[/color]\n"
	text += "Increases attack speed, trigger chances, spell damage, spell crit chance and spell crit damage of nearby towers.\n"
	text += " \n"

	text += "[color=GOLD]Feed the Flames[/color]\n"
	text += "This tower fuels itself in various ways, restoring mana and raising maximum mana.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "Expends all mana to unleash a wave of heat, dealing [Mana x 7] spell damage and applying Lingering Flame to all enemies in 1000 range. Increases the attack and spell crit chance of nearby towers within 350 range by [Mana / 300]% for 4 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.2 spell damage per mana\n"

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "Expends all mana to unleash a wave of heat.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_kill(on_kill)


func load_specials(_modifier: Modifier):
	set_attack_style_splash({300: 1.0})


func tower_init():
	ashbringer_heart_aura_bt = BuffType.create_aura_effect_type("ashbringer_heart_aura_bt", true, self)
	ashbringer_heart_aura_bt.set_buff_icon("@@1@@")
	ashbringer_heart_aura_bt.add_event_on_create(ashbringer_heart_aura_bt_on_create)
	ashbringer_heart_aura_bt.add_periodic_event(ashbringer_heart_aura_bt_periodic, 5.0)
	ashbringer_heart_aura_bt.add_event_on_cleanup(ashbringer_heart_aura_bt_on_cleanup)
	ashbringer_heart_aura_bt.set_buff_tooltip("Flames of the Forge\nThis tower has increased attack speed, trigger chances, spell damage, spell crit chance and spell crit damage.")

	ashbringer_intense_bt = BuffType.new("ashbringer_intense_bt", 4, 0, true, self)
	var ashbringer_intense_bt_mod: Modifier = Modifier.new()
	ashbringer_intense_bt_mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.0, 0.0005)
	ashbringer_intense_bt_mod.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.0, 0.0005)
	ashbringer_intense_bt.set_buff_modifier(ashbringer_intense_bt_mod)
	ashbringer_intense_bt.set_buff_icon("@@2@@")
	ashbringer_intense_bt.set_buff_tooltip("Intense Heat\nThis tower has increased attack and spell crit chance.")

	ashbringer_linger_bt = BuffType.new("ashbringer_linger_bt", 10, 0, false, self)
	ashbringer_linger_bt.add_periodic_event(ashbringer_linger_bt_periodic, 1.0)
	ashbringer_linger_bt.set_buff_tooltip("Lingering Flames\nThis unit receives periodic damage.")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Intense Heat"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 750
	autocast.auto_range = 750
	autocast.cooldown = 5
	autocast.mana_cost = 100
	autocast.target_self = false
	autocast.is_extended = true
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast
	add_autocast(autocast)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 350
	aura.target_type = TargetType.new(TargetType.TOWERS + TargetType.ELEMENT_FIRE + TargetType.RARITY_COMMON + TargetType.RARITY_UNCOMMON)
	aura.target_self = true
	aura.level = 1
	aura.level_add = 0
	aura.power = 1
	aura.power_add = 0
	aura.aura_effect = ashbringer_heart_aura_bt

	return [aura]


func on_attack(_event: Event):
	var tower: Tower = self
	var iterator: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), tower.get_range())
	var random_unit: Unit = iterator.next_random()

	tower.add_mana_perc(0.01)

	issue_target_order("attack", random_unit)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	ashbringer_linger_apply(target)


func on_kill(_event: Event):
	var tower: Tower = self

	tower.modify_property(Modification.Type.MOD_MANA, 10)
	tower.add_mana_perc(0.04)


func on_autocast(_event: Event):
	var tower: Tower = self

	var damagecast: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), tower, 1000)
	var buffcast: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.TOWERS), tower, 350)
	var tower_mana: float = tower.get_mana()
	var fxscale: float = 0.8 + min(tower_mana, 3000) / 3000 * 0.9

	var effect: int = Effect.create_scaled("SmallFlameSpawn.mdl", tower.get_visual_x(), tower.get_visual_y(), 0, 270, fxscale)
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

		ashbringer_intense_bt.apply(tower, next, int(tower_mana / 15.0))

	tower.subtract_mana(tower_mana, true)


func ashbringer_linger_apply(target: Unit):
	var tower: Tower = self
	var buff: Buff = target.get_buff_of_type(ashbringer_linger_bt)
	
	var power: int = 0
	if buff != null:
		power = buff.get_power() + 1
	else:
		power = 1

	ashbringer_linger_bt.apply_custom_power(tower, target, 1, power)


func ashbringer_linger_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var tower: Tower = buff.get_caster()
	var target: Unit = buff.get_buffed_unit()
	var power: int = buff.get_power()
	var damage: float = (100 + 2 * tower.get_level()) * power
	var gain_mana_chance: float = 0.2 + 0.004 * tower.get_level()

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())

	if tower.calc_chance(gain_mana_chance):
		tower.add_mana_perc(0.005 * power)


func ashbringer_heart_aura_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	ashbringer_heart_update(buff)


func ashbringer_heart_aura_bt_periodic(event: Event):
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
	var attackspeed_innate: float = 0.0 + caster_level * Constants.INNATE_MOD_ATTACKSPEED_LEVEL_ADD
	buff.user_real = (caster.get_prop_spell_damage_dealt() - 1.0) * caster_level_factor
	buff.user_real = (caster.get_spell_crit_chance() - spell_crit_innate) * caster_level_factor
	buff.user_real = (caster.get_spell_crit_chance() - spell_dmg_innate) * caster_level_factor
	buff.user_int = int((caster.get_base_attack_speed() - attackspeed_innate) * caster_level_factor * 1000)
	buff.user_int2 = int((caster.get_prop_trigger_chances() - 1.0) * caster_level_factor * 1000)

	buffed_tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, buff.user_real)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, buff.user_real2)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_DAMAGE, buff.user_real3)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, buff.user_int / 1000.0)
	buffed_tower.modify_property(Modification.Type.MOD_TRIGGER_CHANCES, buff.user_int2 / 1000.0)


func ashbringer_heart_aura_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Tower = buff.get_buffed_unit()

	buffed_tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -buff.user_real)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, -buff.user_real2)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_DAMAGE, -buff.user_real3)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, -buff.user_int / 1000.0)
	buffed_tower.modify_property(Modification.Type.MOD_TRIGGER_CHANCES, -buff.user_int2 / 1000.0)
