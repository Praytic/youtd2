class_name ShardofSouls1 extends TowerBehavior


# NOTE: original script uses linked list to track which
# creeps are affected. I changed it to assign id to each
# linked group and check for all units in game if they have
# buff with same id.

# NOTE: it is weird that autocast type is
# AC_TYPE_ALWAYS_BUFF but it needs to be this way. The
# on_autocast() uses the target, so IMMEDIATE type wouldn't
# work because it has no target. Also, ALWAYS needs to be
# used instead of OFFENSIVE because this tower doesn't
# attack so it never triggers AC_TYPE_OFFENSIVE_BUFF.


static var soul_link_id_max: int = 0


var soul_link_bt: BuffType
var is_soul_link_damage: bool = false


func get_tier_stats() -> Dictionary:
	return {
		1: {link_damage_ratio = 0.125, link_damage_ratio_add = 0.003, link_distance = 600},
		2: {link_damage_ratio = 0.15, link_damage_ratio_add = 0.003, link_distance = 700},
	}

const SOUL_LINK_DURATION: float = 2.5
const SOUL_LINK_COUNT: int = 3
const SOUL_CONSUMPTION_EXP_GAIN: int = 1


func get_ability_info_list() -> Array[AbilityInfo]:
	var soul_consumption_exp_gain: String = Utils.format_float(SOUL_CONSUMPTION_EXP_GAIN, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Soul Consumption"
	ability.icon = "res://resources/icons/gloves/curse.tres"
	ability.description_short = "Whenever a unit under the effect of [color=GOLD]Soul Link[/color] dies, the Shard of Souls consumes its soul granting experience to the tower.\n"
	ability.description_full = "Whenever a unit under the effect of [color=GOLD]Soul Link[/color] dies, the Shard of Souls consumes its soul granting %s experience to the tower.\n" % soul_consumption_exp_gain
	list.append(ability)

	return list


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_BUFF_DURATION, 0.0, 0.02)


func tower_init():
	soul_link_bt = BuffType.new("soul_link_bt", SOUL_LINK_DURATION, 0, false, self)
	soul_link_bt.add_event_on_damaged(soul_link_on_damaged)
	soul_link_bt.add_event_on_death(soul_link_on_death)
	soul_link_bt.set_buff_icon("res://resources/icons/generic_icons/aquarius.tres")
	soul_link_bt.set_buff_tooltip("Soul Link\nDeals damage when linked creeps take damage.")


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var soul_link_count: String = Utils.format_float(SOUL_LINK_COUNT, 2)
	var soul_link_duration: String = Utils.format_float(SOUL_LINK_DURATION, 2)
	var link_damage_ratio: String = Utils.format_percent(_stats.link_damage_ratio, 2)
	var link_damage_ratio_add: String = Utils.format_percent(_stats.link_damage_ratio_add, 2)

	autocast.title = "Soul Link"
	autocast.icon = "res://resources/icons/undead/skull_phazing.tres"
	autocast.description_short = "Links enemies' souls together. If a linked unit takes damage all other linked units will take a portion of the damage.\n"
	autocast.description = "Links %s enemies' souls together for %s seconds. If a linked unit takes damage all other linked units will take %s of this damage. This tower does not benefit from damage increasing items or oils.\n" % [soul_link_count, soul_link_duration, link_damage_ratio] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage\n" % link_damage_ratio_add \
	+ "+1 target at level 15 and 25\n"
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 1
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.cast_range = 1000
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 5
	autocast.is_extended = false
	autocast.mana_cost = 50
	autocast.buff_type = soul_link_bt
	autocast.buff_target_type = TargetType.new(TargetType.CREEPS)
	autocast.auto_range = 1000
	autocast.handler = on_autocast

	return [autocast]


func on_autocast(event: Event):
	var level: int = tower.get_level()
	var main_target: Unit = event.get_target()
	var current_target: Unit = event.get_target()
	var counter: int = 0
	var target_list: Array[Unit] = []

	var max_targets: int = SOUL_LINK_COUNT
	if level == 25:
		max_targets += 2
	elif level >= 15:
		max_targets += 1

	if current_target.get_buff_of_type(soul_link_bt) == null:
		target_list.append(current_target)
		counter += 1
	else:
		return

	while true:
		if counter == max_targets:
			break

		var creeps_in_range: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), current_target, _stats.link_distance)
		
		var next: Unit = null

		while true:
			next = creeps_in_range.next()

			if next == null || next.get_buff_of_type(soul_link_bt) == null:
				break

		if next == null:
			break

		target_list.append(next)
		current_target = next
		counter += 1

	var soul_link_id: int = ShardofSouls1.soul_link_id_max
	ShardofSouls1.soul_link_id_max += 1

	for target in target_list:
		var buff: Buff = soul_link_bt.apply(tower, target, level)
		buff.user_int = soul_link_id

		if target != main_target:
			var lightning: InterpolatedSprite = InterpolatedSprite.create_from_unit_to_unit(InterpolatedSprite.LIGHTNING, target, main_target)
			lightning.modulate = Color.PURPLE
			lightning.set_lifetime(0.4)


func soul_link_on_damaged(event: Event):
#	Stop infinite recursion
	if is_soul_link_damage:
		return

	var damage_source: Tower = event.get_target()
	var buff: Buff = event.get_buff()
	var caster: Unit = buff.get_caster()
	var damage: float = event.damage * (_stats.link_damage_ratio + _stats.link_damage_ratio_add * caster.get_level())
	if event.is_spell_damage():
		damage /= damage_source.get_prop_spell_damage_dealt()

	var target_list: Array[Unit] = []

	var creeps_in_range: Iterate = Iterate.over_units_in_range_of_unit(caster, TargetType.new(TargetType.CREEPS), buff.get_buffed_unit(), 10000)

	CombatLog.log_ability(caster, null, "Soul Link share damage")

	while creeps_in_range.count() > 0:
		var creep: Unit = creeps_in_range.next()
		var creep_buff: Buff = creep.get_buff_of_type(soul_link_bt)

		if creep_buff == null:
			continue

		var same_link: bool = buff.user_int == creep_buff.user_int

		if same_link:
			target_list.append(creep)


	is_soul_link_damage = true
	for target in target_list:
		if event.is_spell_damage():
			damage_source.do_spell_damage(target, damage, 1)
		else:
			damage_source.do_attack_damage(target, damage, 1)
	is_soul_link_damage = false


func soul_link_on_death(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Unit = buff.get_caster()
	CombatLog.log_ability(caster, null, "Soul Consumption")
	caster.add_exp(SOUL_CONSUMPTION_EXP_GAIN)
