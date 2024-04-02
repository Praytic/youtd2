# Overcharge Shot
extends ItemBehavior


var cedi_overcharge_pt: ProjectileType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Overcharge Shot[/color]\n"
	text += "This tower's attack continues for 350 units through the main target, dealing 35% of the tower's attack damage to any creep in its path.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% damage\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


# NOTE: PT_Hit() in original script
func cedi_overcharge_pt_on_collision(P: Projectile, U: Unit):
	var T: Tower

	if U.get_instance_id() != P.user_int:
#		Not the original target
		T = P.get_caster()
		T.do_attack_damage(U, P.user_real, T.calc_attack_multicrit(0, 0, 0))


func item_init():
	cedi_overcharge_pt = ProjectileType.create_ranged("FireLordDeathExplode.mdl", 350.0, 1000.0, self)
	cedi_overcharge_pt.enable_collision(cedi_overcharge_pt_on_collision, 75.0, TargetType.new(TargetType.CREEPS), false)


func on_damage(event: Event):
	var angle: float
	var C: Creep
	var T: Tower
	var P: Projectile

	if event.is_main_target():
		T = item.get_carrier()
		C = event.get_target()
		angle = rad_to_deg(atan2(C.global_position.y - T.global_position.y, C.global_position.x - T.global_position.x))
		P = Projectile.create_from_unit(cedi_overcharge_pt, T, C, angle, 1.0, 1.0)
		P.user_int = C.get_instance_id()
		P.user_real = T.get_current_attack_damage_with_bonus() * (0.35 + 0.006 * T.get_level())
