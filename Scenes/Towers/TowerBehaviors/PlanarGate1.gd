extends TowerBehavior


var maj_planar_eruption_bt: BuffType
var maj_planar_dmg_mod_bt: BuffType
var bouncing_pt: ProjectileType
var falcon_count: int = 0


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Planeshift[/color]\n"
	text += "On attack the Gate releases a magical falcon to hunt down its enemies.\n"
	text += "The falcon deals energy damage equal to the Gate's current attack damage and bounces until it runs out of damage. Each bounce deals 5% less damage.\n"
	text += "There is a maximum of 1 falcon summoned at a time and a 20% chance to ignore the maximum.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "-0.1% damage loss per bounce\n"
	text += "+1 falcon every 8 levels\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Planeshift[/color]\n"
	text += "On attack the Gate releases a magical falcon to hunt down its enemies.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "Releases a huge wave of astral power through the gate, weakening the boundary between the planes. This empowers all currently alive falcons and any that are created during the next 6 seconds, allowing them to deal double damage and partially shift their targets into the astral plane, increasing the damage they take from astral towers by 1% of the falcon's current damage ratio.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.18 seconds\n"

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "Releases a huge wave of astral power through the gate. This empowers falcons.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	maj_planar_eruption_bt = BuffType.new("maj_planar_eruption_bt", 6, 0.18, true, self)
	maj_planar_eruption_bt.set_buff_icon("crystal.tres")
	maj_planar_eruption_bt.set_buff_tooltip("Astral Eruption\nEmpowers falcons to deal more damage.")

	maj_planar_dmg_mod_bt = BuffType.new("maj_planar_dmg_mod_bt", -1, 0, false, self)
	maj_planar_dmg_mod_bt.set_buff_icon("ghost.tres")
	maj_planar_dmg_mod_bt.add_event_on_cleanup(maj_planar_dmg_mod_bt_on_cleanup)
	maj_planar_dmg_mod_bt.set_buff_tooltip("Planar Shift\nIncreases damage taken from Astral towers.")

	bouncing_pt = ProjectileType.create_interpolate("MurgulMagicMissile.mdl", 1250, self)
	bouncing_pt.set_event_on_interpolation_finished(bouncing_pt_on_hit)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Astral Eruption"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 0
	autocast.auto_range = 700
	autocast.cooldown = 35
	autocast.mana_cost = 1000
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = maj_planar_eruption_bt
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast
	tower.add_autocast(autocast)


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
	var eruption_buff: Buff = tower.get_buff_of_type(maj_planar_eruption_bt)

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

# 	Remove crits so a 0! doesn't pop up over the tower.
	# TODO: implement Tower.resetAttackCrits()
	# tower.resetAttackCrits()


func on_damage(event: Event):
	event.damage = 0


func on_autocast(_event: Event):
	var x: float = tower.get_visual_x()
	var y: float = tower.get_visual_y()

	maj_planar_eruption_bt.apply(tower, tower, tower.get_level())

	var effect1: int = Effect.create_colored("VoodooAura.mdl", x, y, 0, 0, 5, Color8(1, 255, 255, 255))
	Effect.set_lifetime(effect1, 0.5)

	await Utils.create_timer(0.3).timeout

	var effect2: int = Effect.create_colored("VoodooAura.mdl", x, y, 0, 0, 5, Color8(1, 255, 255, 255))
	Effect.set_lifetime(effect2, 0.5)
	
	await Utils.create_timer(0.3).timeout
	
	var effect3: int = Effect.create_colored("VoodooAura.mdl", x, y, 0, 0, 5, Color8(1, 255, 255, 255))
	Effect.set_lifetime(effect3, 0.5)


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
	var dmg_mod_buff: Buff = target.get_buff_of_type(maj_planar_dmg_mod_bt)

#	Check if the tower cast the buff since the last time this projectile hit.
	if tower.get_buff_of_type(maj_planar_eruption_bt) != null && p.user_int3 == 0:
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
			target.modify_property(Modification.Type.MOD_DMG_FROM_ASTRAL, dmg_mod)

			if dmg_mod_buff != null:
				dmg_mod_buff.user_real += dmg_mod
			else:
				dmg_mod_buff = maj_planar_dmg_mod_bt.apply(tower, target, 0)
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
func maj_planar_dmg_mod_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	buffed_unit.modify_property(Modification.Type.MOD_DMG_FROM_ASTRAL, -buff.user_real)
