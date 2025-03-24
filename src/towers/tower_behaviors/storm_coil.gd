extends TowerBehavior


var surge_bt: BuffType
var slow_bt: BuffType
var aura_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	slow_bt = BuffType.new("slow_bt", 1.5, 0, false, self)
	var slow_bt_mod: Modifier = Modifier.new()
	slow_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.0001)
	slow_bt.set_buff_modifier(slow_bt_mod)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	slow_bt.set_buff_tooltip(tr("MBIW"))

	surge_bt = BuffType.new("surge_bt", 4.0, 0.1, true, self)
	surge_bt.set_buff_icon("res://resources/icons/generic_icons/rss.tres")
	surge_bt.add_periodic_event(surge_bt_periodic, 0.4)
	surge_bt.set_buff_tooltip(tr("PHHY"))

	aura_bt = BuffType.create_aura_effect_type("aura_bt", false, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/electric.tres")
	aura_bt.add_event_on_damaged(aura_bt_on_damaged)
	aura_bt.set_buff_tooltip(tr("ZF40"))


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var distance_to_target: float = tower.get_position_wc3_2d().distance_to(target.get_position_wc3_2d())
	var damage: float = distance_to_target * 12.0 * tower.get_current_attack_damage_with_bonus() / tower.get_base_damage()

	tower.do_attack_damage(target, damage, tower.calc_attack_multicrit_no_bonus())
	tower.get_player().display_floating_text_x(str(int(damage)), target, Color8(255, 200, 0, 255), 0.05, 0.0, 2.0)

	var slow_buff_level: int = floori(distance_to_target * 3)
	slow_bt.apply(tower, target, slow_buff_level)


func on_autocast(event: Event):
	var creep: Unit = event.get_target()

	var buff: Buff = surge_bt.apply(tower, creep, tower.get_level())
	buff.user_real = creep.get_x()
	buff.user_real2 = creep.get_y()


func surge_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var surge_pos: Vector2 = Vector2(buff.user_real, buff.user_real2)
	var distance_to_target: float = surge_pos.distance_to(target.get_position_wc3_2d())
	var damage: float = 4 * distance_to_target * (1 + 0.02 * tower.get_level())

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())
	tower.get_player().display_floating_text_x(str(int(damage)), target, Color8(150, 150, 255, 255), 0.05, 0.0, 2.0)
	Effect.create_simple_at_unit("res://src/effects/spell_ailb.tscn", target)


func aura_bt_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var tower_pos: Vector2 = tower.get_position_wc3_2d()
	var target_pos: Vector2 = target.get_position_wc3_2d()
	var distance_to_target: float = tower_pos.distance_to(target_pos)
	var damage_multiplier: float = 1.0 + distance_to_target * (0.00020 + 0.000006 * tower.get_level())
	var attacking_tower: Tower = event.get_target()
	var attacking_element: Element.enm = attacking_tower.get_element()

	if attacking_element == Element.enm.STORM:
		event.damage *= damage_multiplier
