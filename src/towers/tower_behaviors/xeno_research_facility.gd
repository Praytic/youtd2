extends TowerBehavior


# NOTE: made changes to original script but overall
# it's the same logic.


# NOTE: tower increases dmg against only one category at a
# time (for other towers). This is intentional and works
# like this in original game.


var aura_bt: BuffType
var undead_bt: BuffType
var magic_bt: BuffType
var nature_bt: BuffType
var orc_bt: BuffType
var humanoid_bt: BuffType

const AURA_RANGE: float = 280


var bonus_levels_in_progress: bool = false
var force_show_research_message: bool = false
# which creep type i attacked - that's the type i'll buff next
var current_creep_category: CreepCategory.enm = CreepCategory.enm.UNDEAD
# memory of prev. attacked creep type
var prev_creep_category: CreepCategory.enm = CreepCategory.enm.UNDEAD
var bonus_map: Dictionary = {
	CreepCategory.enm.UNDEAD: 0,
	CreepCategory.enm.MAGIC: 0,
	CreepCategory.enm.NATURE: 0,
	CreepCategory.enm.ORC: 0,
	CreepCategory.enm.HUMANOID: 0,
	CreepCategory.enm.CHALLENGE: 0,
}


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var sample: AbilityInfo = AbilityInfo.new()
	sample.name = "Sample Collection"
	sample.icon = "res://resources/icons/mechanical/alchemy_kit_01.tres"
	sample.description_short = "Has a chance to collect a tissue sample from attacked creeps. Once researched, it will provide a bonus vs the race of that creep to nearby towers.\n"
	sample.description_full = "Has a 25% chance to collect a tissue sample from attacked creeps. Once researched, it will provide a 5% bonus vs the race of that creep, through the [color=GOLD]Xeno Vulnerability Research Aura[/color]. Maximum bonus per race is 25%. Whenever a different race is attacked, half of the research bonuses against all other races are lost.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1% chance to collect sample\n" \
	+ "+1% maximum bonus per race\n"
	list.append(sample)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 6.0)


func tower_init():
	undead_bt = BuffType.new("undead_bt", 1, 0, true, self)
	var palandu_xeno_undead_mod: Modifier = Modifier.new()
	palandu_xeno_undead_mod.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.0, 0.001)
	undead_bt.set_buff_modifier(palandu_xeno_undead_mod)
	undead_bt.set_buff_icon("res://resources/icons/generic_icons/spell_book.tres")
	undead_bt.set_buff_tooltip("Xeno Undead Research\nIncreases damage dealt to Undead creeps.")

	magic_bt = BuffType.new("magic_bt", 1, 0, true, self)
	var palandu_xeno_magic_mod: Modifier = Modifier.new()
	palandu_xeno_magic_mod.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, 0.0, 0.001)
	magic_bt.set_buff_modifier(palandu_xeno_magic_mod)
	magic_bt.set_buff_icon("res://resources/icons/generic_icons/spell_book.tres")
	magic_bt.set_buff_tooltip("Xeno Magic Research\nIncreases damage dealt to Magic creeps.")

	nature_bt = BuffType.new("nature_bt", 1, 0, true, self)
	var palandu_xeno_nature_mod: Modifier = Modifier.new()
	palandu_xeno_nature_mod.add_modification(Modification.Type.MOD_DMG_TO_NATURE, 0.0, 0.001)
	nature_bt.set_buff_modifier(palandu_xeno_nature_mod)
	nature_bt.set_buff_icon("res://resources/icons/generic_icons/spell_book.tres")
	nature_bt.set_buff_tooltip("Xeno Nature Research\nIncreases damage dealt to Nature creeps.")

	orc_bt = BuffType.new("orc_bt", 1, 0, true, self)
	var palandu_xeno_orc_mod: Modifier = Modifier.new()
	palandu_xeno_orc_mod.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.0, 0.001)
	orc_bt.set_buff_modifier(palandu_xeno_orc_mod)
	orc_bt.set_buff_icon("res://resources/icons/generic_icons/spell_book.tres")
	orc_bt.set_buff_tooltip("Xeno Orc Research\nIncreases damage dealt to Orc creeps.")

	humanoid_bt = BuffType.new("humanoid_bt", 1, 0, true, self)
	var palandu_xeno_humanoid_mod: Modifier = Modifier.new()
	palandu_xeno_humanoid_mod.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.0, 0.001)
	humanoid_bt.set_buff_modifier(palandu_xeno_humanoid_mod)
	humanoid_bt.set_buff_icon("res://resources/icons/generic_icons/spell_book.tres")
	humanoid_bt.set_buff_tooltip("Xeno Humanoid Research\nIncreases damage dealt to Humanoid creeps.")

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/spell_book.tres")
	aura_bt.set_buff_tooltip("Xeno Research\nEnhanced by a nearby Xeno Research Facility.")

	
