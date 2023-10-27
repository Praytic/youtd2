extends Tower


var boekie_spell_crit_aura : BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_spell_crit = 0.10, aura_level = 0},
		2: {mod_spell_crit = 0.15, aura_level = 50},
		3: {mod_spell_crit = 0.20, aura_level = 100},
	}


const AURA_RANGE: float = 500.0
const MOD_SPELL_CRIT_ADD: float = 0.002


func get_ability_description() -> String:
	var mod_spell_crit: String = Utils.format_percent(_stats.mod_spell_crit, 2)
	var mod_spell_crit_add: String = Utils.format_percent(MOD_SPELL_CRIT_ADD, 2)
	var aura_range: String = Utils.format_float(AURA_RANGE, 2)

	var text: String = ""

	text += "[color=GOLD]Ancient Magic - Aura[/color]\n"
	text += "Increases spell crit chance of towers in %s range by %s. \n" % [aura_range, mod_spell_crit]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s spell crit chance\n" % mod_spell_crit_add

	return text


func tower_init():
	boekie_spell_crit_aura = BuffType.create_aura_effect_type("boekie_spell_crit_aura", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.10, 0.001)
	boekie_spell_crit_aura.set_buff_modifier(mod)
	boekie_spell_crit_aura.set_buff_icon("@@0@@")
	boekie_spell_crit_aura.set_stacking_group("boekie_spell_crit_aura")
	boekie_spell_crit_aura.set_buff_tooltip("Ancient Magic\nThis tower is under the effect of Ancient Magic Aura; it has increase spell crit chance.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = false
	aura.level = _stats.aura_level
	aura.level_add = 2
	aura.power = _stats.aura_level
	aura.power_add = 2
	aura.aura_effect = boekie_spell_crit_aura
	add_aura(aura)
