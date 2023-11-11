extends Tower


# NOTE: original script sets level of buff to 1 for some
# reason, so the effect doesn't scale with tower level.
# Fixed it.

# NOTE: original script uses "frenzy" spell as a visual
# effect. Didn't implement that. Can implement using an
# Effect.

var poussix_dreadlord_bt: BuffType
var multiboard: MultiboardValues


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Dreadlord Slash[/color]\n"
	text += "Dreadlord deals 100% of his max mana in spell damage on attack. Costs 80 mana on each attack.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+4% spell damag\n"
	text += " \n"

	text += "[color=GOLD]Bloodsucker[/color]\n"
	text += "The Dreadlord is hungry. For every kill he gains 0.5% attack speed and 10 maximum mana. The mana bonus caps at 2000. Both bonuses are permanent.\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Dreadlord Slash[/color]\n"
	text += "Dreadlord deals extra damage based on current mana.\n"
	text += " \n"

	text += "[color=GOLD]Bloodsucker[/color]\n"
	text += "Dreadlord gains extra power with every kill.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "When activated, Dreadlord empowers himself with darkness for 10 seconds, increasing own attack speed by 50% and mana regeneration by 20 per second.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+2% attack speed\n"
	text += "+0.8 mana per second\n"

	return text


func get_autocast_description_short() -> String:
	return "When activated, Dreadlord empowers himself with darkness.\n"


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_kill(on_kill)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_PERC, 0.0, 0.05)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.0, 0.05)


func tower_init():
	poussix_dreadlord_bt = BuffType.new("poussix_dreadlord_bt", 10, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.5, 0.02)
	mod.add_modification(Modification.Type.MOD_MANA_REGEN, 20, 0.8)
	poussix_dreadlord_bt.set_buff_modifier(mod)
	poussix_dreadlord_bt.set_buff_icon("@@2@@")
	poussix_dreadlord_bt.set_buff_tooltip("Dreadlord's Awakening\nThe dreadlord has awaked; it has increased attack speed and mana regen.")

	multiboard = MultiboardValues.new(2)
	multiboard.set_key(0, "Attackspeed Bonus")
	multiboard.set_key(1, "Mana Bonus")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Dreadlord's Awakening"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 0
	autocast.auto_range = 900
	autocast.cooldown = 80
	autocast.mana_cost = 0
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_damage(event: Event):
	var tower: Tower = self
	var creep: Unit = event.get_target()
	var damage: float = (1 + 0.04 * tower.get_level()) * tower.get_overall_mana()
	var mana: float = tower.get_mana()

	if mana >= 80:
		tower.do_spell_damage(creep, damage, tower.calc_spell_crit_no_bonus())
		tower.subtract_mana(80, 0)
		var effect: int = Effect.create_scaled("DevourEffectArt.mdl", creep.get_visual_x(), creep.get_visual_y(), 30, 0, 1.5)
		Effect.destroy_effect_after_its_over(effect)


func on_kill(_event: Event):
	var tower: Tower = self
	tower.modify_property(Modification.Type.MOD_ATTACKSPEED, 0.005)
	tower.user_real2 += 0.005

	if tower.user_real <= 2:
		tower.user_real += 0.01
		tower.modify_property(Modification.Type.MOD_MANA, 10)


func on_tower_details() -> MultiboardValues:
	var tower: Tower = self
	var attackspeed_bonus: String = Utils.format_percent(tower.user_real2, 1)
	var mana_bonus: String = str(int(tower.user_real * 1000))
	multiboard.set_value(0, attackspeed_bonus)
	multiboard.set_value(1, mana_bonus)
	
	return multiboard


func on_autocast(_event: Event):
	var tower: Tower = self
	poussix_dreadlord_bt.apply(tower, tower, tower.get_level())
