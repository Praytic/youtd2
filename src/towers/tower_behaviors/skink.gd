extends TowerBehavior


# NOTE: removed check for validity of poison caster. It's
# not needed because in youtd2, buffs get automatically
# removed when caster becomes invalid.


var poison_skin_bt: BuffType
var poison_bt: BuffType

const AURA_RANGE: int = 200
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
	var attack_speed_and_range_adjustment: float = buffed_tower.get_current_attack_speed() / (buffed_tower.get_range() / 800.0)
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
	poison_skin_bt.set_buff_tooltip("Poisonous Skin\nApplies poison on attack.")

	poison_bt = BuffType.new("poison_bt", POISON_DURATION, 0.0, false, self)
	poison_bt.set_buff_icon("res://resources/icons/generic_icons/poison_gas.tres")
	poison_bt.add_periodic_event(poison_bt_periodic, 1.0)
	poison_bt.set_buff_tooltip("Poison\nDeals damage over time.")

	
func get_aura_types_DELETEME() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var dmg: String = Utils.format_float(_stats.dmg, 2)
	var dmg_add: String = Utils.format_float(_stats.dmg_add, 2)
	var poison_duration: String = Utils.format_float(POISON_DURATION, 2)

	aura.name = "Poisonous Skin"
	aura.icon = "res://resources/icons/tower_icons/poison_battery.tres"
	aura.description_short = "This and nearby towers gain a poisonous attack, which deals spell damage.\n"
	aura.description_full = "This and any towers in %d range gain a poisonous attack. The poison applies to the main target and deals %s spell damage per second for %s seconds. The effect stacks and is adjusted based on the attack speed and range of the buffed tower. Note that poison damage is dealt by [color=GOLD]Skink[/color] instead of the buffed tower.\n" % [AURA_RANGE, dmg, poison_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage per second" % dmg_add

	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.aura_effect = poison_skin_bt
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_range = AURA_RANGE
	return [aura]
