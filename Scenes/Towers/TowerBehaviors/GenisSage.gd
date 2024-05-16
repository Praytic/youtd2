extends TowerBehavior


# NOTE: original script did the "Aqua Edge" spell by casting
# it from tower to a point 25 distance units away from
# tower. Not sure if original engine made carrionswarm spell
# continue after reaching the end point. In youtd2 engine
# swarm spell stops at end point so casting 25 distance
# units away would make the aqua edges not reach any creeps.
# Changed it to cast 900 distance units away. Can look into
# it more later.


var swarm_st: SpellType
var speedcast_bt: BuffType
var spread_bt: BuffType
var magic_boost_bt: BuffType


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var speed_cast: AbilityInfo = AbilityInfo.new()
	speed_cast.name = "Speed Cast"
	speed_cast.icon = "res://resources/Icons/trinkets/trinket_01.tres"
	speed_cast.description_short = "Whenever Genis uses one of his abilities, he has a chance to increase trigger chances and attack speed.\n"
	speed_cast.description_full = "Whenever Genis uses one of his abilities, he has a 15% chance to increase his trigger chances and his attack speed by 25% for 3.5 seconds. This ability does not stack, but can be retriggered.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1% trigger chance\n" \
	+ "+1% attack speed\n" \
	+ "+0.1 seconds\n"
	list.append(speed_cast)

	var aqua_edge: AbilityInfo = AbilityInfo.new()
	aqua_edge.name = "Aqua Edge"
	aqua_edge.icon = "res://resources/Icons/animals/fish_02.tres"
	aqua_edge.description_short = "Each attack has a chance to launch 3 blades of water at target, which deal spell damage.\n"
	aqua_edge.description_full = "Each attack Genis has a 20% chance to launch 3 blades of water in front of him at different angles. Each blade deals 1500 spell damage to each creep it passes through. Costs 15 mana.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.6% chance\n" \
	+ "+150 spell damage\n"
	list.append(aqua_edge)

	var spread: AbilityInfo = AbilityInfo.new()
	spread.name = "Spread"
	spread.icon = "res://resources/Icons/magic/claw_02.tres"
	spread.description_short = "Whenever this tower hits a creep, it has a chance to lift up creeps near the main target and deal spell damage to affected creeps.\n"
	spread.description_full = "Whenever this tower hits a creep, it has a 10% chance to lift up creeps in 250 AoE around the main target for 0.8 seconds. Each creep is also dealt 3000 spell damage. Costs 40 mana.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.2% chance\n" \
	+ "+200 spell damage\n"
	list.append(spread)

	var magic_boost: AbilityInfo = AbilityInfo.new()
	magic_boost.name = "Magic Boost"
	magic_boost.icon = "res://resources/Icons/TowerIcons/StormBattery.tres"
	magic_boost.description_short = "Chance to increase spell damage of nearby towers.\n"
	magic_boost.description_full = "Every 7 seconds Genis has a 30% chance to increase the spell damage of all towers within 350 range of him by 20% for 3 seconds. Costs 10 mana.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1% spell damage\n"
	magic_boost.radius = 350
	magic_boost.target_type = TargetType.new(TargetType.TOWERS)
	list.append(magic_boost)

	return list


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
	speedcast_bt.set_buff_icon("res://resources/Icons/GenericIcons/holy_grail.tres")
	speedcast_bt.set_buff_tooltip("Speed Cast\n.Increases trigger chances and attack speed.")

	spread_bt = CbStun.new("spread_bt", 0.8, 0, false, self)
	spread_bt.add_event_on_create(spread_bt_on_create)
	spread_bt.add_event_on_cleanup(spread_bt_on_cleanup)
	spread_bt.set_buff_tooltip("Spread\nStunned.")

	magic_boost_bt = BuffType.new("magic_boost_bt", 3, 0, true, self)
	var mock_genis_magic_boost_mod: Modifier = Modifier.new()
	mock_genis_magic_boost_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.2, 0.01)
	magic_boost_bt.set_buff_modifier(mock_genis_magic_boost_mod)
	magic_boost_bt.set_buff_icon("res://resources/Icons/GenericIcons/gold_bar.tres")
	magic_boost_bt.set_buff_tooltip("Magic Boost\nIncreases spell damage.")

	swarm_st = SpellType.new("@@0@@", "carrionswarm", 1, self)
	swarm_st.data.swarm.damage = 1.0
	swarm_st.data.swarm.start_radius = 100
	swarm_st.data.swarm.end_radius = 300


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

		swarm_st.point_cast_from_caster_on_point(tower, Vector2(x + 900 * cos(edge_angle), y + 900 * sin(edge_angle)), edge_damage, tower.calc_spell_crit_no_bonus())

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

	SFX.sfx_at_unit("NagaDeath.mdl", creep)

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
