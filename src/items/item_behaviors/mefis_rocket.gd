extends ItemBehavior


# NOTE: changed the 2nd "one_shot" arg passed to
# enable_advanced(). Original script passes "true" but this
# causes the tower to not fire projectiles in youtd2 engine.
# Not sure if the JASS engine processes the "one_shot" arg
# in some weird way.


var rocket_pt: ProjectileType
var multiboard: MultiboardValues


func get_ability_description() -> String:
	var arcane_string: String = AttackType.convert_to_colored_string(AttackType.enm.ARCANE)
	var essence_string: String = AttackType.convert_to_colored_string(AttackType.enm.ESSENCE)
	
	var text: String = ""

	text += "[color=GOLD]Anti-Immunity Missile[/color]\n"
	text += "Fires immune-seeking missiles. The attack range, speed, damage and type is the same as the carrier's, unless the attack type is %s, which is dealt as %s damage. Damage is scaled by 20%% of the tower's spell damage.\n" % [arcane_string, essence_string]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.8% scaling\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 0.1)


# NOTE: hitPT() in original script
func rocket_pt_on_hit(P: Projectile, U: Unit):
	if U == null:
		return

	var T: Tower = P.get_caster()
	T.do_custom_attack_damage(U, P.user_real, T.calc_attack_multicrit(0, 0, 0), P.user_int)


func item_init():
	rocket_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 1000, self)
	rocket_pt.set_event_on_interpolation_finished(rocket_pt_on_hit)

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Damage")


func on_pickup():
	var T: Tower = item.get_carrier()

	if T.get_attack_type() != AttackType.enm.ARCANE:
		item.user_int = T.get_attack_type()
	else:
		item.user_int = AttackType.enm.ESSENCE


func on_tower_details() -> MultiboardValues:
	var tower: Tower = item.get_carrier()
	var dmg: float = tower.get_current_attack_damage_with_bonus() * ( tower.get_prop_spell_damage_dealt() * (0.2 + 0.008 * tower.get_level()))
	multiboard.set_value(0, Utils.format_float(dmg, 0))

	return multiboard


func periodic(event: Event):
	var T: Tower = item.get_carrier()
	var I: Iterate = Iterate.over_units_in_range_of_caster(T, TargetType.new(TargetType.CREEPS), T.get_range())
	var U: Unit
	var dmg: float
	var P: Projectile

	event.enable_advanced(T.get_current_attack_speed(), false)

	while true:
		U = I.next()

		if U == null:
			return

		if U.is_immune():
			break

	dmg = T.get_current_attack_damage_with_bonus() * (T.get_prop_spell_damage_dealt() * (0.2 + 0.008 * T.get_level()))
	P = Projectile.create_linear_interpolation_from_unit_to_unit(rocket_pt, T, 1.0, 1.0, T, U, 0.35, true)
	P.user_real = dmg
	P.user_int = item.user_int
