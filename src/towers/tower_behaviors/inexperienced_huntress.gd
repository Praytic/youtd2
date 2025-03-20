extends TowerBehavior


var glaive_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {shadow_glaive_crit_bonus = 0.25, shadow_glaive_crit_bonus_add = 0.01, star_glaive_dmg_ratio = 0.25},
		2: {shadow_glaive_crit_bonus = 0.50, shadow_glaive_crit_bonus_add = 0.02, star_glaive_dmg_ratio = 0.35},
		3: {shadow_glaive_crit_bonus = 0.75, shadow_glaive_crit_bonus_add = 0.03, star_glaive_dmg_ratio = 0.45},
	}


const SHADOW_GLAIVE_CHANCE: float = 0.20
const SHADOW_GLAIVE_CHANCE_ADD: float = 0.008
const SHADOW_GLAIVE_ATTACK_SPEED: float = 2.0
const SHADOW_GLAIVE_ATTACK_SPEED_ADD: float = 0.08
const STAR_GLAIVE_CHANCE: float = 0.25
const STAR_GLAIVE_CHANCE_ADD: float = 0.004
const STAR_GLAIVE_DMG_RATIO_ADD: float = 0.01


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	glaive_bt = BuffType.new("glaive_bt", 99, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, SHADOW_GLAIVE_ATTACK_SPEED, SHADOW_GLAIVE_ATTACK_SPEED_ADD)
	glaive_bt.set_buff_modifier(mod)
	glaive_bt.set_buff_icon("res://resources/icons/generic_icons/pisces.tres")
	glaive_bt.set_buff_tooltip("Shadow Glaive\nNext attack will be faster and will always be critical.")


func on_attack(_event: Event):
	var buff: Buff = tower.get_buff_of_type(glaive_bt)
	var crit_damage_multiply: float = 1.0 + _stats.shadow_glaive_crit_bonus + _stats.shadow_glaive_crit_bonus_add * tower.get_level()
	var shadow_glaive_chance: float = SHADOW_GLAIVE_CHANCE + SHADOW_GLAIVE_CHANCE_ADD * tower.get_level()

	if buff != null:
		tower.add_modified_attack_crit(0.0, crit_damage_multiply)
		buff.remove_buff()

	if !tower.calc_chance(shadow_glaive_chance):
		return

	CombatLog.log_ability(tower, null, "Shadow Glaive")

	glaive_bt.apply(tower, tower, tower.get_level())


func on_damage(event: Event):
	var star_glaive_chance: float = STAR_GLAIVE_CHANCE + STAR_GLAIVE_CHANCE_ADD * tower.get_level()
	var stair_glaive_damage: float = event.damage * (_stats.star_glaive_dmg_ratio + STAR_GLAIVE_DMG_RATIO_ADD * tower.get_level())

	if !tower.calc_chance(star_glaive_chance):
		return

	CombatLog.log_ability(tower, event.get_target(), "Star Glaive")

	tower.do_spell_damage(event.get_target(), stair_glaive_damage, tower.calc_spell_crit_no_bonus())
	Effect.create_simple_at_unit("res://src/effects/starfall_target.tscn", event.get_target())
