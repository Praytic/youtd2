extends Tower


var cedi_crypt_plague_bt: BuffType
var cedi_crypt_army_bt: BuffType
var multiboard: MultiboardValues


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Plague[/color]\n"
	text += "When a creep is damaged by this tower it will become infected with a plague. This plague deals 750 damage per second and lasts 5 seconds. Every 1.5 seconds the plague can spread to a creep in 250 range around the infected creep. If an infected creep is infected again by the plague the duration will refresh and the damage is increased by 375.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+30 damage\n"
	text += "+0.2 seconds duration\n"
	text += "+15 damage per rebuff\n"
	text += " \n"

	text += "[color=GOLD]Army of the Damned[/color]\n"
	text += "Every 3 seconds, if there is a corpse within 1150 range this tower will extract its soul, increasing its attack speed and damage by 5% and Plague's rate of spread by 10%. This buff lasts 20 seconds and stacks, but new stacks will not refresh the duration of old ones."
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4 seconds duration\n"
	text += " \n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Plague[/color]\n"
	text += "When a creep is damaged by this tower it will become infected with a plague.\n"
	text += " \n"

	text += "[color=GOLD]Army of the Damned[/color]\n"
	text += "If there is a corpse in range, this tower will extract its soul."
	text += " \n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 3.0)


func load_specials(_modifier: Modifier):
	_set_attack_ground_only()
	_set_attack_style_splash({
		25: 1.00,
		50: 0.40,
		150: 0.25,
		})


func tower_init():
	cedi_crypt_plague_bt = BuffType.new("cedi_crypt_plague_bt", 5.0, 0.2, false, self)
	cedi_crypt_plague_bt.set_buff_icon("@@0@@")
	cedi_crypt_plague_bt.add_event_on_upgrade(cedi_crypt_plague_on_create)
	cedi_crypt_plague_bt.add_event_on_refresh(cedi_crypt_plague_on_refresh)
	cedi_crypt_plague_bt.add_periodic_event(cedi_crypt_plague_periodic_damage, 1.0)
#	NOTE: The period of periodic event starts out at 0.01
#	and then gets changed to real period via
#	enable_advanced(). It starts at 0.01 to change to real
#	period as quickly as possible.
	cedi_crypt_plague_bt.add_periodic_event(cedi_crypt_plague_periodic_spread, 0.01)
	cedi_crypt_plague_bt.set_buff_tooltip("Plague\nThis creep is affected by Plague; it will take damage over time.")

	cedi_crypt_army_bt = BuffType.new("cedi_crypt_army_bt", -1, 0, true, self)
	var cedi_crypt_army_mod: Modifier = Modifier.new()
	cedi_crypt_army_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.05)
	cedi_crypt_army_mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.05)
	cedi_crypt_army_bt.set_buff_modifier(cedi_crypt_army_mod)
	cedi_crypt_army_bt.set_buff_icon("@@1@@")
	cedi_crypt_army_bt.set_buff_tooltip("Army of the Damned\nThis tower is supported by Army of the Damned; it has increased attack speed and damage.")

	multiboard = MultiboardValues.new(2)
	multiboard.set_key(0, "Souls Extracted")
	multiboard.set_key(1, "Infection Rate")


func on_damage(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	cedi_crypt_plague_bt.apply(tower, target, level)


func on_tower_details():
	var tower: Tower = self
	var army_buff: Buff = tower.get_buff_of_type(cedi_crypt_army_bt)
	var army_buff_level: int
	if army_buff != null:
		army_buff_level = army_buff.get_level()
	else:
		army_buff_level = 0
	var souls_extracted: String = str(army_buff_level)
	var plague_spread_time: float = get_plague_spread_time()
	var infection_rate: String = Utils.format_float(plague_spread_time, 2)

	multiboard.set_value(0, souls_extracted)
	multiboard.set_value(1, infection_rate)

	return multiboard


func periodic(_event: Event):
	var tower: Tower = self
	var it: Iterate = Iterate.over_corpses_in_range(tower, tower.get_x(), tower.get_y(), 1150)
	var corpse: Unit = it.next_corpse()

	if corpse == null:
		return

	var effect: int = Effect.add_special_effect("RaiseSkeleton.mdl", corpse.position.x, corpse.position.y)
	Effect.destroy_effect_after_its_over(effect)

	corpse.queue_free()

	var active_buff: Buff = tower.get_buff_of_type(cedi_crypt_army_bt)
	var new_buff_level: int
	if active_buff != null:
		new_buff_level = active_buff.get_level() + 1
	else:
		new_buff_level = 1
	
	var buff: Buff = cedi_crypt_army_bt.apply(tower, tower, new_buff_level)

	var stack_duration: float = (20.0 + 0.4 * tower.get_level()) * tower.get_prop_buff_duration()
	await get_tree().create_timer(stack_duration).timeout

#	NOTE: after sleep
	if !Utils.unit_is_valid(tower):
		return

	if !is_instance_valid(buff):
		return

	var reduced_buff_level: int = buff.get_level() - 1
	if reduced_buff_level > 0:
		buff.set_level(reduced_buff_level)
	else:
		buff.remove_buff()


func cedi_crypt_plague_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var damage_increase_multiplier: int = 0
	buff.user_int = damage_increase_multiplier
	var first_periodic_call: int = 0
	buff.user_int2 = first_periodic_call


func cedi_crypt_plague_on_refresh(event: Event):
	var buff: Buff = event.get_buff()
	var old_damage_increase_multiplier: int = buff.user_int
	var new_damage_increase_multiplier: int = old_damage_increase_multiplier + 1
	buff.user_int = new_damage_increase_multiplier


func cedi_crypt_plague_periodic_damage(event: Event):
	var buff: Buff = event.get_buff()
	var tower: Unit = buff.get_caster()
	var target: Unit = buff.get_buffed_unit()
	var level: int = tower.get_level()
	var damage_increase_multiplier: int = buff.user_int
	var damage: float = (750 + 30 * level) + (375 + 15 * level) * damage_increase_multiplier

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())


# NOTE: script doesn't spread when user_int2 is 0 because
# that case happens 0.01s after buff is applied. Once we
# call enable_advanced() with real duration of around 1.5s,
# we will start doing real plague spreads.
func cedi_crypt_plague_periodic_spread(event: Event):
	var plague_buff: Buff = event.get_buff()
	var tower: Tower = plague_buff.get_caster()
	var target: Unit = plague_buff.get_buffed_unit()
	var level: int = tower.get_level()
	var first_periodic_call: int = plague_buff.user_int2

	if first_periodic_call == 1:
		var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 250)
		
		while true:
			var next: Unit = it.next_random()

			if next == null:
				break

			if next != target:
				cedi_crypt_plague_bt.apply(tower, next, level)
				break
	else:
		var new_first_periodic_call: int = 1
		plague_buff.user_int2 = new_first_periodic_call

	var plague_spread_time: float = get_plague_spread_time()
	event.enable_advanced(plague_spread_time, false)


# NOTE: plague spread time gets smaller as the level of army
# buff increases
func get_plague_spread_time():
	var tower: Tower = self
	var army_buff: Buff = tower.get_buff_of_type(cedi_crypt_army_bt)
	var army_buff_level: int
	if army_buff == null:
		army_buff_level = 0
	else:
		army_buff_level = army_buff.get_level()
	
	var plague_spread_time: float = 1.5 * pow(1.1, -army_buff_level)

	return plague_spread_time
