extends TowerBehavior


# NOTE: original script implements "attacks random target"
# ability using aura. Changed implementation to use a
# simpler method with same behavior.


var intense_heat_bt: BuffType
var aura_bt: BuffType
var lingering_flames_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_kill(on_kill)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/hammer_drop.tres")
	aura_bt.add_event_on_create(aura_bt_on_create)
	aura_bt.add_periodic_event(aura_bt_periodic, 5.0)
	aura_bt.add_event_on_cleanup(aura_bt_on_cleanup)
	aura_bt.set_buff_tooltip(tr("C1M6"))

	intense_heat_bt = BuffType.new("intense_heat_bt", 4, 0, true, self)
	var intense_heat_bt_mod: Modifier = Modifier.new()
	intense_heat_bt_mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.0, 0.0005)
	intense_heat_bt_mod.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.0, 0.0005)
	intense_heat_bt.set_buff_modifier(intense_heat_bt_mod)
	intense_heat_bt.set_buff_icon("res://resources/icons/generic_icons/flame.tres")
	intense_heat_bt.set_buff_tooltip(tr("TTEZ"))

	lingering_flames_bt = BuffType.new("lingering_flames_bt", 10, 0, false, self)
	lingering_flames_bt.add_periodic_event(lingering_flames_bt_periodic, 1.0)
	lingering_flames_bt.set_buff_icon("res://resources/icons/generic_icons/flame.tres")
	lingering_flames_bt.set_buff_tooltip(tr("G9ZF"))


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

	var effect: int = Effect.create_scaled("res://src/effects/small_flame_spawn.tscn", tower.get_position_wc3(), 270, fxscale)
	Effect.set_lifetime(effect, 6.6)

	while true:
		var next: Unit = damagecast.next()

		if next == null:
			break

		ashbringer_linger_apply(next)
		var damage: float = (7 + 0.2 * tower.get_level()) * tower_mana
		tower.do_spell_damage(next, damage, tower.calc_spell_crit_no_bonus())
		Effect.create_simple_at_unit_attached("res://src/effects/small_flame_spawn.tscn", next, Unit.BodyPart.ORIGIN)

	while true:
		var next: Unit = buffcast.next()

		if next == null:
			break

		intense_heat_bt.apply(tower, next, int(tower_mana / 15.0))

	tower.subtract_mana(tower_mana, true)


func ashbringer_linger_apply(target: Unit):
	var buff: Buff = target.get_buff_of_type(lingering_flames_bt)
	
	var active_stacks: int
	if buff != null:
		active_stacks = buff.user_int
	else:
		active_stacks = 0

	var new_stacks: int = active_stacks + 1

	buff = lingering_flames_bt.apply(tower, target, 1)
	buff.user_int = new_stacks
	buff.set_displayed_stacks(new_stacks)


func lingering_flames_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var stack_count: int = buff.user_int
	var damage: float = (100 + 2 * tower.get_level()) * stack_count
	var gain_mana_chance: float = 0.2 + 0.004 * tower.get_level()

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())

	if tower.calc_chance(gain_mana_chance):
		tower.add_mana_perc(0.005 * stack_count)


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
#	NOTE: 1.0 is 0.0 in original script. Changed it to 1.0
#	because in youtd2 get_attack_speed_modifier() is based
#	around 1.0.
	var attack_speed_innate: float = 1.0 + caster_level * Constants.INNATE_MOD_ATTACKSPEED_LEVEL_ADD
	buff.user_real = (caster.get_prop_spell_damage_dealt() - 1.0) * caster_level_factor
	buff.user_real = (caster.get_spell_crit_chance() - spell_crit_innate) * caster_level_factor
	buff.user_real = (caster.get_spell_crit_chance() - spell_dmg_innate) * caster_level_factor
	buff.user_int = int((caster.get_attack_speed_modifier() - attack_speed_innate) * caster_level_factor * 1000)
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
