extends Tower


var sir_drake_aura: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mana_regen_add = 1.0, aura_mana_cost = 7, aura_power = 50, aura_power_add = 4, aura_level = 200, damage_mana_multiplier = 8.0},
		2: {mana_regen_add = 2.4, aura_mana_cost = 14, aura_power = 75, aura_power_add = 6, aura_level = 300, damage_mana_multiplier = 9.5},
		3: {mana_regen_add = 4.2, aura_mana_cost = 24, aura_power = 100, aura_power_add = 8, aura_level = 400, damage_mana_multiplier = 11.0},
		4: {mana_regen_add = 6.4, aura_mana_cost = 35, aura_power = 125, aura_power_add = 10, aura_level = 500, damage_mana_multiplier = 12.5},
	}


func get_ability_description() -> String:
	var buffed_tower_mana_burned: String = Utils.format_float(_stats.aura_level / 100.0, 2)
	var damage_mana_multiplier: String = Utils.format_float(_stats.damage_mana_multiplier, 2)
	var aura_mana_cost: String = Utils.format_float(_stats.aura_mana_cost, 2)
	var damage_per_mana_point: String = Utils.format_float(_stats.aura_power, 2)
	var damage_per_mana_point_add: String = Utils.format_float(_stats.aura_power_add, 2)
	var elemental_attack_type_string: String = AttackType.convert_to_colored_string(AttackType.enm.ELEMENTAL)

	var text: String = ""

	text += "[color=GOLD]Unstable Energies[/color]\n"
	text += "This tower has a 28%% chance on damage to release a powerful energy blast, dealing [current mana x %s] %s damage to the target, but consuming 75%% of its own current mana.\n" % [damage_mana_multiplier, elemental_attack_type_string]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.48% chance\n"
	text += "-1% current mana consumed\n"
	text += " \n"
	text += "[color=GOLD]Mana Distortion Field - Aura[/color]\n"
	text += "Towers in 200 range burn %s mana on attack, costing the drake %s mana. The mana burned and spent is attackspeed and range adjusted and the tower deals %s spelldamage per mana point burned.\n" % [buffed_tower_mana_burned, aura_mana_cost, damage_per_mana_point]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s spelldamage per mana point burned\n" % damage_per_mana_point_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Unstable Energies[/color]\n"
	text += "This tower has a chance on damage to release a powerful energy blast at the cost of some mana.\n"
	text += " \n"
	text += "[color=GOLD]Mana Distortion Field - Aura[/color]\n"
	text += "Nearby towers range burn creep mana on attack.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0, _stats.mana_regen_add)


func drake_aura_manaburn(event: Event):
	var b: Buff = event.get_buff()
	var tower: Tower = b.get_buffed_unit()
	var target: Unit = event.get_target()
	var caster: Unit = b.get_caster()
	var mana_drained: float
	var speed: float = tower.get_base_attack_speed() * 800 / tower.get_range()

	if target.get_mana() > 0 && caster.subtract_mana(caster.user_real * speed, false) > 0:
		mana_drained = target.subtract_mana(b.get_level() / 100.0 * speed, true)
		tower.do_spell_damage(target, mana_drained * b.get_power(), tower.calc_spell_crit_no_bonus())
		SFX.sfx_at_unit("DeathandDecayDamage.dml", target)


func tower_init():
	sir_drake_aura = BuffType.create_aura_effect_type("sir_drake_aura", true, self)
	sir_drake_aura.set_buff_icon("@@0@@")
	sir_drake_aura.add_event_on_attack(drake_aura_manaburn)
	sir_drake_aura.set_buff_tooltip("Mana Distortion Field\nThis tower is under the effect of Mana Distortion Field; it will mana burn enemies.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = false
	aura.level = _stats.aura_level
	aura.level_add = 0
	aura.power = _stats.aura_power
	aura.power_add = _stats.aura_power_add
	aura.aura_effect = sir_drake_aura
	add_aura(aura)


func on_damage(event: Event):
	var tower: Tower = self

	if !tower.calc_chance(0.28 + 0.0048 * tower.get_level()):
		return

	tower.do_attack_damage(event.get_target(), _stats.damage_mana_multiplier * tower.get_mana(), tower.calc_attack_multicrit(0, 0, 0))
	tower.subtract_mana(tower.get_mana() * (0.75 - 0.01 * tower.get_level()), true)
	SFX.sfx_at_unit("AlmaTarget.dml", event.get_target())


func on_create(_preceding_tower: Tower):
	var tower: Tower = self
	tower.user_real = _stats.aura_mana_cost
