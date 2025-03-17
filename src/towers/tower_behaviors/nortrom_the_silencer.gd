extends TowerBehavior


var silence_bt: BuffType
var aura_bt: BuffType
var glaive_pt: ProjectileType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 7.0)


func tower_init():
	silence_bt = CbSilence.new("silence_bt", 0, 0, false, self)

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/aries.tres")
	aura_bt.add_event_on_attack(aura_bt_on_attack)
	aura_bt.set_buff_tooltip("Global Silence\nChance to silence creeps.")

	glaive_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 1000, self)
	glaive_pt.set_event_on_interpolation_finished(glaive_pt_on_hit)


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
		Effect.create_scaled("res://src/effects/spell_breaker_target.tscn", Vector3(target.get_x(), target.get_x(), 30), 0, 1)


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
		Effect.create_scaled("res://src/effects/spell_breaker_target.tscn", Vector3(target.get_x(), target.get_x(), 30), 0, 1)

	tower.do_attack_damage(target, damage, tower.calc_attack_multicrit_no_bonus())


# NOTE: "silence()" in original script
func aura_bt_on_attack(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var target: Creep = event.get_target()
	var silence_chance: float = (0.03 + 0.0008 * tower.get_level()) * buffed_unit.get_base_attack_speed()

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
