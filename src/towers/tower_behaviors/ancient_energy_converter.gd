extends TowerBehavior


# NOTE: original script is missing the implementation for
# damage dealt by orbs. It might be implemented as this
# call: "p.addAbility('@@0@@')". Not sure. Wrote an
# implementation for this ability effect from scratch.


var stun_bt: BuffType
var chain_lightning_st: SpellType
var orb_pt: ProjectileType


func tower_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)

	chain_lightning_st = SpellType.new(SpellType.Name.CHAIN_LIGHTNING, 5.0, self)
	chain_lightning_st.set_damage_event(chain_lightning_st_on_damage)
	chain_lightning_st.data.chain_lightning.damage = 1500
	chain_lightning_st.data.chain_lightning.damage_reduction = 0.25
	chain_lightning_st.data.chain_lightning.chain_count = 4

	orb_pt = ProjectileType.create("path_to_projectile_sprite", 12, 250, self)
	orb_pt.enable_periodic(orb_pt_periodic, 1.0)


func on_autocast(_event: Event):
	var level: int = tower.get_level()
	var projectile_count: int = 3 + level / 5

	var start_rotation: float = 1.2 * (Globals.synced_rng.randi_range(0, 1) * 2 - 1)
	orb_pt.set_start_rotation(start_rotation)

	for i in range(0, projectile_count):
		var p: Projectile = Projectile.create(orb_pt, tower, 1.0 + 0.05 * level, tower.calc_spell_crit_no_bonus(), tower.get_position_wc3(), i * 360 / projectile_count)
		p.set_projectile_scale(2.0)


func orb_pt_periodic(p: Projectile):
	var lightning_chance: float = 0.25

	var it_for_lightning: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), Vector2(p.get_x(), p.get_y()), 650.0)

	var lightning_target: Unit = it_for_lightning.next_random()

	if lightning_target != null:
		var lightning: InterpolatedSprite = InterpolatedSprite.create_from_point_to_unit(InterpolatedSprite.LIGHTNING, p.get_position_wc3(), lightning_target)
		lightning.modulate = Color.YELLOW
		lightning.set_lifetime(0.1)

		var orb_damage: float = 1500 + 75 * tower.get_level()
		tower.do_spell_damage(lightning_target, orb_damage, tower.calc_spell_crit_no_bonus())

	if !tower.calc_chance(lightning_chance):
		return

	var it_for_chain: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), Vector2(p.get_x(), p.get_y()), 650.0)

	var chain_target: Unit = it_for_chain.next()

	if chain_target != null:
		chain_lightning_st.target_cast_from_point(tower, chain_target, Vector2(p.get_x(), p.get_y()), p.get_dmg_ratio(), p.get_crit_ratio())


func chain_lightning_st_on_damage(event: Event, _dummy_unit: DummyUnit):
	var target: Unit = event.get_target()
	stun_bt.apply_only_timed(tower, target, 0.8)
