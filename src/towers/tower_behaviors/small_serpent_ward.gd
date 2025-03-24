extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUFF] Changed autocast.buff_type
# (null->charm_bt). This fixes issue where tower would
# rebuff a unit which is already buffed.


var charm_bt: BuffType


const BUFF_DURATION: float = 5.0
const BUFF_DURATION_BONUS_AT_25: float = 5.0


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_mana = 0.10, mod_mana_add = 0.006, mod_mana_regen = 0.10, mod_mana_regen_add = 0.006, mod_spell_damage = 0.05, mod_spell_damage_add = 0.003},
		2: {mod_mana = 0.20, mod_mana_add = 0.012, mod_mana_regen = 0.20, mod_mana_regen_add = 0.012, mod_spell_damage = 0.10, mod_spell_damage_add = 0.006},
		3: {mod_mana = 0.30, mod_mana_add = 0.018, mod_mana_regen = 0.30, mod_mana_regen_add = 0.018, mod_spell_damage = 0.15, mod_spell_damage_add = 0.009},
		4: {mod_mana = 0.40, mod_mana_add = 0.024, mod_mana_regen = 0.40, mod_mana_regen_add = 0.024, mod_spell_damage = 0.20, mod_spell_damage_add = 0.012},
	}


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_MANA_PERC, _stats.mod_mana, _stats.mod_mana_add)
	m.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, _stats.mod_mana_regen, _stats.mod_mana_regen_add)
	m.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, _stats.mod_spell_damage, _stats.mod_spell_damage_add)
	charm_bt = BuffType.new("charm_bt", 0, 0, true, self)
	charm_bt.set_buff_icon("res://resources/icons/generic_icons/charm.tres")
	charm_bt.set_buff_modifier(m)
	charm_bt.set_buff_tooltip(tr("YNTO"))


func on_autocast(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	var duration: float = BUFF_DURATION
	if level == 25:
		duration += BUFF_DURATION_BONUS_AT_25

	charm_bt.apply_custom_timed(tower, target, level, duration)
