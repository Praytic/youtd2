extends TowerBehavior


var silence_bt: BuffType
var aura_bt: BuffType
var glaive_pt: ProjectileType


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var glaive: AbilityInfo = AbilityInfo.new()
	glaive.name = "Glaives of Wisdom"
	glaive.icon = "res://Resources/Icons/hud/recipe_reassemble.tres"
	glaive.description_short = "Every attack an extra glaive is shot out at the cost of mana.\n"
	glaive.description_full = "Every attack an extra glaive is shot out at the cost of 40 mana. This glaive deals physical damage equal to Nortrom's attack damage and targets the creep with the least health in Nortrom's attack range.\n"
	list.append(glaive)

	var last_word: AbilityInfo = AbilityInfo.new()
	last_word.name = "Last Word"
	last_word.icon = "res://Resources/Icons/shields/shield_skull.tres"
	last_word.description_short = "Nortrom deals more damage to silenced creeps.\n"
	last_word.description_full = "If Nortrom attacks a silenced creep, then he does 20% more damage. This affects Glaives of Wisdom as well.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+3.2% damage\n"
	list.append(last_word)

	var curse: AbilityInfo = AbilityInfo.new()
	curse.name = "Curse of the Silent"
	curse.icon = "res://Resources/Icons/tower_variations/AshGeyser_purple.tres"
	curse.description_short = "Creeps in range of Nortrom are periodically silenced.\n"
	curse.description_full = "Every 7 seconds creeps within 800 range of Nortrom are silenced for 2 seconds.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.04 silence duration\n"
	list.append(curse)

	var global_silence: AbilityInfo = AbilityInfo.new()
	global_silence.name = "Global Silence - Aura"
	global_silence.icon = "res://Resources/Icons/TowerIcons/TinyStormLantern.tres"
	global_silence.description_short = "Nearby towers have a small chance to silence creeps.\n"
	global_silence.description_full = "All towers within 350 range of Nortrom have a 3% attackspeed adjusted chance to silence targeted creeps for 1 second. Duration is halved against bosses.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.08% chance\n" \
	+ "+0.04 silence duration\n"
	list.append(global_silence)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 7.0)


func get_ability_ranges() -> Array[RangeData]:
	return [RangeData.new("Curse of the Silent", 800, TargetType.new(TargetType.CREEPS))]


func tower_init():
	silence_bt = CbSilence.new("silence_bt", 0, 0, false, self)

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://Resources/Icons/GenericIcons/aries.tres")
	aura_bt.add_event_on_attack(aura_bt_on_attack)
	aura_bt.set_buff_tooltip("Global Silence\nChance to silence creeps.")

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
	aura.aura_effect = aura_bt

	return [aura]


func on_attack(event: Event):
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
	p.set_projectile_scale(0.5)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var silenced_damage_multiplier: float = get_silenced_damage_multiplier()

	if target.is_silenced():
		event.damage *= silenced_damage_multiplier
		var effect: int = Effect.create_scaled("SpellBreakerAttack.mdl", Vector3(target.get_x(), target.get_x(), 30), 0, 5)
		Effect.destroy_effect_after_its_over(effect)


func periodic(_event: Event):
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 800)
	var duration: float = 2.0 + 0.04 * tower.get_level()

	CombatLog.log_ability(tower, null, "Curse of the Silent")

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		silence_bt.apply_only_timed(tower, next, duration)


# NOTE: "glaive_hit()" in original script
func glaive_pt_on_hit(_p: Projectile, target: Unit):
	if target == null:
		return

	var damage: float = tower.get_current_attack_damage_with_bonus()
	var silenced_damage_multiplier: float = get_silenced_damage_multiplier()

	if target.is_silenced():
		damage *= silenced_damage_multiplier
		var effect: int = Effect.create_scaled("SpellBreakerAttack.mdl", Vector3(target.get_x(), target.get_x(), 30), 0, 5)
		Effect.destroy_effect_after_its_over(effect)

	tower.do_attack_damage(target, damage, tower.calc_attack_multicrit_no_bonus())


# NOTE: "silence()" in original script
func aura_bt_on_attack(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var target: Creep = event.get_target()
	var silence_chance: float = (0.03 + 0.0008 * tower.get_level()) * buffed_unit.get_base_attackspeed()

	if !tower.calc_chance(silence_chance):
		return

	var duration: float = 1.0 + 0.04 * tower.get_level()
	if target.get_size() == CreepSize.enm.BOSS:
		duration /= 2

	CombatLog.log_ability(buffed_unit, target, "Global Silence Effect")

	silence_bt.apply_only_timed(tower, target, duration)


func get_silenced_damage_multiplier() -> float:
	var multiplier: float = 1.2 + 0.032 * tower.get_level()

	return multiplier
