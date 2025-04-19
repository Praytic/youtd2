extends TowerBehavior


# NOTE: SCALE_MIN must match the value in tower sprite
# scene
const SCALE_MIN: float = 0.5
const SCALE_MAX: float = 1.0

var stun_bt: BuffType
var morale_bt: BuffType
var grow_bt: BuffType
var rock_pt: ProjectileType
var multiboard: MultiboardValues
var grow_count: int = 0


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 25)


func tower_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)
	
	morale_bt = BuffType.new("morale_bt", 10, 0, true, self)
	morale_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	morale_bt.set_buff_tooltip(tr("Z5K1"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_DAMAGE_ADD_PERC, 0.10, 0.004)
	mod.add_modification(ModificationType.enm.MOD_ATTACKSPEED, 0.10, 0.004)
	morale_bt.set_buff_modifier(mod)

	grow_bt = BuffType.new("grow_bt", -1, 0, true, self)
	grow_bt.set_buff_icon("res://resources/icons/generic_icons/biceps.tres")
	grow_bt.set_buff_tooltip(tr("VCSG"))

	rock_pt = ProjectileType.create("path_to_projectile_sprite", 4, 700, self)
	rock_pt.enable_homing(rock_pt_on_hit, 0)

	multiboard = MultiboardValues.new(1)
	var grow_count_label: String = tr("D7GE")
	multiboard.set_key(0, grow_count_label)


func on_create(_preceding: Tower):
	var grow_buff: Buff = grow_bt.apply_to_unit_permanent(tower, tower, 0)
	grow_buff.set_displayed_stacks(grow_count)


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var chance: float = 0.25
	var enough_grow_count_for_landslide: bool = grow_count >= 20

	if !tower.calc_chance(chance):
		return

	if !enough_grow_count_for_landslide:
		return

	CombatLog.log_ability(tower, target, "Landslide")

	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 300)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		Projectile.create_from_unit_to_unit(rock_pt, tower, 1.0, 0.0, tower, next, true, false, false)


func on_damage(event: Event):
	var creep: Unit = event.get_target()
	var level: int = tower.get_level()
	var crush_damage: float = 5000 + 250 * level + 50 * grow_count

	var enough_grow_count_for_crush: bool = grow_count >= 10
	if !enough_grow_count_for_crush:
		return

	if !creep.is_stunned():
		return

	tower.do_spell_damage(creep, crush_damage, tower.calc_spell_crit_no_bonus())
	Effect.create_animated("res://src/effects/impale_target_dust.tscn", Vector3(creep.get_x(), creep.get_y(), 0.0), 0)

	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.TOWERS), tower, 500)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		morale_bt.apply(tower, next, level)


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, str(grow_count))

	return multiboard

func periodic(_event: Event):
	var level: int = tower.get_level()
	var reached_max_growth: bool = grow_count >= 160

	if reached_max_growth:
		return

	var effect: int = Effect.create_simple_at_unit("res://src/effects/roots.tscn", tower)
	Effect.set_lifetime(effect, 1.0)

	tower.modify_property(ModificationType.enm.MOD_DAMAGE_ADD_PERC, 0.03 + 0.001 * level)
	tower.add_exp(4)

	grow_count += 1

	var grow_buff: Buff = tower.get_buff_of_type(grow_bt)
	grow_buff.set_displayed_stacks(grow_count)

	var tower_scale: float = Utils.get_scale_from_grows(SCALE_MIN, SCALE_MAX, grow_count, 160)
	tower.set_unit_scale(tower_scale)


func rock_pt_on_hit(_projectile: Projectile, creep: Unit):
	if creep == null:
		return

	var damage: float = 700 + 50 * tower.get_level() + 15 * grow_count

	tower.do_spell_damage(creep, damage, tower.calc_spell_crit_no_bonus())
	stun_bt.apply_only_timed(tower, creep, 0.5)
