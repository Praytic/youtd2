class_name ShardofSouls1 extends Tower


# NOTE: original script uses linked list to track which
# creeps are affected. I changed it to assign id to each
# linked group and check for all units in game if they have
# buff with same id.


static var soul_link_id_max: int = 0


var tomy_soul_link: BuffType
var is_soul_link_damage: bool = false


func get_tier_stats() -> Dictionary:
	return {
		1: {link_damage_ratio = 0.125, link_damage_ratio_add = 0.003},
		2: {link_damage_ratio = 0.15, link_damage_ratio_add = 0.003},
	}

const SOUL_LINK_DURATION: float = 2.5
const SOUL_LINK_COUNT: int = 3
const SOUL_CONSUMPTION_EXP_GAIN: int = 1


func get_ability_description() -> String:
	var soul_consumption_exp_gain: String = Utils.format_float(SOUL_CONSUMPTION_EXP_GAIN, 2)
	
	var text: String = ""

	text += "[color=GOLD]Soul Consumption[/color]\n"
	text += "Whenever a unit under the effect of Soul Link dies, the Shard of Souls consumes its soul granting %s experience to the tower.\n" % soul_consumption_exp_gain

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Soul Consumption[/color]\n"
	text += "Whenever a unit under the effect of Soul Link dies, the Shard of Souls consumes its soul granting experience to the tower.\n"

	return text


func get_autocast_description() -> String:
	var soul_link_count: String = Utils.format_float(SOUL_LINK_COUNT, 2)
	var soul_link_duration: String = Utils.format_float(SOUL_LINK_DURATION, 2)
	var link_damage_ratio: String = Utils.format_percent(_stats.link_damage_ratio, 2)
	var link_damage_ratio_add: String = Utils.format_percent(_stats.link_damage_ratio_add, 2)

	var text: String = ""

	text += "Links %s enemies' souls together for %s seconds. If a linked unit takes damage all other linked units will take %s of this damage. This tower does not benefit from damage increasing items or oils.\n" % [soul_link_count, soul_link_duration, link_damage_ratio]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % link_damage_ratio_add
	text += "+1 target at level 15 and 25\n"

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "Links enemies' souls together. If a linked unit takes damage all other linked units will take a portion of the damage.\n"

	return text


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_BUFF_DURATION, 0.0, 0.02)


func tower_init():
	tomy_soul_link = BuffType.new("tomy_soul_link", SOUL_LINK_DURATION, 0, false, self)
	tomy_soul_link.add_event_on_damaged(soul_link_on_damaged)
	tomy_soul_link.add_event_on_death(soul_link_on_death)
	tomy_soul_link.set_buff_icon("@@0@@")
	tomy_soul_link.set_buff_tooltip("Soul Link\nThis unit is affected by Soul Link; it will take a portion of damage when other linked units received damage.")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Soul Link"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 1
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.cast_range = 1000
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 5
	autocast.is_extended = false
	autocast.mana_cost = 50
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.auto_range = 1000
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_autocast(event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	var current_target: Unit = event.get_target()
	var counter: int = 0
	var target_list: Array[Unit] = []

	var max_targets: int = SOUL_LINK_COUNT
	if level == 25:
		max_targets += 2
	elif level >= 15:
		max_targets += 1

	if current_target.get_buff_of_type(tomy_soul_link) == null:
		target_list.append(current_target)
		counter += 1
	else:
		return

	while true:
		if counter == max_targets:
			break

		var creeps_in_range: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), current_target, 600)
		
		var next: Unit = null

		while true:
			next = creeps_in_range.next()

			if next == null || next.get_buff_of_type(tomy_soul_link) == null:
				break

		if next == null:
			break

		target_list.append(current_target)
		current_target = next
		counter += 1

	var soul_link_id: int = ShardofSouls1.soul_link_id_max
	ShardofSouls1.soul_link_id_max += 1

	for target in target_list:
		var buff: Buff = tomy_soul_link.apply(tower, target, level)
		buff.user_int = soul_link_id

		var effect_id: int = Effect.create_simple_at_unit("FindSomeEffect.mdl", target)
		Effect.destroy_effect_after_its_over(effect_id)


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

	while creeps_in_range.count() > 0:
		var creep: Unit = creeps_in_range.next()
		var creep_buff: Buff = creep.get_buff_of_type(tomy_soul_link)

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
	caster.add_exp(SOUL_CONSUMPTION_EXP_GAIN)
