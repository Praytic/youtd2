extends Tower


var regen_well_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {replenish_mana = 0.10, replenish_mana_add = 0.004, mod_spell_dmg = 0.15, mod_spell_dmg_add = 0.006},
		2: {replenish_mana = 0.15, replenish_mana_add = 0.006, mod_spell_dmg = 0.20, mod_spell_dmg_add = 0.008},
		3: {replenish_mana = 0.20, replenish_mana_add = 0.008, mod_spell_dmg = 0.25, mod_spell_dmg_add = 0.010},
	}

const AURA_RANGE: float = 200
const REPLENISH_RANGE: float = 500


func get_ability_description() -> String:
	var aura_range: String = Utils.format_float(AURA_RANGE, 2)
	var mod_spell_dmg: String = Utils.format_percent(_stats.mod_spell_dmg, 2)
	var mod_spell_dmg_add: String = Utils.format_percent(_stats.mod_spell_dmg_add, 2)

	var text: String = ""

	text += "[color=GOLD]Cleansing Water - Aura[/color]\n"
	text += "Increases the spell damage dealt by all towers in %s range by %s.\n" % [aura_range, mod_spell_dmg]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s spell damage\n" % mod_spell_dmg_add

	return text


func get_autocast_description() -> String:
	var replenish_range: String = Utils.format_float(REPLENISH_RANGE, 2)
	var replenish_mana: String = Utils.format_percent(_stats.replenish_mana, 2)
	var replenish_mana_add: String = Utils.format_percent(_stats.replenish_mana_add, 2)

	var text: String = ""

	text += "Restores %s (only half on towers of this family) of each towers maximum mana for towers in %s range.\n" % [replenish_mana, replenish_range]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s maximum mana\n" % replenish_mana_add

	return text


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.20, 0.008)


func tower_init():
	regen_well_bt = BuffType.create_aura_effect_type("regen_well_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.0, 0.001)
	regen_well_bt.set_buff_modifier(mod)
	regen_well_bt.set_buff_icon("@@0@@")
	regen_well_bt.set_buff_tooltip("Cleansing Water Aura\nThis tower is under the effect of Cleansing Water Aura; it deals extra spell damage.")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Replenish"
	autocast.description = get_autocast_description()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = "ReplenishManaCasterOverhead.mdl"
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = REPLENISH_RANGE
	autocast.auto_range = REPLENISH_RANGE
	autocast.cooldown = 5
	autocast.mana_cost = 200
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = regen_well_bt
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast
	add_autocast(autocast)

	var aura_level: int = int(_stats.mod_spell_dmg * 1000)
	var aura_level_add: int = int(_stats.mod_spell_dmg_add * 1000)

	var aura: AuraType = AuraType.new()
	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = aura_level
	aura.level_add = aura_level_add
	aura.power = aura_level
	aura.power_add = aura_level_add
	aura.aura_effect = regen_well_bt
	add_aura(aura)


func on_autocast(_event: Event):
	var tower: Tower = self
	var towers_in_range: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 500)
	var mana_gain_ratio: float = _stats.replenish_mana + _stats.replenish_mana_add * tower.get_level()

	while true:
		var target: Unit = towers_in_range.next()

		if target == null:
			break

		var is_same_family: bool = target.get_family() == tower.get_family()

		var replenish_mana: float
		if is_same_family:
			replenish_mana = target.get_mana() * mana_gain_ratio * 0.5
		else:
			replenish_mana = target.get_mana() * mana_gain_ratio

		target.add_mana(replenish_mana)
