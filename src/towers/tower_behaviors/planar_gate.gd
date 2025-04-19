extends TowerBehavior


var eruption_bt: BuffType
var planar_shift_bt: BuffType
var bouncing_pt: ProjectileType
var falcon_count: int = 0


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	tower.hide_attack_projectiles()

	eruption_bt = BuffType.new("eruption_bt", 6, 0.18, true, self)
	eruption_bt.set_buff_icon("res://resources/icons/generic_icons/azul_flake.tres")
	eruption_bt.set_buff_tooltip(tr("BOPO"))

	planar_shift_bt = BuffType.new("planar_shift_bt", -1, 0, false, self)
	planar_shift_bt.set_buff_icon("res://resources/icons/generic_icons/ghost.tres")
	planar_shift_bt.add_event_on_cleanup(planar_shift_bt_on_cleanup)
	planar_shift_bt.set_buff_tooltip(tr("I8HW"))

	bouncing_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 1250, self)
	bouncing_pt.set_event_on_interpolation_finished(bouncing_pt_on_hit)


func on_attack(event: Event):
	var ignore_falcon_count_max_chance: float = 0.20
	var ignore_falcon_count_max: bool = tower.calc_chance(ignore_falcon_count_max_chance)

#	Check if the amount of birds summoned is low enough to create another one.
	var falcon_count_max: int = 1 + tower.get_level() / 8
	if falcon_count >= falcon_count_max && !ignore_falcon_count_max:
		return

	var target: Unit = event.get_target()

	CombatLog.log_ability(tower, target, "Planeshift")

	var crits: int = event.get_number_of_crits()
	var cur_dmg: float = tower.get_current_attack_damage_with_bonus()
	var eruption_buff: Buff = tower.get_buff_of_type(eruption_bt)

#	Set the projectile values.
	var p: Projectile = Projectile.create_linear_interpolation_from_unit_to_unit(bouncing_pt, tower, 1, 1, tower, target, 0.5, true)
	p.user_real = 0.05 - 0.001 * tower.get_level() # damage multiplier loss per bounce
	p.user_real2 = 1 # Projectile's current damage multiplier

	if eruption_buff != null:
		p.user_int3 = 1
	else:
		p.user_int3 = 0

#	Check for crits.
	if crits > 0:
		p.user_real3 = cur_dmg * (crits * (tower.get_prop_atk_crit_damage() - 1) + 1)
		p.user_int = crits
	else:
		p.user_real3 = cur_dmg
		p.user_int = 0

#	Increase counter for birds summoned.
	falcon_count += 1


func on_damage(event: Event):
	event.damage = 0


func on_autocast(_event: Event):
	var effect_pos: Vector3 = tower.get_position_wc3()

	eruption_bt.apply(tower, tower, tower.get_level())

	var effect1: int = Effect.create_colored("res://src/effects/voodoo_aura.tscn", effect_pos, 0, 1, Color8(1, 255, 255, 255))
	Effect.set_z_index(effect1, Effect.Z_INDEX_BELOW_TOWERS)

	await Utils.create_manual_timer(0.3, self).timeout

	var effect2: int = Effect.create_colored("res://src/effects/voodoo_aura.tscn", effect_pos, 0, 2, Color8(1, 255, 255, 255))
	Effect.set_z_index(effect2, Effect.Z_INDEX_BELOW_TOWERS)
	
	await Utils.create_manual_timer(0.3, self).timeout
	
	var effect3: int = Effect.create_colored("res://src/effects/voodoo_aura.tscn", effect_pos, 0, 3, Color8(1, 255, 255, 255))
	Effect.set_z_index(effect3, Effect.Z_INDEX_BELOW_TOWERS)


# p.userInt = number of crits
# p.userInt2 = UID
# p.userInt3 = check for buff
# p.userReal = damage loss per bounce
# p.userReal2 = damage ratio of this projectile
# p.userReal3 = damage to deal
# NOTE: "bounce()" in original script
func bouncing_pt_on_hit(p: Projectile, target: Unit):
	if target == null:
		return

#	Check if this projectile has damage ratio left and if the target is still alive.
	if p.user_real2 <= 0 || target == null:
#		If the projectile had no damage ratio, end here and decrease the tower userInt.
		falcon_count -= 1

		return

	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 500)
	var dmg_mod_buff: Buff = target.get_buff_of_type(planar_shift_bt)

#	Check if the tower cast the buff since the last time this projectile hit.
	if tower.get_buff_of_type(eruption_bt) != null && p.user_int3 == 0:
		p.user_int3 = 1

#	Check if the tower crit this attack, and if so, display
#	the damage colored red above the tower with exclamation
#	marks after it equal to the number of crits. This only
#	runs the first time the projectile hits because
#	p.userInt is set to 0 at the end.
	if p.user_int > 0:
		var crit_str: String = ""
		var int_var: int = 0

		while true:
			crit_str += "!"
			int_var += 1

			if int_var == p.user_int:
				break

		var floating_text: String = str(int(p.user_real3)) + crit_str

		tower.get_player().display_floating_text(floating_text, tower, Color8(255, 0, 0))

#	Check if the buff was applied on the tower when it
#	launched this projectile, and if the target isn't immune
#	then increase the damage it takes from astral, and apply
#	the buff or if the buff was already applied, increase
#	the amount of damage taken to remove when the buff gets
#	purged or similar.
	if p.user_int3 == 1:
		if !target.is_immune():
			var dmg_mod: float = p.user_real2 * 0.01
			target.modify_property(ModificationType.enm.MOD_DMG_FROM_ASTRAL, dmg_mod)

			if dmg_mod_buff != null:
				dmg_mod_buff.user_real += dmg_mod
			else:
				dmg_mod_buff = planar_shift_bt.apply(tower, target, 0)
				dmg_mod_buff.user_real = dmg_mod

#	Deal the damage (double if the projectile got buffed).
	var damage: float = p.user_real3 * p.user_real2 * (1 + p.user_int3)
	tower.do_attack_damage(target, damage, 1.0)

#	Choose a target from all creeps in 500 range that isn't
#	this projectile's target.
	var next: Unit = it.next_random()
	if next == target && next != null:
		next = it.next_random()

#	If no valid targets in range, end here and decrease
#	falcon count so portal can fire again.
	if next == null:
		falcon_count -= 1

		return

#	Fire the projectile to the next unit and set all the
#	necessary values.
	var new_p: Projectile = Projectile.create_linear_interpolation_from_unit_to_unit(bouncing_pt, tower, 1, 1, target, next, 0.35, true)

	new_p.user_int = 0
	new_p.user_int3 = p.user_int3
	new_p.user_real = p.user_real
	new_p.user_real2 = p.user_real2 - p.user_real # decrease new projectile's damage multiplier
	new_p.user_real3 = p.user_real3


# In case the buff gets purged.
# NOTE: "removeMod()" in original script
func planar_shift_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	buffed_unit.modify_property(ModificationType.enm.MOD_DMG_FROM_ASTRAL, -buff.user_real)
