extends TowerBehavior


var grapple_bt: BuffType
var shock_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	grapple_bt = CbStun.new("grapple_bt", 2.5, 0, false, self)
	grapple_bt.set_buff_icon("res://resources/icons/generic_icons/pokecog.tres")
	grapple_bt.add_event_on_create(grapple_bt_on_create)
	grapple_bt.add_event_on_cleanup(grapple_bt_on_cleanup)

	shock_bt = CbStun.new("shock_bt", 2.5, 0, false, self)
	shock_bt.set_buff_icon("res://resources/icons/generic_icons/atomic_slashes.tres")


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var grapple_chance: float = 0.08 + 0.0032 * tower.get_level()

	var grapple_duration: float
	if target.get_size() >= CreepSize.enm.CHAMPION:
		grapple_duration = 0.9
	else:
		grapple_duration = 2.5

	if !tower.calc_chance(grapple_chance):
		return

	CombatLog.log_ability(tower, target, "Grapple")

	grapple_bt.apply_only_timed(tower, target, grapple_duration)


func on_autocast(event: Event):
	var target: Unit = event.get_target()
	var shock_damage: float = 1250 + 185 * tower.get_level()

	Effect.create_simple_at_unit("res://src/effects/thunder_clap.tscn", target)

	tower.do_spell_damage_aoe_unit(target, 250, shock_damage, tower.calc_spell_crit_no_bonus(), 0.5)

	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 250)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		shock_bt.apply_only_timed(tower, next, 2.0)


func grapple_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var caster: Unit = buff.get_caster()

	var lightning_start: Vector3 = Vector3(caster.get_x(), caster.get_y(), 100)
	var lightning_end: Vector3 = Vector3(target.get_x(), target.get_y(), 0)
	var lightning: InterpolatedSprite = InterpolatedSprite.create_from_point_to_point(InterpolatedSprite.LIGHTNING, lightning_start, lightning_end)
	buff.user_int = lightning.get_instance_id()


func grapple_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var lightning_id: int = buff.user_int

	var lightning_object: Object = instance_from_id(lightning_id)

	if lightning_object != null:
		var lightning_node: Node = lightning_object as Node
		lightning_node.queue_free()
