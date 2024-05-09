extends TowerBehavior


var aura_bt : BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_spell_crit = 0.10, aura_level = 0},
		2: {mod_spell_crit = 0.15, aura_level = 50},
		3: {mod_spell_crit = 0.20, aura_level = 100},
	}


const AURA_RANGE: float = 500.0
const MOD_SPELL_CRIT_ADD: float = 0.002



func get_ability_info_list() -> Array[AbilityInfo]:
	var mod_spell_crit: String = Utils.format_percent(_stats.mod_spell_crit, 2)
	var mod_spell_crit_add: String = Utils.format_percent(MOD_SPELL_CRIT_ADD, 2)
	var aura_range: String = Utils.format_float(AURA_RANGE, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Ancient Magic - Aura"
	ability.icon = "res://Resources/Icons/TowerIcons/LightningEye.tres"
	ability.description_short = "Increases spell crit chance of nearby towers.\n"
	ability.description_full = "Increases spell crit chance of towers in %s range by %s.\n" % [aura_range, mod_spell_crit] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell crit chance\n" % mod_spell_crit_add
	list.append(ability)

	return list


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.10, 0.001)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://Resources/Icons/GenericIcons/polar_star.tres")
	aura_bt.set_stacking_group("aura_bt")
	aura_bt.set_buff_tooltip("Ancient Magic\nIncreases spell crit chance.")

	
func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = false
	aura.level = _stats.aura_level
	aura.level_add = 2
	aura.power = _stats.aura_level
	aura.power_add = 2
	aura.aura_effect = aura_bt
	return [aura]
