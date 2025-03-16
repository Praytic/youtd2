extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] changed autocast type
# AC_TYPE_ALWAYS_BUFF->AC_TYPE_ALWAYS_IMMEDIATE because the
# autocast is an AoE effect. Original script must have used
# AC_TYPE_ALWAYS_BUFF by mistake.


var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {replenish_mana = 0.10, replenish_mana_add = 0.004, mod_spell_dmg = 0.15, mod_spell_dmg_add = 0.006},
		2: {replenish_mana = 0.15, replenish_mana_add = 0.006, mod_spell_dmg = 0.20, mod_spell_dmg_add = 0.008},
		3: {replenish_mana = 0.20, replenish_mana_add = 0.008, mod_spell_dmg = 0.25, mod_spell_dmg_add = 0.010},
	}

const AURA_RANGE: float = 200
const REPLENISH_RANGE: float = 500


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.20, 0.008)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, _stats.mod_spell_dmg, _stats.mod_spell_dmg_add)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/atomic_slashes.tres")
	aura_bt.set_buff_tooltip("Cleansing Water Aura\nIncreases spell damage.")


func create_autocasts_DELETEME() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var replenish_range: String = Utils.format_float(REPLENISH_RANGE, 2)
	var replenish_mana: String = Utils.format_percent(_stats.replenish_mana, 2)
	var replenish_mana_add: String = Utils.format_percent(_stats.replenish_mana_add, 2)

	autocast.title = "Replenish"
	autocast.icon = "res://resources/icons/plants/flower_01.tres"
	autocast.description_short = "Restores mana of nearby towers.\n"
	autocast.description = "Restores %s of each towers maximum mana for towers in %s range. Restores only half the amount for towers of the same family.\n" % [replenish_mana, replenish_range] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s maximum mana\n" % replenish_mana_add
	autocast.caster_art = "res://src/effects/replenish_mana.tscn"
	autocast.target_art = "res://src/effects/spell_aima.tscn"
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = REPLENISH_RANGE
	autocast.auto_range = REPLENISH_RANGE
	autocast.cooldown = 5
	autocast.mana_cost = 200
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.buff_target_type = null
	autocast.handler = on_autocast

	return [autocast]


func get_aura_types_DELETEME() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var mod_spell_dmg: String = Utils.format_percent(_stats.mod_spell_dmg, 2)
	var mod_spell_dmg_add: String = Utils.format_percent(_stats.mod_spell_dmg_add, 2)

	aura.name = "Cleansing Water"
	aura.icon = "res://resources/icons/orbs/orb_ice.tres"
	aura.description_short = "Increases spell damage dealt by nearby towers.\n"
	aura.description_full = "Increases the spell damage dealt by all towers in %d range by %s.\n" % [AURA_RANGE, mod_spell_dmg] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage\n" % mod_spell_dmg_add

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = aura_bt
	return [aura]


func on_autocast(_event: Event):
	var towers_in_range: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 500)
	var mana_gain_ratio: float = _stats.replenish_mana + _stats.replenish_mana_add * tower.get_level()

	while true:
		var target: Unit = towers_in_range.next()

		if target == null:
			break

		var is_same_family: bool = target.get_family() == tower.get_family()

		var replenish_mana: float
		if is_same_family:
			replenish_mana = target.get_overall_mana() * mana_gain_ratio * 0.5
		else:
			replenish_mana = target.get_overall_mana() * mana_gain_ratio

		target.add_mana(replenish_mana)
