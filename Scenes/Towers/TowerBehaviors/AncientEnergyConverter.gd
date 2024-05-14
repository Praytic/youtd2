extends TowerBehavior


var stun_bt: BuffType
var lightning_st: SpellType
var orb_pt: ProjectileType


func load_specials(modifier: Modifier):
	tower.set_attack_style_bounce(3, 0.70)
	modifier.add_modification(Modification.Type.MOD_MANA, 0, 25)


func tower_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)

	lightning_st = SpellType.new("@@0@@", "chainlightning", 5.0, self)
	lightning_st.set_damage_event(lightning_st_on_damage)
	lightning_st.data.chain_lightning.damage = 1500
	lightning_st.data.chain_lightning.damage_reduction = 0.25
	lightning_st.data.chain_lightning.chain_count = 4

	orb_pt = ProjectileType.create("ManaFlareTarget.mdl", 12, 250, self)
	orb_pt.enable_periodic(orb_pt_periodic, 1.0)


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()
	
	autocast.title = "Energy Conversion"
	autocast.icon = "res://Resources/Icons/mechanical/battery.tres"
	autocast.description_short = "Spawns 3 chain lightning orbs that fly around the Converter. Orbs deal damage and stun nearby units.\n"
	autocast.description = "Spawns 3 orbs that last 12 seconds flying around the Converter. Each orb deals 1500 damage per second to random units in 650 range. Additionally, the orbs have a 25% chance every second to cast a chainlightining that deals 1500 initial damage and hits up to 4 targets dealing 25% less damage with each bounce.\n" \
	+ "Units hit by the chainlightning are stunned for 0.8 seconds.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+75 orb damage\n" \
	+ "+1 orb spawned per 5 levels\n"

	autocast.caster_art = "MassTeleportCaster.mdl"
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 0
	autocast.auto_range = 650
	autocast.cooldown = 12
	autocast.mana_cost = 1200
	autocast.target_self = false
	autocast.is_extended = true
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast
	
	return [autocast]


func on_autocast(_event: Event):
	var level: int = tower.get_level()
	var projectile_count: int = 3 + level / 5

	for i in range(0, projectile_count):
		var p: Projectile = Projectile.create(orb_pt, tower, 1.0 + 0.05 * level, tower.calc_spell_crit_no_bonus(), tower.get_position_wc3(), i * 360 / projectile_count)
		p.set_projectile_scale(2.0)


func orb_pt_periodic(p: Projectile):
	var lightning_chance: float = 0.25

	if !tower.calc_chance(lightning_chance):
		return

	var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), Vector2(p.get_x(), p.get_y()), 650.0)
	var next: Unit = it.next()

	if next != null:
		lightning_st.target_cast_from_point(tower, next, Vector2(p.get_x(), p.get_y()), p.get_dmg_ratio(), p.get_crit_ratio())


func lightning_st_on_damage(event: Event, _dummy_unit: DummyUnit):
	var target: Unit = event.get_target()
	stun_bt.apply_only_timed(tower, target, 0.8)
