extends TowerBehavior


# NOTE: changed buff types a bit. In original script they
# are two separate types, made it into one type which
# changes based on tier.


var crusader_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_dmg_to_undead = 0.5, blessed_weapon_damage = 500, for_the_god_effect = 0.40, for_the_god_effect_add = 0.01, for_the_god_level = 400, for_the_god_level_add = 10},
		2: {mod_dmg_to_undead = 1.0, blessed_weapon_damage = 1000, for_the_god_effect = 0.80, for_the_god_effect_add = 0.02, for_the_god_level = 800, for_the_god_level_add = 20},
	}

const BLESSED_WEAPON_CHANCE: float = 0.15
const BLESSED_WEAPON_DAMAGE_ADD: float = 50
const BLESSED_WEAPON_MANA_GAIN: float = 2
const BLESSED_WEAPON_MANA_GAIN_ADD: float = 0.1
const FOR_THE_GOD_DURATION: float = 8.0
const FOR_THE_GOD_DURATION_ADD: float = 0.1


func get_ability_info_list() -> Array[AbilityInfo]:
	var blessed_weapon_chance: String = Utils.format_percent(BLESSED_WEAPON_CHANCE, 2)
	var blessed_weapon_mana_gain: String = Utils.format_float(BLESSED_WEAPON_MANA_GAIN, 2)
	var blessed_weapon_mana_gain_add: String = Utils.format_float(BLESSED_WEAPON_MANA_GAIN_ADD, 2)
	var blessed_weapon_damage: String = Utils.format_float(_stats.blessed_weapon_damage, 2)
	var blessed_weapon_damage_add: String = Utils.format_float(BLESSED_WEAPON_DAMAGE_ADD, 2)
	
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Blessed Weapon"
	ability.icon = "res://resources/icons/holy/cross_01.tres"
	ability.description_short = "Whenever this tower hits a creep, it has a chance a chance to deal spell damage to the creep and restore mana.\n"
	ability.description_full = "Whenever this tower hits a creep, it has a chance a %s chance to deal %s spell damage to the creep and restore %s mana.\n" % [blessed_weapon_chance, blessed_weapon_damage, blessed_weapon_mana_gain] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage\n" % blessed_weapon_damage_add \
	+ "+%s mana regeneration\n" % blessed_weapon_mana_gain_add
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	tower.set_attack_ground_only()
	tower.set_attack_style_bounce(5, 0.1)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, _stats.mod_dmg_to_undead, 0.0)
	modifier.add_modification(Modification.Type.MOD_MANA, 0, 1)


func tower_init():
	crusader_bt = BuffType.new("crusader_bt", FOR_THE_GOD_DURATION, FOR_THE_GOD_DURATION_ADD, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, _stats.for_the_god_effect, _stats.for_the_god_effect_add)
	mod.add_modification(Modification.Type.MOD_EXP_RECEIVED, _stats.for_the_god_effect, _stats.for_the_god_effect_add)
	crusader_bt.set_buff_modifier(mod)
	crusader_bt.set_buff_icon("res://resources/icons/generic_icons/angel_wings.tres")
	crusader_bt.set_buff_tooltip("For the God\nIncreases attack damage and experience gain.")


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var for_the_god_effect: String = Utils.format_percent(_stats.for_the_god_effect, 2)
	var for_the_god_effect_add: String = Utils.format_percent(_stats.for_the_god_effect_add, 2)
	var duration: String = Utils.format_float(FOR_THE_GOD_DURATION, 2)
	var duration_add: String = Utils.format_float(FOR_THE_GOD_DURATION_ADD, 2)

	autocast.title = "For the God"
	autocast.icon = "res://resources/icons/holy/altar.tres"
	autocast.description_short = "This tower casts a buff on a tower that increases attack damage and experience gain.\n"
	autocast.description = "This tower casts a buff on a friendly tower that increases attack damage and experience gain by %s. The buff lasts %s seconds.\n" % [for_the_god_effect, duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s seconds duration\n" % duration_add \
	+ "+%s attack damage and experience gain\n" % for_the_god_effect_add
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.num_buffs_before_idle = 5
	autocast.target_self = true
	autocast.is_extended = false
	autocast.cast_range = 600
	autocast.auto_range = 600
	autocast.cooldown = 4
	autocast.mana_cost = 10
	autocast.buff_type = crusader_bt
	autocast.handler = on_autocast

	return [autocast]


func on_damage(event: Event):
	if !tower.calc_chance(BLESSED_WEAPON_CHANCE):
		return

	CombatLog.log_ability(tower, event.get_target(), "Blessed Weapon")

	var damage: float = _stats.blessed_weapon_damage + BLESSED_WEAPON_DAMAGE_ADD * tower.get_level()
	var mana_gain: float = BLESSED_WEAPON_MANA_GAIN + BLESSED_WEAPON_MANA_GAIN_ADD * tower.get_level()

	var effect: int = Effect.add_special_effect_target("HolyBoltSpecialArt.mdl", event.get_target(), Unit.BodyPart.ORIGIN)
	Effect.destroy_effect_after_its_over(effect)
	tower.do_spell_damage(event.get_target(), damage, tower.calc_spell_crit_no_bonus())
	tower.add_mana(mana_gain)


func on_autocast(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	crusader_bt.apply(tower, target, level)
