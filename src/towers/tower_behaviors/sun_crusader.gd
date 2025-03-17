extends TowerBehavior


# NOTE: changed buff types a bit. In original script they
# are two separate types, made it into one type which
# changes based on tier.


var crusader_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {blessed_weapon_damage = 500, for_the_god_effect = 0.40, for_the_god_effect_add = 0.01, for_the_god_level = 400, for_the_god_level_add = 10},
		2: {blessed_weapon_damage = 1000, for_the_god_effect = 0.80, for_the_god_effect_add = 0.02, for_the_god_level = 800, for_the_god_level_add = 20},
	}

const BLESSED_WEAPON_CHANCE: float = 0.15
const BLESSED_WEAPON_DAMAGE_ADD: float = 50
const BLESSED_WEAPON_MANA_GAIN: float = 2
const BLESSED_WEAPON_MANA_GAIN_ADD: float = 0.1
const FOR_THE_GOD_DURATION: float = 8.0
const FOR_THE_GOD_DURATION_ADD: float = 0.1


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	crusader_bt = BuffType.new("crusader_bt", FOR_THE_GOD_DURATION, FOR_THE_GOD_DURATION_ADD, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, _stats.for_the_god_effect, _stats.for_the_god_effect_add)
	mod.add_modification(Modification.Type.MOD_EXP_RECEIVED, _stats.for_the_god_effect, _stats.for_the_god_effect_add)
	crusader_bt.set_buff_modifier(mod)
	crusader_bt.set_buff_icon("res://resources/icons/generic_icons/angel_wings.tres")
	crusader_bt.set_buff_tooltip("For the God\nIncreases attack damage and experience gain.")


func on_damage(event: Event):
	if !tower.calc_chance(BLESSED_WEAPON_CHANCE):
		return

	CombatLog.log_ability(tower, event.get_target(), "Blessed Weapon")

	var damage: float = _stats.blessed_weapon_damage + BLESSED_WEAPON_DAMAGE_ADD * tower.get_level()
	var mana_gain: float = BLESSED_WEAPON_MANA_GAIN + BLESSED_WEAPON_MANA_GAIN_ADD * tower.get_level()

	Effect.create_simple_at_unit_attached("res://src/effects/holy_bolt.tscn", event.get_target(), Unit.BodyPart.CHEST)
	tower.do_spell_damage(event.get_target(), damage, tower.calc_spell_crit_no_bonus())
	tower.add_mana(mana_gain)


func on_autocast(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	crusader_bt.apply(tower, target, level)
