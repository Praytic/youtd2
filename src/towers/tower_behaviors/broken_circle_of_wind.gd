extends TowerBehavior


var wind_bt: BuffType

func get_tier_stats() -> Dictionary:
	return {
		1: {catch_chance = 0.20, catch_chance_add = 0.003, cyclone_duration = 0.5, cyclone_damage = 20, cyclone_damage_add = 2},
		2: {catch_chance = 0.22, catch_chance_add = 0.004, cyclone_duration = 0.6, cyclone_damage = 68, cyclone_damage_add = 7},
		3: {catch_chance = 0.24, catch_chance_add = 0.005, cyclone_duration = 0.7, cyclone_damage = 196, cyclone_damage_add = 20},
		4: {catch_chance = 0.26, catch_chance_add = 0.006, cyclone_duration = 0.8, cyclone_damage = 600, cyclone_damage_add = 60},
		5: {catch_chance = 0.28, catch_chance_add = 0.007, cyclone_duration = 1.0, cyclone_damage = 1120, cyclone_damage_add = 112},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var catch_chance: String = Utils.format_percent(_stats.catch_chance, 2)
	var cyclone_duration: String = Utils.format_float(_stats.cyclone_duration, 2)
	var cyclone_damage: String = Utils.format_float(_stats.cyclone_damage, 2)
	var cyclone_damage_add: String = Utils.format_float(_stats.cyclone_damage_add, 2)
	var catch_chance_add: String = Utils.format_percent(_stats.catch_chance_add, 2)
	var physical_string: String = AttackType.convert_to_colored_string(AttackType.enm.PHYSICAL)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Wind of Death"
	ability.icon = "res://resources/icons/elements/storm.tres"
	ability.description_short = "On attack, this tower has a chance to catch the target in a cyclone. When the caught creep falls down, this tower deals %s damage to all creeps near the target. Doesn't work on bosses and air creeps.\n" % physical_string
	ability.description_full = "On attack, this tower has a %s chance to catch the target in a cyclone for %s seconds. When the caught creep falls down, this tower deals %s %s damage to creeps in 300 AoE around the target. AoE damage is increased by 25%% if the target is a champion. Doesn't work on bosses and air creeps.\n" % [catch_chance, cyclone_duration, physical_string, cyclone_damage] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage\n" % cyclone_damage_add \
	+ "+%s chance to catch\n" % catch_chance_add
	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.70, 0.02)


func tower_init():
	wind_bt = CbStun.new("wind_bt", 1.0, 0, false, self)
	wind_bt.set_buff_icon("res://resources/icons/generic_icons/rolling_energy.tres")
	wind_bt.add_event_on_create(wind_bt_on_create)
	wind_bt.add_periodic_event(wind_bt_periodic, 0.1)
	wind_bt.add_event_on_cleanup(wind_bt_on_cleanup)


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var damage: float = _stats.cyclone_damage + _stats.cyclone_damage_add * tower.get_level()
	var b: Buff

	if (target.get_size() == CreepSize.enm.MASS || target.get_size() == CreepSize.enm.NORMAL || target.get_size() == CreepSize.enm.CHAMPION):
		if (tower.calc_chance(_stats.catch_chance + (_stats.catch_chance_add * tower.get_level()))):
			CombatLog.log_ability(tower, target, "Wind of Death")

			b = target.get_buff_of_type(wind_bt)
			
			if b != null:
				damage = max(b.user_real3, damage)

			b = wind_bt.apply_custom_timed(tower, target, tower.get_level(), _stats.cyclone_duration)

			if b != null:
				b.user_real3 = damage


# NOTE: cyclone_creep_up() in original script
func wind_bt_on_create(event: Event):
	var b: Buff = event.get_buff()

	var c: Unit = b.get_buffed_unit()
#	(start) cyclone animation
	b.user_int = Effect.create_animated("res://src/effects/CycloneTarget.tscn", Vector3(c.get_x(), c.get_y(), 0.0), 0.0)
#   move creep up
	c.adjust_height(300, 1000)


# NOTE: cyclone_creep_turn() in original script
func wind_bt_periodic(event: Event):
	var b: Buff = event.get_buff()

	var real_unit: Unit = b.get_buffed_unit()
	real_unit.set_unit_facing(real_unit.get_unit_facing() + 150.0)
	real_unit = null


# NOTE: cyclone_creep_down() in original script
func wind_bt_on_cleanup(event: Event):
	var b: Buff = event.get_buff()

	var t: Unit = b.get_caster()
	var c: Unit = b.get_buffed_unit()
	var ratio: float = 1

	CombatLog.log_ability(t, c, "Wind of Death End")

#	set units back (down)
	c.adjust_height(-300, 2500)
#	remove the cyclone
	Effect.destroy_effect(b.user_int)
# 	effects
	var creep_pos: Vector2 = c.get_position_wc3_2d()
	var thunder_clap_effect: int = Effect.create_simple("res://src/effects/bdragon_466_thunderclap.tscn", creep_pos)
	Effect.set_z_index(thunder_clap_effect, 9)
	Effect.destroy_effect_after_its_over(thunder_clap_effect)
	var bolt_impact: int = Effect.create_simple_at_unit("res://src/effects/BoltImpact.tscn", c)
	Effect.destroy_effect_after_its_over(bolt_impact)
#   do damage
	if c.get_size() == CreepSize.enm.CHAMPION:
		ratio = 1.25

	t.do_attack_damage_aoe_unit(c, ratio * 300.0, b.user_real3, t.calc_attack_multicrit(0, 0, 0), 0.0)
