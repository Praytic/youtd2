extends Tower


# NOTE: made made changes to original script but overall
# it's the same logic.

# NOTE: original script doesn't behave according to
# description. It only applies the "mod dmg to category"
# buff to neighbor towers for the current attack category.
# This means that when category changes and the 6.5s buff
# duration expires, neighbor towers will only have bonus for
# current category. Reimplemented as is but should think
# about maybe fixing this.


var palandu_xeno_aura_bt: BuffType
var palandu_xeno_undead_bt: BuffType
var palandu_xeno_magic_bt: BuffType
var palandu_xeno_nature_bt: BuffType
var palandu_xeno_orc_bt: BuffType
var palandu_xeno_humanoid_bt: BuffType


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
}


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Sample Collection[/color]\n"
	text += "Has a 25% chance to collect a tissue sample from a damaged creep. Once researched, it will provide a 5% bonus vs the race of that creep, through the Xeno Vulnerability Research aura. Maximum bonus per race is 25%. Whenever a different race is attacked, half of the research bonuses against all other races are lost.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1% chance to collect sample\n"
	text += "+1% maximum bonus per race\n"
	text += " \n"
	text += "[color=GOLD]Xeno Vulnerability Research - Aura[/color]\n"
	text += "Improves damage vs various creep races for all towers in 280 range. Improvement amount depends on the Sample Collection. Research results are published every 6 seconds and whenever a different race is attacked. Stops working in the Bonus Level."
	text += " \n"
	text += "[color=GOLD]Note:[/color] For this tower, research overrides any and all other race modifications. So the race bonuses of this tower reflect the bonuses given by this aura.\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Sample Collection[/color]\n"
	text += "Has a chance to collect a tissue sample from a damaged creep. Once researched, it will provide a bonus vs the race of that creep to nearby towers.\n"
	text += " \n"
	text += "[color=GOLD]Xeno Vulnerability Research - Aura[/color]\n"
	text += "Improves damage vs various creep races for all towers in range. Improvement amount depends on the Sample Collection. Stops working in the Bonus Level."
	text += " \n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 6.0)


func tower_init():
	palandu_xeno_undead_bt = BuffType.new("palandu_xeno_undead_bt", 1, 0, true, self)
	var palandu_xeno_undead_mod: Modifier = Modifier.new()
	palandu_xeno_undead_mod.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.0, 0.001)
	palandu_xeno_undead_bt.set_buff_modifier(palandu_xeno_undead_mod)

	palandu_xeno_magic_bt = BuffType.new("palandu_xeno_magic_bt", 1, 0, true, self)
	var palandu_xeno_magic_mod: Modifier = Modifier.new()
	palandu_xeno_magic_mod.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, 0.0, 0.001)
	palandu_xeno_magic_bt.set_buff_modifier(palandu_xeno_magic_mod)

	palandu_xeno_nature_bt = BuffType.new("palandu_xeno_nature_bt", 1, 0, true, self)
	var palandu_xeno_nature_mod: Modifier = Modifier.new()
	palandu_xeno_nature_mod.add_modification(Modification.Type.MOD_DMG_TO_NATURE, 0.0, 0.001)
	palandu_xeno_nature_bt.set_buff_modifier(palandu_xeno_nature_mod)

	palandu_xeno_orc_bt = BuffType.new("palandu_xeno_orc_bt", 1, 0, true, self)
	var palandu_xeno_orc_mod: Modifier = Modifier.new()
	palandu_xeno_orc_mod.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.0, 0.001)
	palandu_xeno_orc_bt.set_buff_modifier(palandu_xeno_orc_mod)

	palandu_xeno_humanoid_bt = BuffType.new("palandu_xeno_humanoid_bt", 1, 0, true, self)
	var palandu_xeno_humanoid_mod: Modifier = Modifier.new()
	palandu_xeno_humanoid_mod.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.0, 0.001)
	palandu_xeno_humanoid_bt.set_buff_modifier(palandu_xeno_humanoid_mod)

	palandu_xeno_aura_bt = BuffType.create_aura_effect_type("palandu_xeno_aura_bt", true, self)
	palandu_xeno_aura_bt.set_buff_icon("@@0@@")
	palandu_xeno_aura_bt.set_buff_tooltip("Xeno Research\nThis tower is enhanced by a nearby Xeno Research Facility.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 280
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 1
	aura.level_add = 1
	aura.power = 1
	aura.power_add = 1
	aura.aura_effect = palandu_xeno_aura_bt
	add_aura(aura)


func on_attack(event: Event):
	if bonus_levels_in_progress:
		return

	var creep: Creep = event.get_target()
	var creep_category: CreepCategory.enm = creep.get_category() as CreepCategory.enm

	if creep.get_spawn_level() > Utils.get_max_level():
		bonus_levels_in_progress = true

	current_creep_category = creep_category

	var is_type_change: bool = current_creep_category != prev_creep_category
	if is_type_change:
		xeno_buff_towers(true)


func on_damage(event: Event):
	if bonus_levels_in_progress:
		return
	
	var tower: Tower = self
	var creep: Creep = event.get_target()
	var creep_category: CreepCategory.enm = creep.get_category() as CreepCategory.enm
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

	tower.get_player().display_small_floating_text("Sample Collected", creep, 200, 200, 200, 40.0)
	var new_bonus: int = min(current_bonus + 50, bonus_max)
	bonus_map[creep_category] = new_bonus
	force_show_research_message = true


func periodic(_event: Event):
	if !bonus_levels_in_progress:
		xeno_buff_towers(current_creep_category != prev_creep_category)


func xeno_manage_bonuses(is_type_change: bool, current_bonus: int):
	var tower: Tower = self

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
	var tower: Tower = self

	var power_level: int = bonus_map[current_creep_category]
	prev_creep_category = current_creep_category

# 	NOTE: ignore challenge creeps
	if current_creep_category == CreepCategory.enm.CHALLENGE:
		return

	var category_string = CreepCategory.convert_to_string(current_creep_category).capitalize()
	var category_color: Color = CreepCategory.get_color(current_creep_category)
	var floating_text: String = "%s Research Published" % category_string

	if (is_type_change && power_level > 0) || force_show_research_message:
		tower.get_player().display_floating_text_color(floating_text, tower, category_color, 1.0)
		force_show_research_message = false

	var category_to_bt: Dictionary = {
		CreepCategory.enm.UNDEAD: palandu_xeno_undead_bt,
		CreepCategory.enm.MAGIC: palandu_xeno_magic_bt,
		CreepCategory.enm.NATURE: palandu_xeno_nature_bt,
		CreepCategory.enm.ORC: palandu_xeno_orc_bt,
		CreepCategory.enm.HUMANOID: palandu_xeno_humanoid_bt,
	}
	var selected_buff: BuffType = category_to_bt[current_creep_category]

	xeno_manage_bonuses(is_type_change, power_level)

	if power_level <= 0:
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

		var tower_is_in_aura: bool = next_tower.get_buff_of_type(palandu_xeno_aura_bt) != null

		if tower_is_in_aura:
#			always 8.5 secs (comment from original script, no idea what it means)
			var buff_duration: float = 6.5 / tower.get_prop_buff_duration()
			selected_buff.apply_advanced(tower, next_tower, power_level, power_level, buff_duration)
