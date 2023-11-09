extends Tower


var cedi_shadow_glaive_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {shadow_glaive_crit_bonus = 0.25, shadow_glaive_crit_bonus_add = 0.01, star_glaive_dmg_ratio = 0.25},
		2: {shadow_glaive_crit_bonus = 0.50, shadow_glaive_crit_bonus_add = 0.02, star_glaive_dmg_ratio = 0.35},
		3: {shadow_glaive_crit_bonus = 0.75, shadow_glaive_crit_bonus_add = 0.03, star_glaive_dmg_ratio = 0.45},
	}


const SHADOW_GLAIVE_CHANCE: float = 0.20
const SHADOW_GLAIVE_CHANCE_ADD: float = 0.008
const SHADOW_GLAIVE_ATTACKSPEED: float = 2.0
const SHADOW_GLAIVE_ATTACKSPEED_ADD: float = 0.08
const STAR_GLAIVE_CHANCE: float = 0.25
const STAR_GLAIVE_CHANCE_ADD: float = 0.004
const STAR_GLAIVE_DMG_RATIO_ADD: float = 0.01


func get_ability_description() -> String:
	var shadow_glaive_chance: String = Utils.format_percent(SHADOW_GLAIVE_CHANCE, 2)
	var shadow_glaive_chance_add: String = Utils.format_percent(SHADOW_GLAIVE_CHANCE_ADD, 2)
	var shadow_glaive_attackspeed: String = Utils.format_percent(SHADOW_GLAIVE_ATTACKSPEED, 2)
	var shadow_glaive_attackspeed_add: String = Utils.format_percent(SHADOW_GLAIVE_ATTACKSPEED_ADD, 2)
	var shadow_glaive_crit_bonus: String = Utils.format_percent(_stats.shadow_glaive_crit_bonus, 2)
	var shadow_glaive_crit_bonus_add: String = Utils.format_percent(_stats.shadow_glaive_crit_bonus_add, 2)
	var star_glaive_chance: String = Utils.format_percent(STAR_GLAIVE_CHANCE, 2)
	var star_glaive_chance_add: String = Utils.format_percent(STAR_GLAIVE_CHANCE_ADD, 2)
	var star_glaive_dmg_ratio: String = Utils.format_percent(_stats.star_glaive_dmg_ratio, 2)
	var star_glaive_dmg_ratio_add: String = Utils.format_percent(STAR_GLAIVE_DMG_RATIO_ADD, 2)

	var text: String = ""

	text += "[color=GOLD]Shadow Glaive[/color]\n"
	text += "Whenever this tower attacks it has a %s chance to gain %s attackspeed until the next attack. The next attack will also crit for sure and deal %s more crit damage.\n" % [shadow_glaive_chance, shadow_glaive_attackspeed, shadow_glaive_crit_bonus]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s crit damage\n" % shadow_glaive_crit_bonus_add
	text += "+%s attack speed\n" % shadow_glaive_attackspeed_add
	text += "+%s chance\n" % shadow_glaive_chance_add
	text += " \n"
	text += "[color=GOLD]Star Glaive[/color]\n"
	text += "Whenever this tower damages a creep there is a %s chance to deal an additional %s of the attack's damage as spell damage.\n" % [star_glaive_chance, star_glaive_dmg_ratio]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s chance\n" % star_glaive_chance_add
	text += "+%s attack damage as spell damage\n" % star_glaive_dmg_ratio_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Shadow Glaive[/color]\n"
	text += "This tower has a chance to do a fast follow-up attack which is guaranteed to be critical.\n"
	text += " \n"
	text += "[color=GOLD]Star Glaive[/color]\n"
	text += "Whenever this tower damages a creep there is a chance to deal additional spell damage.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


# NOTE: this tower's tooltip in original game does NOT
# include innate stats
func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.024)
	_set_attack_style_bounce(4, 0.25)


func tower_init():
	cedi_shadow_glaive_bt = BuffType.new("cedi_shadow_glaive_bt", 99, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, SHADOW_GLAIVE_ATTACKSPEED, SHADOW_GLAIVE_ATTACKSPEED_ADD)
	cedi_shadow_glaive_bt.set_buff_modifier(mod)
	cedi_shadow_glaive_bt.set_buff_icon("@@0@@")
	cedi_shadow_glaive_bt.set_buff_tooltip("Shadow Glaive\nThis unit holds a Shadow Glaive; it's next attack will be faster and critical.")


func on_attack(_event: Event):
	var tower: Tower = self
	var buff: Buff = tower.get_buff_of_type(cedi_shadow_glaive_bt)
	var crit_damage_multiply: float = 1.0 + _stats.shadow_glaive_crit_bonus + _stats.shadow_glaive_crit_bonus_add * tower.get_level()
	var shadow_glaive_chance: float = SHADOW_GLAIVE_CHANCE + SHADOW_GLAIVE_CHANCE_ADD * tower.get_level()

	if buff != null:
		tower.add_modified_attack_crit(0.0, crit_damage_multiply)
		buff.remove_buff()

	if !tower.calc_chance(shadow_glaive_chance):
		return

	cedi_shadow_glaive_bt.apply(tower, tower, tower.get_level())


func on_damage(event: Event):
	var tower: Tower = self
	var star_glaive_chance: float = STAR_GLAIVE_CHANCE + STAR_GLAIVE_CHANCE_ADD * tower.get_level()
	var stair_glaive_damage: float = event.damage * (_stats.star_glaive_dmg_ratio + STAR_GLAIVE_DMG_RATIO_ADD * tower.get_level())

	if !tower.calc_chance(star_glaive_chance):
		return

	tower.do_spell_damage(event.get_target(), stair_glaive_damage, tower.calc_spell_crit_no_bonus())
	SFX.sfx_on_unit("StarfallTarget.mdl", event.get_target(), "origin")
