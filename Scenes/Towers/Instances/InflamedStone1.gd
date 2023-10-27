extends Tower


# NOTE: fixed bug in original script. The buffs which tower
# applied onto itself were unfriendly, changed them to
# friendly. These buffs are permanent though so they are
# invisible so doesn't matter much.

# NOTE: had to adjust how buff levels are calculated a bit
# to account for differences in how stats start from 0.0 vs
# 1.0 in original youtd vs youtd2.


var spell_flame_damage_bt: BuffType
var spell_flame_crit_damage_bt: BuffType
var spell_flame_crit_chance_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {spellfire_ratio = 0.84, spellfire_ratio_add = 0.0336, extra_crit_dmg_per_mana = 0.08, mana_threshold_add = 0.20},
		2: {spellfire_ratio = 0.90, spellfire_ratio_add = 0.0360, extra_crit_dmg_per_mana = 0.09, mana_threshold_add = 0.25},
		3: {spellfire_ratio = 1.00, spellfire_ratio_add = 0.0400, extra_crit_dmg_per_mana = 0.10, mana_threshold_add = 0.30},
	}


const MANA_THRESHOLD_BASE: float = 20


func get_ability_description() -> String:
	var spellfire_ratio: String = Utils.format_percent(_stats.spellfire_ratio, 2)
	var spellfire_ratio_add: String = Utils.format_percent(_stats.spellfire_ratio_add, 2)
	var mana_threshold_base: String = Utils.format_float(MANA_THRESHOLD_BASE, 2)
	var mana_threshold_add: String = Utils.format_float(_stats.mana_threshold_add, 2)
	var extra_crit_dmg_per_mana: String = Utils.format_percent(_stats.extra_crit_dmg_per_mana, 2)

	var text: String = ""

	text += "[color=GOLD]Spellfire[/color]\n"
	text += "This tower treats all spell modifiers as attack bonuses, with an %s bonus gain of stated effect. This is recalculated before every attack.\n" % spellfire_ratio
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s bonus gain\n" % spellfire_ratio_add
	text += " \n"
	text += "[color=GOLD]Spellfire Projectiles[/color]\n"
	text += "If this tower has at least %s mana when it attacks, it will pay all its mana to proc a critical strike. %s Mana is used to grant the critical strike and every further point of mana spent grants %s more critical damage to that attack.\n" % [mana_threshold_base, mana_threshold_base, extra_crit_dmg_per_mana]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "-%s Mana needed\n" % mana_threshold_add
	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.0, 0.02)


func tower_init():
	spell_flame_damage_bt = BuffType.new("spell_flame_damage_bt", -1, 0, true, self)
	var spell_flame_damage_mod: Modifier = Modifier.new()
	spell_flame_damage_mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, 0.01)
	spell_flame_damage_bt.set_buff_modifier(spell_flame_damage_mod)

	spell_flame_crit_chance_bt = BuffType.new("spell_flame_crit_chance_bt", -1, 0, true, self)
	var spell_flame_crit_chance_mod: Modifier = Modifier.new()
	spell_flame_crit_chance_mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.0, 0.01)
	spell_flame_crit_chance_bt.set_buff_modifier(spell_flame_crit_chance_mod)

	spell_flame_crit_damage_bt = BuffType.new("spell_crit_damage_bt", -1, 0, true, self)
	var spell_crit_damage_mod: Modifier = Modifier.new()
	spell_crit_damage_mod.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.0, 0.01)
	spell_flame_crit_damage_bt.set_buff_modifier(spell_crit_damage_mod)


func on_attack(_event: Event):
	var tower: Tower = self

#	Spellfire
	var lvl: int = tower.get_level()
	var buff_level_multiplier: float = (_stats.spellfire_ratio + _stats.spellfire_ratio_add * lvl) * 100
	var spell_damage_level: int = int((tower.get_prop_spell_damage_dealt() - 1.0) * buff_level_multiplier)
	var spell_crit_damage_level: int = int((tower.get_spell_crit_damage() - 1.0) * buff_level_multiplier)
	var spell_crit_chance_level: int = int(tower.get_spell_crit_chance() * buff_level_multiplier)

	spell_flame_damage_bt.apply(tower, tower, spell_damage_level)
	spell_flame_crit_damage_bt.apply(tower, tower, spell_crit_damage_level)
	spell_flame_crit_chance_bt.apply(tower, tower, spell_crit_chance_level)

#	Spellfire Projectiles
	var mana: float = tower.get_mana()
	var mana_threshold: float = MANA_THRESHOLD_BASE - _stats.mana_threshold_add * tower.get_level()
	var extra_crit: bool = mana > mana_threshold
	var custom_crit_ratio: float = tower.get_prop_atk_crit_damage() + (mana - mana_threshold) * _stats.extra_crit_dmg_per_mana

	if extra_crit:
		tower.subtract_mana(mana, false)
		tower.add_custom_attack_crit(custom_crit_ratio)
