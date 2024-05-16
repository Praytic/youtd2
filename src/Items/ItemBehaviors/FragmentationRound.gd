extends ItemBehavior


var frag_pt: ProjectileType
var frag_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Fragmentation Round[/color]\n"
	text += "Whenever the carrier hits the main target, it has a 40% chance to hit up to 2 other creeps within 500 range of the main target with fragments. Fragments deal 45% of the attack damage and cause creeps to take 40% more damage from further fragments for the next 5 seconds. Fragments also cause creeps to take 40% extra damage from splash attacks for the next 5 seconds.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


# NOTE: PT_Hit() in original script
func frag_pt_on_hit(P: Projectile, U: Unit):
	if U == null:
		return

	var T: Tower = P.get_caster()
	var B: Buff = U.get_buff_of_type(frag_bt)

	if B != null:
		P.user_real = P.user_real * 1.40

	var buff_level: int
	if B != null:
		buff_level = B.get_level()
	else:
		buff_level = 0
	
	T.do_attack_damage(U, P.user_real * 0.45, 1.0)

	frag_bt.apply(T, U, buff_level)


# NOTE: BT_DMG() in original script
func frag_bt_on_damaged(event: Event):
	if event.is_main_target() == false && event.is_spell_damage() == false:
		event.damage = event.damage * 1.40


func item_init():
	frag_pt = ProjectileType.create("BloodElfSpellThiefMISSILE.mdl", 0.0, 1000.0, self)
	frag_pt.enable_homing(frag_pt_on_hit, 0.1)

	frag_bt = BuffType.new("frag_bt", 5.0, 0.0, false, self)
	frag_bt.set_buff_icon("res://resources/icons/GenericIcons/mine_explosion.tres")
	frag_bt.set_buff_tooltip("Fragment Hit\nIncreases damage taken from Fragmentation Rounds and splash attacks.")
	frag_bt.add_event_on_damaged(frag_bt_on_damaged)


func on_damage(event: Event):
	var tower: Unit = item.get_carrier()

	var fragmentation_round_chance: float = 0.40

	if !tower.calc_chance(fragmentation_round_chance):
		return

	CombatLog.log_item_ability(item, null, "Fragmentation Round")

	var I: Iterate
	var U: Unit
	var Targ: Unit
	var i: int = 2

	if event.is_main_target():
		Targ = event.get_target()
		I = Iterate.over_units_in_range_of_unit(item.get_carrier(), TargetType.new(TargetType.CREEPS), Targ, 500)

		while true:
			U = I.next()

			if U == null:
				break

			if U != Targ:
				var projectile: Projectile = Projectile.create_from_unit_to_unit(frag_pt, item.get_carrier(), 1.0, 1.0, Targ, U, true, false, true)
				projectile.user_real = event.damage
				i = i - 1

				if i == 0:
					break
