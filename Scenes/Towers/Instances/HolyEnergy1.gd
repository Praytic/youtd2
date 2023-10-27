extends Tower


# NOTE: fixed bug in original script where glimmer aura's
# initial level/power were set to 1 which caused the initial
# effect value to be 15% + 0.2%. Fixed so it's 15%.


var dave_glimmer_bt: BuffType
var dave_sunlight_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {},
	}


const SUNLIGHT_RANGE: float = 1000
const SUNLIGHT_DURATION: float = 1.5
const SUNLIGHT_DURATION_ADD: float = 0.02
const AURA_RANGE: float = 500
const GLIMMER_MOD_DEBUFF_DURATION: float = 0.15
const GLIMMER_MOD_DEBUFF_DURATION_ADD: float = 0.002


func get_ability_description() -> String:
	var aura_range: String = Utils.format_float(AURA_RANGE, 2)
	var glimmer_mod_debuff_duration: String = Utils.format_percent(GLIMMER_MOD_DEBUFF_DURATION, 2)
	var glimmer_mod_debuff_duration_add: String = Utils.format_percent(GLIMMER_MOD_DEBUFF_DURATION_ADD, 2)

	var text: String = ""

	text += "[color=GOLD]Glimmer of Hope - Aura[/color]\n"
	text += "Reduces the debuff duration of all towers in %s range by %s.\n" % [aura_range, glimmer_mod_debuff_duration]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s debuff duration reduction\n" % glimmer_mod_debuff_duration_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Glimmer of Hope - Aura[/color]\n"
	text += "Reduces debuff duration of all towers in range.\n"

	return text


func get_autocast_description() -> String:
	var sunlight_range: String = Utils.format_float(SUNLIGHT_RANGE, 2)
	var sunlight_duration: String = Utils.format_float(SUNLIGHT_DURATION, 2)
	var sunlight_duration_add: String = Utils.format_float(SUNLIGHT_DURATION_ADD, 2)

	var text: String = ""

	text += "Stuns all towers and all enemies in %s range for %s seconds.\n" % [sunlight_range, sunlight_duration]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s seconds\n" % sunlight_duration_add

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "Stuns all towers and creeps in range.\n"

	return text


func load_specials(modifier: Modifier):
	_set_target_count(3)

	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0.0, 0.1)
	modifier.add_modification(Modification.Type.MOD_BUFF_DURATION, 0.0, 0.01)


func tower_init():
	dave_glimmer_bt = BuffType.create_aura_effect_type("dave_glimmer_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -GLIMMER_MOD_DEBUFF_DURATION, -GLIMMER_MOD_DEBUFF_DURATION_ADD)
	dave_glimmer_bt.set_buff_modifier(mod)
	dave_glimmer_bt.set_buff_icon("@@1@@")
	dave_glimmer_bt.set_buff_tooltip("Glimmer of Hope Aura\nThis tower is under the effect of Glimmer of Hope Aura; it has reduced debuff duration.")

	dave_sunlight_bt = CbStun.new("dave_sunlight_bt", SUNLIGHT_DURATION, SUNLIGHT_DURATION_ADD, false, self)
	dave_sunlight_bt.set_buff_icon("@@2@@")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Sunlight Burst"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = "Awaken.mdl"
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 1000
	autocast.auto_range = 850
	autocast.cooldown = 20
	autocast.mana_cost = 90
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.target_type = null
	autocast.handler = on_autocast
	add_autocast(autocast)

	var aura: AuraType = AuraType.new()
	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = dave_glimmer_bt
	add_aura(aura)


func on_autocast(_event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	var creeps: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), SUNLIGHT_RANGE)
	var towers: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), SUNLIGHT_RANGE)

	while true:
		var target_creep: Unit = creeps.next()

		if target_creep == null:
			break

		dave_sunlight_bt.apply(tower, target_creep, level)

	while true:
		var target_tower: Unit = towers.next()

		if target_tower == null:
			break

		dave_sunlight_bt.apply(tower, target_tower, level)
		

