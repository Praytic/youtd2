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


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_attack(on_attack)


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
	surge_bt_mod.add_modification(ModificationType.enm.MOD_ATTACKSPEED, 1.0, 0.02)
	surge_bt.set_buff_modifier(surge_bt_mod)
	surge_bt.set_buff_icon("res://resources/icons/generic_icons/over_infinity.tres")
	surge_bt.add_event_on_attack(surge_bt_on_attack)
	surge_bt.set_buff_tooltip(tr("Q9D4"))


func on_attack(_event: Event):
	var mana: float = tower.get_mana()

	tower.set_mana(mana + 4 * tower.get_base_mana_regen_bonus_percent())

	tower.modify_property(ModificationType.enm.MOD_SPELL_CRIT_CHANCE, _stats.spell_crit + (tower.get_level() * _stats.spell_crit_add))
	tower.user_real = tower.user_real + _stats.spell_crit + tower.get_level() * _stats.spell_crit_add


func on_damage(event: Event):
	if !tower.calc_chance(0.125 + 0.005 * tower.get_level()):
		return

	var creep: Creep = event.get_target()

	if !creep.is_immune():
		CombatLog.log_ability(tower, creep, "Lightning Burst")

		Effect.create_animated("res://src/effects/holy_bolt_green.tscn", Vector3(creep.get_x(), creep.get_y(), 50), 0)
		tower.do_spell_damage(creep, tower.get_mana() * _stats.damage_from_mana_multiplier, tower.calc_spell_crit_no_bonus())
		tower.modify_property(ModificationType.enm.MOD_SPELL_CRIT_CHANCE, - tower.user_real)
		tower.user_real = 0.0


func on_create(_preceding_tower: Tower):
	tower.user_real = 0.0
	tower.user_int = 0
