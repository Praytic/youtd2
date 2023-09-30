extends Tower


var boekie_rage_buff: BuffType
var boekie_jungle_stalker_mb: MultiboardValues


func get_tier_stats() -> Dictionary:
	return {
		1: {crit_chance = 0.150, feral_dmg_gain = 0.002, feral_dmg_max = 2.00, bloodthirst_attackspeed = 1.00, bloodthirst_duration = 3, rage_buff_level_base = 0},
		2: {crit_chance = 0.175, feral_dmg_gain = 0.003, feral_dmg_max = 2.25, bloodthirst_attackspeed = 1.25, bloodthirst_duration = 4, rage_buff_level_base = 25},
		3: {crit_chance = 0.200, feral_dmg_gain = 0.004, feral_dmg_max = 2.50, bloodthirst_attackspeed = 1.50, bloodthirst_duration = 5, rage_buff_level_base = 50},
	}


const CRIT_CHANCE_ADD: float = 0.005
const BLOODTHIRST_ATTACKSPEED_ADD: float = 0.01
const BLOODTHIRST_DURATION_ADD: float = 0.05


func get_extra_tooltip_text() -> String:
	var feral_dmg_gain: String = Utils.format_percent(_stats.feral_dmg_gain, 2)
	var feral_dmg_max: String = Utils.format_percent(_stats.feral_dmg_max, 2)
	var bloodthirst_attackspeed: String = Utils.format_percent(_stats.bloodthirst_attackspeed, 2)
	var bloodthirst_attackspeed_add: String = Utils.format_percent(BLOODTHIRST_ATTACKSPEED_ADD, 2)
	var bloodthirst_duration: String = Utils.format_float(_stats.bloodthirst_duration, 2)
	var bloodthirst_duration_add: String = Utils.format_float(BLOODTHIRST_DURATION_ADD, 2)

	var text: String = ""

	text += "[color=GOLD]Feral Aggression[/color]\n"
	text += "On every critical hit this tower gains +%s bonus damage. This bonus is permanent and has a maximum of %s bonus damage.\n" % [feral_dmg_gain, feral_dmg_max]
	text += " \n"
	text += "[color=GOLD]Bloodthirst[/color]\n"
	text += "Whenever this tower kills a unit it becomes enraged, gaining +%s attackspeed for %s seconds. Cannot retrigger while active!\n" % [bloodthirst_attackspeed, bloodthirst_duration]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s sec duration\n" % bloodthirst_duration_add
	text += "+%s attackspeed\n" % bloodthirst_attackspeed_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_kill(on_kill)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, _stats.crit_chance - Constants.INNATE_MOD_ATK_CRIT_CHANCE, CRIT_CHANCE_ADD - Constants.INNATE_MOD_ATK_CRIT_CHANCE_LEVEL_ADD)


func tower_init():
	boekie_rage_buff = BuffType.new("boekie_rage_buff", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 1.0, BLOODTHIRST_ATTACKSPEED_ADD)
	boekie_rage_buff.set_buff_modifier(mod)
	boekie_rage_buff.set_buff_icon("@@0@@")
	boekie_rage_buff.set_buff_tooltip("Enraged\nThis tower is enraged; it has increased attackspeed.")

	boekie_jungle_stalker_mb = MultiboardValues.new(1)
	boekie_jungle_stalker_mb.set_key(0, "Damage Bonus")


func on_damage(event: Event):
	var tower: Tower = self

	if event.is_attack_damage_critical() && tower.user_real <= _stats.feral_dmg_max:
		tower.user_real += _stats.feral_dmg_gain
		tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, _stats.feral_dmg_gain)


func on_kill(_event: Event):
	var tower: Tower = self
	var lvl: int = tower.get_level()
	var buff_level: int = lvl + _stats.rage_buff_level_base
	var buff_duration: float = _stats.bloodthirst_duration + BLOODTHIRST_DURATION_ADD * lvl

	if tower.get_buff_of_type(boekie_rage_buff) == null:
		boekie_rage_buff.apply_custom_timed(tower, tower, buff_level, buff_duration)


func on_create(preceding: Tower):
	var tower: Tower = self

	if preceding != null && preceding.get_family() == tower.get_family():
		var damage_bonus: float = preceding.user_real
		tower.user_real = damage_bonus
		tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, damage_bonus)
	else:
		tower.user_real = 0.0


func on_tower_details() -> MultiboardValues:
	var tower: Tower = self
	var damage_bonus: String = Utils.format_percent(tower.user_real, 1)

	boekie_jungle_stalker_mb.set_value(0, damage_bonus)

	return boekie_jungle_stalker_mb
