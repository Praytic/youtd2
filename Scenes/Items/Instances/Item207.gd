# M.E.F.I.S. Rocket
extends Item


# NOTE: changed the 2nd "one_shot" arg passed to
# enable_advanced(). Original script passes "true" but this
# causes the tower to not fire projectiles in youtd2 engine.
# Not sure if the JASS engine processes the "one_shot" arg
# in some weird way.


var PT: ProjectileType
var MB: MultiboardValues


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Anti-Immunity Missile[/color]\n"
	text += "Fires immune-seeking missiles. The attack range, speed, damage and type is the same as the carrier's, unless the attack type is Magic, which is dealt as Essence damage. Damage is scaled by 20% of the tower's spell damage.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.8% scaling\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 0.1)


func hit_PT(P: Projectile, U: Unit):
	var T: Tower = P.get_caster()
	T.do_custom_attack_damage(U, P.user_real, T.calc_attack_multicrit(0, 0, 0), P.user_int)


func item_init():
	PT = ProjectileType.create_interpolate("TinkerRocketMissile.mdl", 1000, self)
	PT.set_event_on_interpolation_finished(hit_PT)

	MB = MultiboardValues.new(1)
	MB.set_key(0, "Damage")


func on_pickup():
	var itm: Item = self
	var T: Tower = itm.get_carrier()

	if T.get_attack_type() != AttackType.enm.MAGIC:
		itm.user_int = T.get_attack_type()
	else:
		itm.user_int = AttackType.enm.ESSENCE


func on_tower_details() -> MultiboardValues:
	var itm: Item = self
	var T: Tower = itm.get_carrier()
	var dmg: float = T.get_current_attack_damage_with_bonus() * ( T.get_prop_spell_damage_dealt() * (0.2 + 0.008 * T.get_level()))
	MB.set_value(0, Utils.format_float(dmg, 0))

	return MB


func periodic(event: Event):
	var itm: Item = self
	var T: Tower = itm.get_carrier()
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
	P = Projectile.create_linear_interpolation_from_unit_to_unit(PT, T, 1.0, 1.0, T, U, 0.35, true)
	P.user_real = dmg
	P.user_int = itm.user_int
