extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] Fixed minor bug in original
# script. The buffs which tower applied onto itself were
# unfriendly. Fixed them to be friendly. This bug doesn't
# matter that much because the buffs are permanent and
# invisible.

# NOTE: had to adjust how buff levels are calculated a bit
# to account for differences in how stats start from 0.0 vs
# 1.0 in original youtd vs youtd2.


var damage_bt: BuffType
var crit_damage_bt: BuffType
var crit_chance_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {spellfire_ratio = 0.84, spellfire_ratio_add = 0.0336, extra_crit_dmg_per_mana = 0.08, mana_threshold_add = 0.20},
		2: {spellfire_ratio = 0.90, spellfire_ratio_add = 0.0360, extra_crit_dmg_per_mana = 0.09, mana_threshold_add = 0.25},
		3: {spellfire_ratio = 1.00, spellfire_ratio_add = 0.0400, extra_crit_dmg_per_mana = 0.10, mana_threshold_add = 0.30},
	}


const MANA_THRESHOLD_BASE: float = 20


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	damage_bt = BuffType.new("damage_bt", -1, 0, true, self)
	var spell_flame_damage_mod: Modifier = Modifier.new()
	spell_flame_damage_mod.add_modification(ModificationType.enm.MOD_DAMAGE_ADD_PERC, 0.0, 0.01)
	damage_bt.set_buff_modifier(spell_flame_damage_mod)
	damage_bt.set_hidden()

	crit_chance_bt = BuffType.new("crit_chance_bt", -1, 0, true, self)
	var spell_flame_crit_chance_mod: Modifier = Modifier.new()
	spell_flame_crit_chance_mod.add_modification(ModificationType.enm.MOD_ATK_CRIT_CHANCE, 0.0, 0.01)
	crit_chance_bt.set_buff_modifier(spell_flame_crit_chance_mod)
	crit_chance_bt.set_hidden()

	crit_damage_bt = BuffType.new("spell_crit_damage_bt", -1, 0, true, self)
	var spell_crit_damage_mod: Modifier = Modifier.new()
	spell_crit_damage_mod.add_modification(ModificationType.enm.MOD_ATK_CRIT_DAMAGE, 0.0, 0.01)
	crit_damage_bt.set_buff_modifier(spell_crit_damage_mod)
	crit_damage_bt.set_hidden()


func on_attack(_event: Event):
#	Spellfire
	var lvl: int = tower.get_level()
	var buff_level_multiplier: float = (_stats.spellfire_ratio + _stats.spellfire_ratio_add * lvl) * 100
	var spell_damage_level: int = int((tower.get_prop_spell_damage_dealt() - 1.0) * buff_level_multiplier)
	var spell_crit_damage_level: int = int((tower.get_spell_crit_damage() - 1.0) * buff_level_multiplier)
	var spell_crit_chance_level: int = int(tower.get_spell_crit_chance() * buff_level_multiplier)

	damage_bt.apply(tower, tower, spell_damage_level)
	crit_damage_bt.apply(tower, tower, spell_crit_damage_level)
	crit_chance_bt.apply(tower, tower, spell_crit_chance_level)

#	Spellfire Projectiles
	var mana: float = tower.get_mana()
	var mana_threshold: float = MANA_THRESHOLD_BASE - _stats.mana_threshold_add * tower.get_level()
	var extra_crit: bool = mana > mana_threshold
	var custom_crit_ratio: float = tower.get_prop_atk_crit_damage() + (mana - mana_threshold) * _stats.extra_crit_dmg_per_mana

	if extra_crit:
		CombatLog.log_ability(tower, null, "Spellfire Projectiles")

		tower.subtract_mana(mana, false)
		tower.add_custom_attack_crit(custom_crit_ratio)
