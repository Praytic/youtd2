extends Tower


# NOTE: original script has a bug where slow debuff is
# applied to the main target instead of all damaged units.
# Fixed it.


var cedi_protectress_slow_bt: BuffType
var cedi_protectress_aura_bt: BuffType
var seconds_since_last_attack: int = 0
var dmg_bonus_from_meld: float = 0.0


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Protectress's Wrath[/color]\n"
	text += "Each attack has a [seconds since last attack x 5]% chance to deal an extra 50% attack damage to all units in 250 range around the target. The maximum chance is 75%. Slows all damaged units by 50% for 1.5 seconds. Increased attackspeed decreases time needed to gain a charge.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+2% damage\n"
	text += "+0.04 seconds\n"
	text += " \n"

	text += "[color=GOLD]Meld with the Forest[/color]\n"
	text += "The Protectress gains 18% additional attack damage for each second she doesn't attack. There is a maximum of 12 seconds. On attack the bonus disappears. Increased attackspeed decreases the time needed to gain a charge.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1% damage per second\n"
	text += " \n"

	text += "[color=GOLD]Strike the Unprepared - Aura[/color]\n"
	text += "Increases the attack critical chance of towers in 175 range by 0.25% for each 1% hp the attacked creep has left.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.01% attack crit chance\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Protectress's Wrath[/color]\n"
	text += "Each attack has a chance to deal an extra damage to all units in range around the target. Slows all damaged units.\n"
	text += " \n"

	text += "[color=GOLD]Meld with the Forest[/color]\n"
	text += "The Protectress gains additional attack damage for each second she doesn't attack.\n"
	text += " \n"

	text += "[color=GOLD]Strike the Unprepared - Aura[/color]\n"
	text += "Increases the attack critical chance of towers in range based on hp of attacked creeps.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 1.0)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.06)


func tower_init():
	cedi_protectress_slow_bt = BuffType.new("cedi_protectress_slow_bt", 1.5, 0.04, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.50, 0.0)
	cedi_protectress_slow_bt.set_buff_modifier(mod)
	cedi_protectress_slow_bt.set_buff_icon("@@0@@")
	cedi_protectress_slow_bt.set_buff_tooltip("Protectress's Wrath\nThis unit is affected by Protectreess's Wrath; it has reduced movement speed.")

	cedi_protectress_aura_bt = BuffType.create_aura_effect_type("cedi_protectress_aura_bt", true, self)
	cedi_protectress_aura_bt.set_buff_icon("@@1@@")
	cedi_protectress_aura_bt.add_event_on_attack(cedi_protectress_aura_bt_on_attack)
	cedi_protectress_aura_bt.add_event_on_cleanup(cedi_protectress_aura_bt_on_cleanup)
	cedi_protectress_aura_bt.set_buff_tooltip("Strike the Unprepared Aura\nThis tower is under the effect of Strike the Unprepared Aura; it will get increased crit chance based on target's health.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 175
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = cedi_protectress_aura_bt

	return [aura]


func on_damage(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var wrath_damage: float = (0.5 + 0.02 * tower.get_level()) * tower.get_current_attack_damage_with_bonus()
	var wrath_chance: float = 0.05 * seconds_since_last_attack

	if !tower.calc_chance(wrath_chance):
		return

	CombatLog.log_ability(self, target, "Protectress's Wrath")

	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 250)
	SFX.sfx_at_unit("NECancelDeath.mdl", target)
	tower.do_attack_damage_aoe_unit(target, 250, wrath_damage, tower.calc_attack_multicrit_no_bonus(), 0.0)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		cedi_protectress_slow_bt.apply(tower, next, tower.get_level())

	tower.set_visual_modulate(Color.WHITE)
	tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, -dmg_bonus_from_meld)
	dmg_bonus_from_meld = 0.0
	seconds_since_last_attack = 0


func periodic(event: Event):
	var tower: Tower = self
	var bonus_add: float = 0.18 + 0.01 * tower.get_level()
	var updated_period: float = tower.get_current_attack_speed() / 2.2

	if seconds_since_last_attack < 12:
		seconds_since_last_attack += 1

		tower.set_visual_modulate(Color8(255, 255, 255, 255 - 15 * seconds_since_last_attack))
		tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, bonus_add)
		dmg_bonus_from_meld += bonus_add

	event.enable_advanced(updated_period, false)


func cedi_protectress_aura_bt_on_attack(event: Event):
	var buff: Buff = event.get_buff()
	var tower: Unit = buff.get_buffed_unit()
	var creep: Unit = event.get_target()
	var caster: Unit = buff.get_caster()
	var prev_bonus: float = buff.user_real
	var new_bonus: float = creep.get_health_ratio() * (0.25 + 0.01 * caster.get_level())

	tower.modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, -prev_bonus)
	tower.modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, new_bonus)

	buff.user_real = new_bonus


func cedi_protectress_aura_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var applied_bonus: float = buff.user_real
	target.modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, -applied_bonus)
