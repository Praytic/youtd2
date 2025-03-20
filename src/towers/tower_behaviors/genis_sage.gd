extends TowerBehavior


var swarm_st: SpellType
var speedcast_bt: BuffType
var spread_bt: BuffType
var magic_boost_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 7.0)


func tower_init():
	speedcast_bt = BuffType.new("speedcast_bt", 3.5, 0.1, true, self)
	var mock_genis_speedcast_mod: Modifier = Modifier.new()
	mock_genis_speedcast_mod.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.25, 0.01)
	mock_genis_speedcast_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.25, 0.01)
	speedcast_bt.set_buff_modifier(mock_genis_speedcast_mod)
	speedcast_bt.set_buff_icon("res://resources/icons/generic_icons/holy_grail.tres")
	speedcast_bt.set_buff_tooltip("Speed Cast\n.Increases trigger chances and attack speed.")

	spread_bt = CbStun.new("spread_bt", 0.8, 0, false, self)
	spread_bt.add_event_on_create(spread_bt_on_create)
	spread_bt.add_event_on_cleanup(spread_bt_on_cleanup)
	spread_bt.set_buff_tooltip("Spread\nStunned.")

	magic_boost_bt = BuffType.new("magic_boost_bt", 3, 0, true, self)
	var mock_genis_magic_boost_mod: Modifier = Modifier.new()
	mock_genis_magic_boost_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.2, 0.01)
	magic_boost_bt.set_buff_modifier(mock_genis_magic_boost_mod)
	magic_boost_bt.set_buff_icon("res://resources/icons/generic_icons/gold_bar.tres")
	magic_boost_bt.set_buff_tooltip("Magic Boost\nIncreases spell damage.")

	swarm_st = SpellType.new(SpellType.Name.CARRION_SWARM, 1, self)
	swarm_st.data.swarm.damage = 1.0
	swarm_st.data.swarm.start_radius = 100
	swarm_st.data.swarm.end_radius = 300
	swarm_st.data.swarm.travel_distance = 1200
	swarm_st.data.swarm.effect_path = "res://src/effects/moonwell_target.tscn"


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	var aqua_edge_chance: float = 0.20 + 0.006 * level
	var x2: float = target.get_x()
	var y2: float = target.get_y()
	var x: float = tower.get_x()
	var y: float = tower.get_y()
	var facing: float = rad_to_deg(atan2(y2 - y, x2 - x))
	var angle: float = -20
	var edge_damage: float = 1500 + 150 * level

	if !tower.calc_chance(aqua_edge_chance):
		return

	if tower.get_mana() < 15:
		return

	CombatLog.log_ability(tower, target, "Aqua Edge")

	tower.subtract_mana(15, false)

	while true:
		if angle > 20:
			break

		var edge_angle: float = deg_to_rad(facing + angle)

		swarm_st.point_cast_from_caster_on_point(tower, Vector2(x + 25 * cos(edge_angle), y + 25 * sin(edge_angle)), edge_damage, tower.calc_spell_crit_no_bonus())

		angle += 20

	speedcast()


func on_damage(event: Event):
	var creep: Unit = event.get_target()
	var level: int = tower.get_level()
	var spread_chance: float = 0.10 + 0.002 * level

	if !tower.calc_chance(spread_chance):
		return

	if tower.get_mana() < 40:
		return

	CombatLog.log_ability(tower, creep, "Spread")

	tower.subtract_mana(40, false)

	Effect.create_simple_at_unit("res://src/effects/naga_death.tscn", creep)

#	NOTE: call calc_spell_crit_no_bonus() one time so that
#	all AoE has same crit value
	var spread_damage: float = 3000 + 200 * level
	var crit_ratio: float = tower.calc_spell_crit_no_bonus()

	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), creep, 250)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		tower.do_spell_damage(next, spread_damage, crit_ratio)
		spread_bt.apply(tower, next, 0)

	speedcast()


func periodic(_event: Event):
	var level: int = tower.get_level()
	var magic_boost_chance: float = 0.3

	if !tower.calc_chance(magic_boost_chance):
		return

	if tower.get_mana() < 40:
		return

	CombatLog.log_ability(tower, null, "Magic Boost")

	tower.subtract_mana(40, false)

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 350)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		magic_boost_bt.apply(tower, next, level)

	speedcast()


func speedcast():
	var speedcast_chance: float = 0.15

	if !tower.calc_chance(speedcast_chance):
		return

	CombatLog.log_ability(tower, null, "Speedcast")

	speedcast_bt.apply(tower, tower, tower.get_level())


func spread_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Unit = buff.get_caster()
	var creep: Creep = buff.get_buffed_unit()
	var adjust_speed: float = 300 / (0.4 * caster.get_prop_buff_duration()) * creep.get_prop_debuff_duration()
	creep.adjust_height(300, adjust_speed)


func spread_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Unit = buff.get_caster()
	var creep: Creep = buff.get_buffed_unit()
	var adjust_speed: float = 300 / (0.4 * caster.get_prop_buff_duration()) * creep.get_prop_debuff_duration()
	creep.adjust_height(-300, adjust_speed)
