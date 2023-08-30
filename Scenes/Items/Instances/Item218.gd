# Blaster Staff
extends Item

var PT: ProjectileType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Blasting Attack[/color]\n"
	text += "The staff launches a magical missile each second which deals 60 spelldamage. The staff has a range of 1000.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 1.0)


func Collision(P: Projectile, targ: Unit):
	P.get_caster().do_spell_damage(targ, 60.00, P.get_caster().calc_spell_crit_no_bonus()) 


func item_init():
	PT = ProjectileType.create("Abilities\\Weapons\\DruidoftheTalonMissile\\DruidoftheTalonMissile.mdl", 4.00, 1400.00)
	PT.enable_homing(Collision, 0.0)


func periodic(_event: Event):
	var itm: Item = self

	var U: Unit = itm.get_carrier()
	var I: Iterate = Iterate.over_units_in_range_of_unit(U, TargetType.new(TargetType.CREEPS), U, 1000.0)
	var T: Unit = I.next()

	if T != null:
		Projectile.create_from_unit_to_unit(PT, U, 1.00, U.calc_spell_crit_no_bonus(), U, T, true, false, false)
