extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {smite_damage = 10, smite_damage_add = 18, armor_reduce = -0.6, armor_reduce_boss = -0.2},
		2: {smite_damage = 35, smite_damage_add = 63, armor_reduce = -0.9, armor_reduce_boss = -0.3},
		3: {smite_damage = 90, smite_damage_add = 162, armor_reduce = -1.2, armor_reduce_boss = -0.4},
		4: {smite_damage = 190, smite_damage_add = 342, armor_reduce = -1.5, armor_reduce_boss = -0.5},
		5: {smite_damage = 380, smite_damage_add = 648, armor_reduce = -1.8, armor_reduce_boss = -0.6},
	}


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var smite_damage: String = Utils.format_float(_stats.smite_damage, 2)
	var smite_damage_add: String = Utils.format_float(_stats.smite_damage_add, 2)
	var armor_reduce: String = Utils.format_float(_stats.armor_reduce, 2)
	var armor_reduce_boss: String = Utils.format_float(_stats.armor_reduce_boss, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Smite"
	ability.icon = "res://resources/icons/electricity/lightning_glowing.tres"
	ability.description_short = "Chance to smite hit creeps, dealing spell damage.\n"
	ability.description_full = "5%% chance to smite hit creeps, dealing %s spell damage.\n" % smite_damage \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+2% chance\n" \
	+ "+%s spell damage\n" % smite_damage_add \
	+ "%s permanent armor reduction (%s on bosses) at level 25" % [armor_reduce, armor_reduce_boss]
	list.append(ability)

	return list


# NOTE: this tower's tooltip in original game does NOT
# include innate stats
func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.03)


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func on_damage(event: Event):
	if !tower.calc_chance(0.05 + tower.get_level() * 0.02):
		return

	var creep: Unit = event.get_target()
	var level: int = tower.get_level()

	CombatLog.log_ability(tower, creep, "Smite")

	tower.do_spell_damage(creep, _stats.smite_damage + (level * _stats.smite_damage_add), tower.calc_spell_crit_no_bonus())
	Effect.create_simple_at_unit("res://src/effects/holy_bolt.tscn", creep)

	if level == 25:
		if creep.get_size() < CreepSize.enm.BOSS:
			creep.modify_property(Modification.Type.MOD_ARMOR, _stats.armor_reduce)
		else:
			creep.modify_property(Modification.Type.MOD_ARMOR, _stats.armor_reduce_boss)
