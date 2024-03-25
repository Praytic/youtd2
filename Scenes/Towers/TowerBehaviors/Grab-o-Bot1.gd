extends TowerBehavior


var cedi_bot_grapple_bt: BuffType
var cedi_bot_stun_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Grapple[/color]\n"
	text += "Each time the bot attacks there is an 8% chance it will grab the target, holding it in place for 2.5 seconds. The duration is reduced to 0.9 seconds for champions and bosses.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.32% chance\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Grapple[/color]\n"
	text += "Chance to grab the target, holding it in place for 2.5 seconds.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "Slams all creeps in 250 AoE around the target, dealing 1250 spell damage and stunning for 2 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+185 damage\n"

	return text


func get_autocast_description_short() -> String:
	return "Slams all creeps in around the target, dealing damage and stunning them.\n"


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(_modifier: Modifier):
	tower.set_attack_style_splash({
		75: 1.00,
		100: 0.66,
		125: 0.33,
		})


func tower_init():
	cedi_bot_grapple_bt = CbStun.new("cedi_bot_grapple_bt", 2.5, 0, false, self)
	cedi_bot_grapple_bt.set_buff_icon("@@0@@")
	cedi_bot_grapple_bt.add_event_on_create(cedi_bot_grapple_bt_on_create)
	cedi_bot_grapple_bt.add_event_on_cleanup(cedi_bot_grapple_bt_on_cleanup)

	cedi_bot_stun_bt = CbStun.new("cedi_bot_stun_bt", 2.5, 0, false, self)
	cedi_bot_stun_bt.set_buff_icon("@@1@@")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Shock"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.num_buffs_before_idle = 1
	autocast.cast_range = 900
	autocast.auto_range = 900
	autocast.cooldown = 15
	autocast.mana_cost = 50
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast
	tower.add_autocast(autocast)


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

	cedi_bot_grapple_bt.apply_only_timed(tower, target, grapple_duration)


func on_autocast(event: Event):
	var target: Unit = event.get_target()
	var shock_damage: float = 1250 + 185 * tower.get_level()

	var effect: int = Effect.create_simple_at_unit("ThunderClapCaster.mdl", target)
	Effect.destroy_effect_after_its_over(effect)

	tower.do_spell_damage_aoe_unit(target, 250, shock_damage, tower.calc_spell_crit_no_bonus(), 0.5)

	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 250)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		cedi_bot_stun_bt.apply_only_timed(tower, next, 2.0)


func cedi_bot_grapple_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var caster: Unit = buff.get_caster()

	var lightning_start: Vector3 = Vector3(caster.get_visual_x(), caster.get_visual_y(), 100)
	var lightning_end: Vector3 = Vector3(target.get_visual_x(), target.get_visual_y(), 0)
	var lightning: InterpolatedSprite = InterpolatedSprite.create_from_point_to_point(InterpolatedSprite.LIGHTNING, lightning_start, lightning_end)
	buff.user_int = lightning.get_instance_id()


func cedi_bot_grapple_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var lightning_id: int = buff.user_int

	var lightning_object: Object = instance_from_id(lightning_id)

	if lightning_object != null:
		var lightning_node: Node = lightning_object as Node
		lightning_node.queue_free()
