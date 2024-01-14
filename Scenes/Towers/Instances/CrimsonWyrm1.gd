extends Tower


# NOTE: fixed bug in original script. Tower details
# displayed dmg bonus from gold hoarded incorrectly, it was
# dividing by 100 instead of 5000.


var wyrm_pt: ProjectileType
var multiboard: MultiboardValues
var gold_hoard: float = 0
var fireball_cd: int = 0


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Flaming Inferno[/color]\n"
	text += "Every [color=GOLD]7th-11th[/color] attack releases 3 fireballs that fly towards random targets in 950 range, dealing 3750 spelldamage in 250 AoE around the target on impact.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+150 spelldamage\n"
	text += "-1 minimum and maximum attack needed at levels 15 and 25\n"
	text += "+1 fireball at level 10\n"
	text += "+5% bonus crit chance at levels 5 and 20\n"
	text += " \n"

	text += "[color=GOLD]Dragon's Hoard[/color]\n"
	text += "Whenever the Crimson Wyrm kills a creep it hoards 75% of the bounty. The hoard has a maximum capacity of 90000 gold and grants [color=GOLD][gold hoarded / 50]%[/color] spelldamage and base attackdamage.\n" 
	text += "[color=GOLD]Hint:[/color] This ability is modified by both the creep's and this tower's bounty ratios.\n" 

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Flaming Inferno[/color]\n"
	text += "Occasionally releases fireballs that deal AoE damage.\n"
	text += " \n"

	text += "[color=GOLD]Dragon's Hoard[/color]\n"
	text += "Whenever the Crimson Wyrm kills a creep it hoards 75% of the bounty.\n" 

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_kill(on_kill)


func tower_init():
	multiboard = MultiboardValues.new(3)
	multiboard.set_key(0, "Gold Hoarded")
	multiboard.set_key(1, "Bonus Damage")
	multiboard.set_key(2, "Atks to Fireballs")

	wyrm_pt = ProjectileType.create_interpolate("FireBallMissile.mdl", 700, self)
	wyrm_pt.set_event_on_interpolation_finished(wyrm_pt_on_hit)


func on_attack(_event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()

#	check if 0 attacks remain till fireballs
	if tower.fireball_cd > 0:
		tower.fireball_cd -= 1
	else:
#		setting minimum number of attacks before next fireballs
		if level == 25:
			fireball_cd = 5
		elif level >= 15:
			fireball_cd = 6
		else:
			fireball_cd = 7

#		set +0,+1 or +2 attacks and release bolts afterwards
		fireball_cd += randi_range(0, 4)

		if level >= 10:
			release_fireballs(4)
		else:
			release_fireballs(3)


func on_kill(event: Event):
	var tower: Tower = self
	var creep: Creep = event.get_target()
	var value: float = 0.75 * creep.get_base_bounty_value() * creep.get_prop_bounty_granted() * tower.get_prop_bounty_received()
	var hoard_size: float = 90000

	if tower.gold_hoard >= hoard_size:
		value = 0
	elif tower.gold_hoard + value > hoard_size:
		value = hoard_size - tower.gold_hoard

	if value != 0:
		sir_update(value)
		tower.get_player().give_gold(-value, tower, false, false)
		SFX.sfx_at_unit("PileofGold.mdl", tower)


func on_create(preceding: Tower):
	var tower: Tower = self

#	Somebody might replace this tower with this tower
	if preceding != null && preceding.get_family() == tower.get_family():
		sir_update(preceding.gold_hoard)

#	Mediocre cd for first wave of fireballs
	tower.fireball_cd = 9


func on_tower_details() -> MultiboardValues:
	var gold_hoard_string: String = Utils.format_float(gold_hoard, 0)
	var dmg_bonus_string: String = Utils.format_percent(gold_hoard / 5000, 0)
	var fireball_cd_string: String = str(fireball_cd)

	multiboard.set_value(0, gold_hoard_string)
	multiboard.set_value(1, dmg_bonus_string)
	multiboard.set_value(2, fireball_cd_string)

	return multiboard


func sir_update(new_gold: float):
	var tower: Tower = self

	tower.modify_property(Modification.Type.MOD_DAMAGE_BASE_PERC, -tower.gold_hoard / 5000)
	tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -tower.gold_hoard / 5000)
	tower.gold_hoard += new_gold
	tower.modify_property(Modification.Type.MOD_DAMAGE_BASE_PERC, tower.gold_hoard / 5000)
	tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, tower.gold_hoard / 5000)


func wyrm_pt_on_hit(p: Projectile, _target: Unit):
	var tower: Tower = p.get_caster()
	var level: int = tower.get_level()

	var crit_mod: float
	if level >= 20:
		crit_mod = 0.10
	elif level >= 5 && level < 20:
		crit_mod = 0.05
	else:
		crit_mod = 0.00

	var radius: float = 250
	var damage: float = 3750 + 150 * level

	tower.do_spell_damage_aoe(p.get_x(), p.get_y(), radius, damage, tower.calc_spell_crit(crit_mod, 0), 0)


func release_fireballs(fireball_count: int):
	var tower: Tower = self
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 950)
	var last_target: Unit = null

	CombatLog.log_ability(tower, null, "Fireballs count=%d" % fireball_count)

	while true:
		var next: Unit = it.next_random()

		if next == null:
			break

		var p: Projectile = Projectile.create_bezier_interpolation_from_unit_to_unit(wyrm_pt, tower, 1, 1, tower, next, 0, randf_range(-0.35, 0.35), randf_range(0.17, 0.4), true)
		p.setScale(2.0)

		fireball_count -= 1

		last_target = next

		if fireball_count == 0:
			break

	if fireball_count > 0:
		if last_target != null:
# 			Shoot remaining balls at last target
			for i in range(0, fireball_cd):
				var p: Projectile = Projectile.create_bezier_interpolation_from_unit_to_unit(wyrm_pt, tower, 1, 1, tower, last_target, 0, randf_range(-0.35, 0.35), randf_range(0.17, 0.4), true)
				p.setScale(2.0)
		else:
# 			Shoot remaining balls during next attack
			tower.fireball_cd = 0
