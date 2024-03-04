extends Tower


var cb_silence: BuffType
var mock_nortrom_aura_bt: BuffType
var glaive_pt: ProjectileType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Glaives of Wisdom[/color]\n"
	text += "Every attack an extra glaive is shot out at the cost of 40 mana. This glaive deals physical damage equal to Nortrom's attack damage and targets the creep with the least health in Nortrom's attack range.\n"
	text += " \n"

	text += "[color=GOLD]Last Word[/color]\n"
	text += "If Nortrom attacks a silenced creep, then he does 20% more damage. This affects Glaives of Wisdom as well.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+3.2% damage\n"
	text += " \n"

	text += "[color=GOLD]Curse of the Silent[/color]\n"
	text += "Every 7 seconds creeps within 800 range of Nortrom are silenced for 2 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.04 silence duration\n"
	text += " \n"

	text += "[color=GOLD]Global Silence - Aura[/color]\n"
	text += "All towers within 350 range of Nortrom have a 3% attackspeed adjusted chance to silence targeted creeps for 1 second. Duration is halved against bosses.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.08% chance\n"
	text += "+0.04 silence duration\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Glaives of Wisdom[/color]\n"
	text += "Every attack an extra glaive is shot out at the cost of mana.\n"
	text += " \n"

	text += "[color=GOLD]Last Word[/color]\n"
	text += "Nortrom deals more damage to silenced creeps.\n"
	text += " \n"

	text += "[color=GOLD]Curse of the Silent[/color]\n"
	text += "Creeps in range of Nortrom are periodically silenced.\n"
	text += " \n"

	text += "[color=GOLD]Global Silence - Aura[/color]\n"
	text += "Nearby towers have a small chance to silence creeps.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 7.0)


func get_ability_ranges() -> Array[Tower.RangeData]:
	return [Tower.RangeData.new("Curse of the Silent", 800, TargetType.new(TargetType.CREEPS))]


func tower_init():
	cb_silence = CbSilence.new("nortrom_silence", 0, 0, false, self)

	mock_nortrom_aura_bt = BuffType.create_aura_effect_type("mock_nortrom_aura_bt", true, self)
	mock_nortrom_aura_bt.set_buff_icon("@@0@@")
	mock_nortrom_aura_bt.add_event_on_attack(mock_nortrom_aura_bt_on_attack)
	mock_nortrom_aura_bt.set_buff_tooltip("Global Silence\nChance to silence creeps.")

	glaive_pt = ProjectileType.create_interpolate("BloodElfSpellThiefMISSILE.mdl", 1000, self)
	glaive_pt.set_event_on_interpolation_finished(glaive_pt_on_hit)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 350
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = mock_nortrom_aura_bt

	return [aura]


func on_attack(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()

	if tower.get_mana() < 40:
		return

	tower.subtract_mana(40, false)

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 800)

	var lowest_health_creep: Unit = target

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		if next.get_health() < target.get_health():
			lowest_health_creep = next

	var p: Projectile = Projectile.create_linear_interpolation_from_unit_to_unit(glaive_pt, tower, 1, 1, tower, lowest_health_creep, 0, true)
	p.setScale(0.5)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var silenced_damage_multiplier: float = get_silenced_damage_multiplier()

	if target.is_silenced():
		event.damage *= silenced_damage_multiplier
		var effect: int = Effect.create_scaled("SpellBreakerAttack.mdl", target.get_visual_x(), target.get_visual_x(), 30, 0, 2)
		Effect.destroy_effect_after_its_over(effect)


func periodic(_event: Event):
	var tower: Tower = self
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 800)
	var duration: float = 2.0 + 0.04 * tower.get_level()

	CombatLog.log_ability(tower, null, "Curse of the Silent")

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		cb_silence.apply_only_timed(tower, next, duration)


# func on_autocast(event: Event):
# 	var tower: Tower = self


# NOTE: "glaive_hit()" in original script
func glaive_pt_on_hit(p: Projectile, target: Unit):
	if target == null:
		return

	var tower: Tower = p.get_caster()
	var damage: float = tower.get_current_attack_damage_with_bonus()
	var silenced_damage_multiplier: float = get_silenced_damage_multiplier()

	if target.is_silenced():
		damage *= silenced_damage_multiplier
		var effect: int = Effect.create_scaled("SpellBreakerAttack.mdl", target.get_visual_x(), target.get_visual_x(), 30, 0, 2)
		Effect.destroy_effect_after_its_over(effect)

	tower.do_attack_damage(target, damage, tower.calc_attack_multicrit_no_bonus())


# NOTE: "silence()" in original script
func mock_nortrom_aura_bt_on_attack(event: Event):
	var buff: Buff = event.get_buff()
	var tower: Tower = buff.get_caster()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var target: Creep = event.get_target()
	var silence_chance: float = (0.03 + 0.0008 * tower.get_level()) * buffed_unit.get_base_attackspeed()

	if !tower.calc_chance(silence_chance):
		return

	var duration: float = 1.0 + 0.04 * tower.get_level()
	if target.get_size() == CreepSize.enm.BOSS:
		duration /= 2

	CombatLog.log_ability(buffed_unit, target, "Global Silence Effect")

	cb_silence.apply_only_timed(tower, target, duration)


func get_silenced_damage_multiplier() -> float:
	var tower: Tower = self
	var multiplier: float = 1.2 + 0.032 * tower.get_level()

	return multiplier
