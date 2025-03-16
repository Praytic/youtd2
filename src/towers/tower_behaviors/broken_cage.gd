extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 0.35, damage_add = 0.010},
		2: {damage = 0.45, damage_add = 0.013},
		3: {damage = 0.55, damage_add = 0.016},
		4: {damage = 0.65, damage_add = 0.019},
		5: {damage = 0.75, damage_add = 0.022},
		}


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var damage: String = Utils.format_percent(_stats.damage, 2)
	var damage_add: String = Utils.format_percent(_stats.damage_add, 2)
	var magic_string: String = CreepCategory.convert_to_colored_string(CreepCategory.enm.MAGIC)
	var undead_string: String = CreepCategory.convert_to_colored_string(CreepCategory.enm.UNDEAD)
	var nature_string: String = CreepCategory.convert_to_colored_string(CreepCategory.enm.NATURE)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Banish"
	ability.icon = "res://resources/icons/magic/magic_stone_green.tres"
	ability.description_short = "Deals extra spell damage when hitting %s, %s and %s creeps.\n" % [magic_string, undead_string, nature_string]
	ability.description_full = "Deals additional %s spell damage when hitting %s, %s and %s creeps.\n" % [damage, magic_string, undead_string, nature_string] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage\n" % damage_add
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var creep: Creep = event.get_target()
	var creep_category: CreepCategory.enm = creep.get_category()
	var category_match: bool = [CreepCategory.enm.UNDEAD, CreepCategory.enm.MAGIC, CreepCategory.enm.NATURE].has(creep_category)

	if category_match:
		tower.do_spell_damage(creep, event.damage * (_stats.damage + (_stats.damage_add * tower.get_level())), tower.calc_spell_crit_no_bonus())
		Effect.create_simple_at_unit("res://src/effects/mana_burn_target.tscn", creep)
