extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] Fixed tower details displaying
# dmg bonus from gold hoarded incorrectly. It was dividing
# by 100 instead of 5000.


var wyrm_pt: ProjectileType
var multiboard: MultiboardValues
var fireball_cd: int = 0


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_kill(on_kill)


func tower_init():
	multiboard = MultiboardValues.new(3)
	var gold_hoarded_label: String = tr("GRZ6")
	var bonus_damage_label: String = tr("YQK4")
	var atks_to_fireballs_label: String = tr("CE54")
	multiboard.set_key(0, gold_hoarded_label)
	multiboard.set_key(1, bonus_damage_label)
	multiboard.set_key(2, atks_to_fireballs_label)

	wyrm_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 700, self)
	wyrm_pt.set_event_on_interpolation_finished(wyrm_pt_on_hit)


func on_attack(_event: Event):
	var level: int = tower.get_level()

#	check if 0 attacks remain till fireballs
	if fireball_cd > 0:
		fireball_cd -= 1
	else:
#		setting minimum number of attacks before next fireballs
		if level == 25:
			fireball_cd = 5
		elif level >= 15:
			fireball_cd = 6
		else:
			fireball_cd = 7

#		set +0,+1 or +2 attacks and release bolts afterwards
		fireball_cd += Globals.synced_rng.randi_range(0, 4)

		if level >= 10:
			release_fireballs(4)
		else:
			release_fireballs(3)


func on_kill(event: Event):
	var creep: Creep = event.get_target()
	var value: float = 0.75 * creep.get_base_bounty_value() * creep.get_prop_bounty_granted() * tower.get_prop_bounty_received()
	var hoard_size: float = 90000

	if tower.user_real >= hoard_size:
		value = 0
	elif tower.user_real + value > hoard_size:
		value = hoard_size - tower.user_real

	if value != 0:
		sir_update(value)
		tower.get_player().give_gold(-value, tower, true, false)


func on_create(preceding: Tower):
#	Somebody might replace this tower with this tower
	tower.user_real = 0
	if preceding != null && preceding.get_family() == tower.get_family():
		sir_update(preceding.user_real)

#	Mediocre cd for first wave of fireballs
	fireball_cd = 9


func on_tower_details() -> MultiboardValues:
	var gold_hoard_string: String = Utils.format_float(tower.user_real, 0)
	var dmg_bonus_string: String = Utils.format_percent(tower.user_real / 5000, 0)
	var fireball_cd_string: String = str(fireball_cd)

	multiboard.set_value(0, gold_hoard_string)
	multiboard.set_value(1, dmg_bonus_string)
	multiboard.set_value(2, fireball_cd_string)

	return multiboard


func sir_update(new_gold: float):
	tower.modify_property(ModificationType.enm.MOD_DAMAGE_BASE_PERC, -tower.user_real / 5000)
	tower.modify_property(ModificationType.enm.MOD_SPELL_DAMAGE_DEALT, -tower.user_real / 5000)
	tower.user_real += new_gold
	tower.modify_property(ModificationType.enm.MOD_DAMAGE_BASE_PERC, tower.user_real / 5000)
	tower.modify_property(ModificationType.enm.MOD_SPELL_DAMAGE_DEALT, tower.user_real / 5000)


func wyrm_pt_on_hit(p: Projectile, _target: Unit):
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

	tower.do_spell_damage_aoe(Vector2(p.get_x(), p.get_y()), radius, damage, tower.calc_spell_crit(crit_mod, 0), 0)


func release_fireballs(fireball_count: int):
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 950)
	var last_target: Unit = null

	CombatLog.log_ability(tower, null, "Fireballs count=%d" % fireball_count)

	while true:
		var next: Unit = it.next_random()

		if next == null:
			break

		var p: Projectile = Projectile.create_bezier_interpolation_from_unit_to_unit(wyrm_pt, tower, 1, 1, tower, next, 0, Globals.synced_rng.randf_range(-0.35, 0.35), Globals.synced_rng.randf_range(0.17, 0.4), true)
		p.set_projectile_scale(2.0)

		fireball_count -= 1

		last_target = next

		if fireball_count == 0:
			break

	if fireball_count > 0:
		if last_target != null:
# 			Shoot remaining balls at last target
			for i in range(0, fireball_cd):
				var p: Projectile = Projectile.create_bezier_interpolation_from_unit_to_unit(wyrm_pt, tower, 1, 1, tower, last_target, 0, Globals.synced_rng.randf_range(-0.35, 0.35), Globals.synced_rng.randf_range(0.17, 0.4), true)
				p.set_projectile_scale(2.0)
		else:
# 			Shoot remaining balls during next attack
			fireball_cd = 0
