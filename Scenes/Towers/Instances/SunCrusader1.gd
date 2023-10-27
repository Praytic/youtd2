extends Tower


# NOTE: changed buff types a bit. In original script they
# are two separate types, made it into one type which
# changes based on tier.


var cedi_crusader_buff: BuffType


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


func get_ability_description() -> String:
	var blessed_weapon_chance: String = Utils.format_percent(BLESSED_WEAPON_CHANCE, 2)
	var blessed_weapon_mana_gain: String = Utils.format_float(BLESSED_WEAPON_MANA_GAIN, 2)
	var blessed_weapon_mana_gain_add: String = Utils.format_float(BLESSED_WEAPON_MANA_GAIN_ADD, 2)
	var blessed_weapon_damage: String = Utils.format_float(_stats.blessed_weapon_damage, 2)
	var blessed_weapon_damage_add: String = Utils.format_float(BLESSED_WEAPON_DAMAGE_ADD, 2)
	
	var text: String = ""

	text += "[color=GOLD]Blessed Weapon[/color]\n"
	text += "Everytime this tower damages a creep it has a %s chance to deal %s spelldamage and gain %s mana.\n" % [blessed_weapon_chance, blessed_weapon_damage, blessed_weapon_mana_gain]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % blessed_weapon_damage_add
	text += "+%s mana regeneration\n" % blessed_weapon_mana_gain_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Blessed Weapon[/color]\n"
	text += "Everytime this tower damages a creep it has a chance to deal spelldamage and gain mana.\n"

	return text


func get_autocast_description() -> String:
	var for_the_god_effect: String = Utils.format_percent(_stats.for_the_god_effect, 2)
	var for_the_god_effect_add: String = Utils.format_percent(_stats.for_the_god_effect_add, 2)
	var duration: String = Utils.format_float(FOR_THE_GOD_DURATION, 2)
	var duration_add: String = Utils.format_float(FOR_THE_GOD_DURATION_ADD, 2)

	var text: String = ""

	text += "This tower casts a buff on a friendly tower that increases attackdamage and experience gain by %s. The buff lasts %s seconds.\n" % [for_the_god_effect, duration]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s seconds duration\n" % duration_add
	text += "+%s attack damage and experience gain\n" % for_the_god_effect_add

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "This tower casts a buff on a tower that increases attack damage and experience gain.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	_set_attack_ground_only()
	_set_attack_style_bounce(5, 0.1)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, _stats.mod_dmg_to_undead, 0.0)
	modifier.add_modification(Modification.Type.MOD_MANA, 0, 1)


func tower_init():
	cedi_crusader_buff = BuffType.new("cedi_crusader_buff", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, 0.001)
	mod.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.0, 0.001)
	cedi_crusader_buff.set_buff_modifier(mod)
	cedi_crusader_buff.set_buff_icon("@@1@@")
	cedi_crusader_buff.set_buff_tooltip("For the God\nThis tower is affected by For the God; it deals extra attack damage and has increased experience gain.")

	var autocast: Autocast = Autocast.make()
	autocast.title = "For the God"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
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
	autocast.buff_type = cedi_crusader_buff
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_damage(event: Event):
	var tower: Tower = self

	if !tower.calc_chance(BLESSED_WEAPON_CHANCE):
		return

	var damage: float = _stats.blessed_weapon_damage + BLESSED_WEAPON_DAMAGE_ADD * tower.get_level()
	var mana_gain: float = BLESSED_WEAPON_MANA_GAIN + BLESSED_WEAPON_MANA_GAIN_ADD * tower.get_level()

	var effect: int = Effect.add_special_effect_target("HolyBoltSpecialArt.mdl", event.get_target(), "origin")
	Effect.destroy_effect_after_its_over(effect)
	tower.do_spell_damage(event.get_target(), damage, tower.calc_spell_crit_no_bonus())
	tower.add_mana(mana_gain)


func on_autocast(event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	var buff_level: int = _stats.for_the_god_level + _stats.for_the_god_level_add * level
	var buff_duration: float = FOR_THE_GOD_DURATION + FOR_THE_GOD_DURATION_ADD * level

	cedi_crusader_buff.apply_custom_timed(tower, event.get_target(), buff_level, buff_duration)
