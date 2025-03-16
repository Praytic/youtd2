extends TowerBehavior


var slow_bt: BuffType
var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {cursed_attack_damage = 200, cursed_attack_damage_add = 10, mod_movespeed = 0.20, mod_spell_dmg_received = 0.100, aura_effect = 0.10, aura_effect_add = 0.004},
		2: {cursed_attack_damage = 320, cursed_attack_damage_add = 16, mod_movespeed = 0.25, mod_spell_dmg_received = 0.125, aura_effect = 0.15, aura_effect_add = 0.006},
		3: {cursed_attack_damage = 560, cursed_attack_damage_add = 28, mod_movespeed = 0.30, mod_spell_dmg_received = 0.150, aura_effect = 0.20, aura_effect_add = 0.008},
	}

const CURSED_ATTACK_CHANCE: float = 0.25
const CURSED_ATTACK_CHANCE_ADD: float = 0.01
const CURSED_DURATION: float = 4
const CURSED_DURATION_ADD: float = 0.1
const AURA_RANGE: float = 350


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var cursed_attack_chance: String = Utils.format_percent(CURSED_ATTACK_CHANCE, 2)
	var cursed_attack_chance_add: String = Utils.format_percent(CURSED_ATTACK_CHANCE_ADD, 2)
	var cursed_attack_damage: String = Utils.format_float(_stats.cursed_attack_damage, 2)
	var cursed_attack_damage_add: String = Utils.format_float(_stats.cursed_attack_damage_add, 2)
	var cursed_duration: String = Utils.format_float(CURSED_DURATION, 2)
	var cursed_duration_add: String = Utils.format_float(CURSED_DURATION_ADD, 2)
	var mod_movespeed: String = Utils.format_percent(_stats.mod_movespeed, 2)
	var mod_spell_dmg_received: String = Utils.format_percent(_stats.mod_spell_dmg_received, 2)

	var list: Array[AbilityInfo] = []
	
	var cursed_attack: AbilityInfo = AbilityInfo.new()
	cursed_attack.name = "Cursed Attack"
	cursed_attack.icon = "res://resources/icons/undead/skull_wand_02.tres"
	cursed_attack.description_short = "Chance to deal additional spell damage to hit creeps and weaken them, reducing movement speed and increasing spell damage received.\n"
	cursed_attack.description_full = "%s chance to deal %s additional spell damage to hit creeps and weaken them for %s seconds, reducing movement speed by %s and increasing spell damage received by %s.\n" % [cursed_attack_chance, cursed_attack_damage, cursed_duration, mod_movespeed, mod_spell_dmg_received] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s chance\n" % cursed_attack_chance_add \
	+ "+%s spell damage\n" % cursed_attack_damage_add \
	+ "+%s sec slow duration\n" % cursed_duration_add
	list.append(cursed_attack)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	tower.set_attack_style_bounce(4, 0.3)


func tower_init():
	slow_bt = BuffType.new("slow_bt", CURSED_DURATION, CURSED_DURATION_ADD, false, self)
	var slow_bt_mod: Modifier = Modifier.new()
	slow_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, -_stats.mod_movespeed, 0)
	slow_bt_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, _stats.mod_spell_dmg_received, 0)
	slow_bt.set_buff_modifier(slow_bt_mod)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/alien_skull.tres")
	slow_bt.set_buff_tooltip("Cursed Attack\nReduces movement speed and increases spell damage taken.")

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var aura_bt_mod: Modifier = Modifier.new()
	aura_bt_mod.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, _stats.aura_effect, _stats.aura_effect_add)
	aura_bt_mod.add_modification(Modification.Type.MOD_DMG_TO_ORC, _stats.aura_effect, _stats.aura_effect_add)
	aura_bt_mod.add_modification(Modification.Type.MOD_DMG_TO_NATURE, _stats.aura_effect, _stats.aura_effect_add)
	aura_bt.set_buff_modifier(aura_bt_mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/over_infinity.tres")
	aura_bt.set_buff_tooltip("Mortal Coil Aura\nIncreases damage dealt against Human, Orc and Nature creeps.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var aura_effect: String = Utils.format_percent(_stats.aura_effect, 2)
	var aura_effect_add: String = Utils.format_percent(_stats.aura_effect_add, 2)
	var human_string: String = CreepCategory.convert_to_colored_string(CreepCategory.enm.HUMANOID)
	var orc_string: String = CreepCategory.convert_to_colored_string(CreepCategory.enm.ORC)
	var nature_string: String = CreepCategory.convert_to_colored_string(CreepCategory.enm.NATURE)

	aura.name = "Mortal Coil"
	aura.icon = "res://resources/icons/undead/demon_emblem.tres"
	aura.description_short = "Grants bonus damage against %s, %s and %s creeps to nearby towers.\n" % [human_string, orc_string, nature_string]
	aura.description_full = "Grants %s bonus damage against %s, %s and %s creeps to all towers within %d range.\n" % [aura_effect, human_string, orc_string, nature_string, AURA_RANGE] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage\n" % aura_effect_add

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = aura_bt
	return [aura]


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	var cursed_attack_chance: float = CURSED_ATTACK_CHANCE + CURSED_ATTACK_CHANCE_ADD * level

	if !tower.calc_chance(cursed_attack_chance):
		return

	if !target.is_immune():
		CombatLog.log_ability(tower, target, "Cursed Attack")

		var damage: float = _stats.cursed_attack_damage + _stats.cursed_attack_damage_add * level
		tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())

		slow_bt.apply(tower, target, level)
		Effect.create_simple_at_unit("res://src/effects/spell_aima.tscn", target)
