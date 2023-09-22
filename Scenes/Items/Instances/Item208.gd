# Fragmentation Round
extends Item


var PT: ProjectileType
var BT: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Fragmentation Round[/color]\n"
	text += "On damage, the carrier of this item has a 40% chance to hit up to 2 other creeps within 500 range of the main target with fragments that deal 45% of the damage and cause hit creeps to take 40% more damage from further fragments and splash damage for the next 5 seconds.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func PT_hit(P: Projectile, U: Unit):
	var T: Tower = P.get_caster()
	var B: Buff = U.get_buff_of_type(BT)

	if B != null:
		P.user_real = P.user_real * 1.40

	T.do_attack_damage(U, P.user_real * 0.45, 1.0)

	BT.apply(T, U, B.get_level())


func BT_dmg(event: Event):
	if event.is_main_target() == false && event.is_spell_damage() == false:
		event.damage = event.damage * 1.40


func item_init():
	PT = ProjectileType.create_interpolate("BloodElfSpellThiefMISSILE.mdl", 1000.0, self)
	PT.enable_homing(PT_hit, 0.1)

	BT = BuffType.new("Item208_BT", 5.0, 0.0, false, self)
	BT.set_buff_icon("@@0@@")
	BT.add_event_on_damaged(BT_dmg)
	BT.set_buff_tooltip("Fragment Hit\nThis unit has been hit by a Fragment; it will take more damage from Fragmentation Rounds and splash damage.")


func on_damage(event: Event):
	var itm: Item = self

	var I: Iterate
	var U: Unit
	var Targ: Unit
	var i: int = 2

	if event.is_main_target():
		Targ = event.get_target()
		I = Iterate.over_units_in_range_of_unit(itm.get_carrier(), TargetType.new(TargetType.CREEPS), Targ, 500)

		while true:
			U = I.next()

			if U == null:
				break

			if U != Targ:
				var projectile: Projectile = Projectile.create_from_unit_to_unit(PT, itm.get_carrier(), 1.0, 1.0, Targ, U, true, false, true)
				projectile.user_real = event.damage
				i = i - 1

				if i == 0:
					break
