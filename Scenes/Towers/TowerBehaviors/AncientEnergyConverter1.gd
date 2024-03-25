extends TowerBehavior

# TODO: the visual for chain lightning is a bit incorrect.
# It should start from projectile, instead it starts from
# tower. Need to rework chain lightning code so it can start
# from both units and positions.


var cb_stun: BuffType
var lightning_st: SpellType
var orb_pt: ProjectileType


func get_autocast_description() -> String:
	var text: String = ""

	text += "Spawns 3 orbs that last 12 seconds flying around the Converter. Each orb deals 1500 damage per second to random units in 650 range. Additionally, the orbs have a 25% chance every second to cast a chainlightining that deals 1500 initial damage and hits up to 4 targets dealing 25% less damage with each bounce.\n"
	text += "Units hit by the chainlightning are stunned for 0.8 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+75 orb damage\n"
	text += "+1 orb spawned per 5 levels\n"

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "Spawns 3 chain lightning orbs that fly around the Converter. Orbs deal damage and stun nearby units.\n"

	return text


func load_specials(modifier: Modifier):
	tower.set_attack_style_bounce(3, 0.70)
	modifier.add_modification(Modification.Type.MOD_MANA, 0, 25)


func tower_init():
	cb_stun = CbStun.new("ancient_energy_converter_stun", 0, 0, false, self)

	lightning_st = SpellType.new("@@0@@", "chainlightning", 5.0, self)
	lightning_st.set_damage_event(lightning_st_on_damage)
	lightning_st.data.chain_lightning.damage = 1500
	lightning_st.data.chain_lightning.damage_reduction = 0.25
	lightning_st.data.chain_lightning.chain_count = 4

	orb_pt = ProjectileType.create("ManaFlareTarget.mdl", 12, 250, self)
	orb_pt.enable_periodic(orb_pt_periodic, 1.0)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Energy Conversion"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
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
	tower.add_autocast(autocast)


func on_autocast(_event: Event):
	var level: int = tower.get_level()
	var projectile_count: int = 3 + level / 5
	var x: float = tower.get_visual_x()
	var y: float = tower.get_visual_y()

#	TODO: need to implement set_start_roation()
	# orb_pt.set_start_roation(1.2 * randi_range(1, 2))

	for i in range(0, projectile_count):
		var p: Projectile = Projectile.create(orb_pt, tower, 1.0 + 0.05 * level, tower.calc_spell_crit_no_bonus(), x, y, 80, i * 360 / projectile_count)
		p.setScale(2.0)


func orb_pt_periodic(p: Projectile):
	var lightning_chance: float = 0.25

	if !tower.calc_chance(lightning_chance):
		return

	var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), p.get_x(), p.get_y(), 650.0)
	var next: Unit = it.next()

	if next != null:
		lightning_st.target_cast_from_point(tower, next, p.get_x(), p.get_y(), p.get_dmg_ratio(), p.get_crit_ratio())


func lightning_st_on_damage(event: Event, _dummy_unit: DummyUnit):
	var target: Unit = event.get_target()
	cb_stun.apply_only_timed(tower, target, 0.8)
