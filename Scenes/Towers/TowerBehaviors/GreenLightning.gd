extends TowerBehavior


# NOTE: changed missile speed in csv for this tower.
# 5000->9001. This tower uses "lightning" projectile visual
# so slow speed looks weird because it makes the damage
# delayed compared to the lightning visual.

var surge_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {surge_bt_level_bonus = 0, spell_crit = 0.050, spell_crit_add = 0.0010, damage_from_mana_multiplier = 15},
		2: {surge_bt_level_bonus = 25, spell_crit = 0.075, spell_crit_add = 0.0015, damage_from_mana_multiplier = 25},
		3: {surge_bt_level_bonus = 50, spell_crit = 0.100, spell_crit_add = 0.0020, damage_from_mana_multiplier = 35},
		4: {surge_bt_level_bonus = 75, spell_crit = 0.125, spell_crit_add = 0.0025, damage_from_mana_multiplier = 45},
	}



func get_ability_info_list() -> Array[AbilityInfo]:
	var spell_crit: String = Utils.format_percent(_stats.spell_crit, 2)
	var spell_crit_add: String = Utils.format_percent(_stats.spell_crit_add, 2)
	var damage_from_mana_multiplier: String = Utils.format_float(_stats.damage_from_mana_multiplier, 2)

	var list: Array[AbilityInfo] = []
	
	var mana_feed: AbilityInfo = AbilityInfo.new()
	mana_feed.name = "Mana Feed"
	mana_feed.icon = "res://Resources/Icons/magic/magic_stone.tres"
	mana_feed.description_short = "Attacks restore mana to the tower and increase spell crit chance.\n"
	mana_feed.description_full = "Attacks restore 4 mana to the tower and increase spell crit chance by %s.\n" % spell_crit \
	+ "[color=GOLD]Hint:[/color] Mana regeneration increases mana gained.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell crit chance\n" % spell_crit_add
	list.append(mana_feed)

	var burst: AbilityInfo = AbilityInfo.new()
	burst.name = "Lightning Burst"
	burst.icon = "res://Resources/Icons/electricity/lightning_circle_white.tres"
	burst.description_short = "Grants a chance to deal extra spell damage on each attack, resets spell crit bonus of Mana Feed.\n"
	burst.description_full = "Grants a 12.5%% chance to deal %s times current mana as spell damage on attack.\n" % damage_from_mana_multiplier \
	+ " \n" \
	+ "Resets the bonus spell crit of 'Mana Feed'.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.5% chance\n"
	list.append(burst)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, 0.20, 0.0)


func on_autocast(_event: Event):
	tower.user_int = 5 + tower.get_level() / 5
	surge_bt.apply(tower, tower, tower.get_level() + _stats.surge_bt_level_bonus)


# NOTE: surge() in original script
func surge_bt_on_attack(event: Event):
	var b: Buff = event.get_buff()
	var caster: Unit = b.get_caster()

	if caster.user_int < 1:
		b.remove_buff()
	else:
		caster.user_int = caster.user_int - 1


func tower_init():
	var surge_bt_mod: Modifier = Modifier.new()
	surge_bt = BuffType.new("surge_bt", 8, 0, true, self)
	surge_bt_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 1.0, 0.02)
	surge_bt.set_buff_modifier(surge_bt_mod)
	surge_bt.set_buff_icon("res://Resources/Icons/GenericIcons/over_infinity.tres")
	surge_bt.add_event_on_attack(surge_bt_on_attack)
	surge_bt.set_buff_tooltip("Mana Feed\nIncreases spell crit chance.")


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var attackspeed: String = Utils.format_percent(1.0 + 0.02 * _stats.surge_bt_level_bonus, 2)
	
	autocast.title = "Lightning Surge"
	autocast.icon = "res://Resources/Icons/electricity/lightning_circle_white.tres"
	autocast.description_short = "Increases the attackspeed of this tower for next few attacks.\n"
	autocast.description = "Increases the attackspeed of this tower by %s for the next 5 attacks. The surge fades after 8 seconds.\n" % attackspeed \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+2% attackspeed\n" \
	+ "+1 attack per 5 levels\n"
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.cast_range = 1200
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 6
	autocast.is_extended = false
	autocast.mana_cost = 60
	autocast.buff_type = null
	autocast.target_type = null
	autocast.auto_range = 1200
	autocast.handler = on_autocast

	return [autocast]


func on_attack(_event: Event):
	var mana: float = tower.get_mana()

	tower.set_mana(mana + 4 * tower.get_base_mana_regen_bonus_percent())

	tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, _stats.spell_crit + (tower.get_level() * _stats.spell_crit_add))
	tower.user_real = tower.user_real + _stats.spell_crit + tower.get_level() * _stats.spell_crit_add


func on_damage(event: Event):
	if !tower.calc_chance(0.125 + 0.005 * tower.get_level()):
		return

	var creep: Creep = event.get_target()

	if !creep.is_immune():
		CombatLog.log_ability(tower, creep, "Lightning Burst")

		var target_effect: int = Effect.create_scaled("ManaFlareBoltImpact.mdl", Vector3(creep.get_x(), creep.get_y(), 0), 0, 5)
		Effect.set_lifetime(target_effect, 1.0)
		tower.do_spell_damage(creep, tower.get_mana() * _stats.damage_from_mana_multiplier, tower.calc_spell_crit_no_bonus())
		tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, - tower.user_real)
		tower.user_real = 0.0


func on_create(_preceding_tower: Tower):
	tower.user_real = 0.0
	tower.user_int = 0