func get_aura_types_DELETEME() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	aura.name = "Xeno Vulnerability Research"
	aura.icon = "res://resources/icons/orbs/orb_green.tres"
	aura.description_short = "Improves damage vs various creep races for all towers in range. Improvement amount depends on the [color=GOLD]Sample Collection[/color]. Stops working in the Bonus Level.\n"
	aura.description_full = "Improves damage vs various creep races for all towers in %d range. Improvement amount depends on the [color=GOLD]Sample Collection[/color]. Research results are published every 6 seconds and whenever a different race is attacked. Stops working in the Bonus Level.\n" % AURA_RANGE \
	+ " \n" \
	+ "[color=GOLD]Note:[/color] For this tower, research overrides any and all other race modifications. So the race bonuses of this tower reflect the bonuses given by this aura.\n"
	
	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = aura_bt
	return [aura]


func on_attack(event: Event):
	if bonus_levels_in_progress:
		return

	var creep: Creep = event.get_target()
	var creep_category: CreepCategory.enm = creep.get_category()

	if creep.get_spawn_level() > Utils.get_max_level():
		bonus_levels_in_progress = true

	current_creep_category = creep_category

	var is_type_change: bool = current_creep_category != prev_creep_category
	if is_type_change:
		xeno_buff_towers(true)


func on_damage(event: Event):
	if bonus_levels_in_progress:
		return
	
	var creep: Creep = event.get_target()
	var creep_category: CreepCategory.enm = creep.get_category()
	var chance: float = 0.25 + 0.01 * tower.get_level()

	if !tower.calc_chance(chance):
		return

# 	NOTE: ignore challenge creeps
	if creep_category == CreepCategory.enm.CHALLENGE:
		return

	var bonus_max: int = 250 + 10 * tower.get_level()
	var current_bonus: int = bonus_map[creep_category]

	if current_bonus >= bonus_max:
		return

	CombatLog.log_ability(tower, creep, "Sample Collection")

	tower.get_player().display_small_floating_text("Sample Collected", creep, Color8(200, 200, 200), 40.0)
	var new_bonus: int = min(current_bonus + 50, bonus_max)
	bonus_map[creep_category] = new_bonus
	force_show_research_message = true


func periodic(_event: Event):
	if !bonus_levels_in_progress:
		xeno_buff_towers(current_creep_category != prev_creep_category)


func xeno_manage_bonuses(is_type_change: bool, current_bonus: int):
# 	NOTE: ignore challenge creeps
	if current_creep_category == CreepCategory.enm.CHALLENGE:
		return

	if is_type_change:
		for category in bonus_map.keys():
			bonus_map[category] = bonus_map[category] / 2
#		now restore the correct one :P
		bonus_map[current_creep_category] = current_bonus

#	now set the correct race bonuses for this tower
	for category in bonus_map.keys():
		var ideal_bonus: float = 1.0 + bonus_map[category] / 1000.0
		var current_race_bonus: float = tower.get_damage_to_category(category)
		var mod_type: Modification.Type = CreepCategory.convert_to_mod_dmg_type(category)
		
		if ideal_bonus != current_race_bonus:
			var delta: float = ideal_bonus - current_race_bonus
			tower.modify_property(mod_type, delta)


func xeno_buff_towers(is_type_change: bool):
# 	NOTE: ignore challenge creeps
	if current_creep_category == CreepCategory.enm.CHALLENGE:
		return

	var buff_level: int = bonus_map[current_creep_category]
	prev_creep_category = current_creep_category

	var category_string = CreepCategory.convert_to_string(current_creep_category).capitalize()
	var category_color: Color = CreepCategory.get_color(current_creep_category)
	var floating_text: String = "%s Research Published" % category_string

	if (is_type_change && buff_level > 0) || force_show_research_message:
		tower.get_player().display_floating_text(floating_text, tower, category_color)
		force_show_research_message = false

	var category_to_bt: Dictionary = {
		CreepCategory.enm.UNDEAD: undead_bt,
		CreepCategory.enm.MAGIC: magic_bt,
		CreepCategory.enm.NATURE: nature_bt,
		CreepCategory.enm.ORC: orc_bt,
		CreepCategory.enm.HUMANOID: humanoid_bt,
		CreepCategory.enm.CHALLENGE: humanoid_bt,
	}
	var selected_buff: BuffType = category_to_bt[current_creep_category]

	xeno_manage_bonuses(is_type_change, buff_level)

	if buff_level <= 0:
		return

#	larger AoE needed as aura centre seems to be diff + collision problems
	var towers_in_aura: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 315)

	while true:
		var next_tower: Tower = towers_in_aura.next()

		if next_tower == null:
			break

		var tower_is_self: bool = next_tower == tower
		if tower_is_self:
			continue

		var tower_is_in_aura: bool = next_tower.get_buff_of_type(aura_bt) != null

		if tower_is_in_aura:
#			NOTE: divide by tower buff duration to force
#			duration to always be 6.5 seconds. (duration is
#			multiplied by tower buff duration during
#			apply()).
			var buff_duration: float = 6.5 / tower.get_prop_buff_duration()
			selected_buff.apply_custom_timed(tower, next_tower, buff_level, buff_duration)
