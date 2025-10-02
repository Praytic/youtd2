extends TowerBehavior


# NOTE: removed check for validity of poison caster. It's
# not needed because in youtd2, buffs get automatically
# removed when caster becomes invalid.


var poison_skin_bt: BuffType
var poison_bt: BuffType

const POISON_DURATION: float = 5.0


func get_tier_stats() -> Dictionary:
	return {
		1: {dmg = 3, dmg_add = 0.12},
		2: {dmg = 10, dmg_add = 0.4},
		3: {dmg = 30, dmg_add = 1.2},
		4: {dmg = 76.5, dmg_add = 3.06},
		5: {dmg = 127.5, dmg_add = 5.1},
	}


func poison_skin_bt_on_attack(event: Event):
	var poisonskin_buff: Buff = event.get_buff()

	var skink: Tower = poisonskin_buff.get_caster()
	var level: int = skink.get_level()
	var buffed_tower: Tower = poisonskin_buff.get_buffed_unit()
	var target: Unit = event.get_target()

	var active_buff: Buff = target.get_buff_of_type(poison_bt)

	var active_stacks: int = 0
	var active_damage: float = 0
	if active_buff != null:
		active_stacks = active_buff.user_int
		active_damage = active_buff.user_real

	var new_stacks: int = active_stacks + 1
	var attack_speed_and_range_adjustment: float = buffed_tower.get_current_attack_speed() / (buffed_tower.get_base_range() / 800.0)
	var added_damage: float = (_stats.dmg + _stats.dmg_add * level) * attack_speed_and_range_adjustment
	var new_damage: float = active_damage + added_damage

#	NOTE: weaker tier tower increases buff effect without
#	refreshing duration
	active_buff = poison_bt.apply(skink, target, 1)
	active_buff.user_int = new_stacks
	active_buff.set_displayed_stacks(new_stacks)
	active_buff.user_real = new_damage


func poison_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var damage: float = buff.user_real

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())
	Effect.create_simple_at_unit_attached("res://src/effects/chimaera_acid.tscn", tower, Unit.BodyPart.HEAD)


func tower_init():
	poison_skin_bt = BuffType.create_aura_effect_type("poison_skin_bt", true, self)
	poison_skin_bt.set_buff_icon("res://resources/icons/generic_icons/poison_gas.tres")
	poison_skin_bt.add_event_on_attack(poison_skin_bt_on_attack)
	poison_skin_bt.set_buff_tooltip(tr("Z9Z7"))

	poison_bt = BuffType.new("poison_bt", POISON_DURATION, 0.0, false, self)
	poison_bt.set_buff_icon("res://resources/icons/generic_icons/poison_gas.tres")
	poison_bt.add_periodic_event(poison_bt_periodic, 1.0)
	poison_bt.set_buff_tooltip(tr("VS62"))
