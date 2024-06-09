extends TowerBehavior


# NOTE: fixed bug in original script where glimmer aura's
# initial level was set to 1 which caused the initial
# effect value to be 15% + 0.2%. Fixed so it's 15%.


var glimmer_bt: BuffType
var sunlight_bt: BuffType


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


func load_specials(modifier: Modifier):
	tower.set_target_count(3)

	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0.0, 0.1)
	modifier.add_modification(Modification.Type.MOD_BUFF_DURATION, 0.0, 0.01)


func tower_init():
	glimmer_bt = BuffType.create_aura_effect_type("glimmer_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -GLIMMER_MOD_DEBUFF_DURATION, -GLIMMER_MOD_DEBUFF_DURATION_ADD)
	glimmer_bt.set_buff_modifier(mod)
	glimmer_bt.set_buff_icon("res://resources/icons/generic_icons/star_swirl.tres")
	glimmer_bt.set_buff_tooltip("Glimmer of Hope Aura\nReduces debuff duration.")

	sunlight_bt = CbStun.new("sunlight_bt", SUNLIGHT_DURATION, SUNLIGHT_DURATION_ADD, false, self)
	sunlight_bt.set_buff_icon("res://resources/icons/generic_icons/shiny_omega.tres")


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var sunlight_range: String = Utils.format_float(SUNLIGHT_RANGE, 2)
	var sunlight_duration: String = Utils.format_float(SUNLIGHT_DURATION, 2)
	var sunlight_duration_add: String = Utils.format_float(SUNLIGHT_DURATION_ADD, 2)

	autocast.title = "Sunlight Burst"
	autocast.icon = "res://resources/icons/electricity/electricity_yellow.tres"
	autocast.description_short = "Stuns all towers and creeps in range.\n"
	autocast.description = "Stuns all towers and all enemies in %s range for %s seconds.\n" % [sunlight_range, sunlight_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s seconds\n" % sunlight_duration_add
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

	return [autocast]


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var glimmer_mod_debuff_duration: String = Utils.format_percent(GLIMMER_MOD_DEBUFF_DURATION, 2)
	var glimmer_mod_debuff_duration_add: String = Utils.format_percent(GLIMMER_MOD_DEBUFF_DURATION_ADD, 2)
	
	aura.name = "Glimmer of Hope"
	aura.icon = "res://resources/icons/holy/orb.tres"
	aura.description_short = "Reduces debuff duration of all towers in range.\n"
	aura.description_full = "Reduces the debuff duration of all towers in %d range by %s.\n" % [AURA_RANGE, glimmer_mod_debuff_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s debuff duration reduction\n" % glimmer_mod_debuff_duration_add

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = glimmer_bt
	return [aura]


func on_autocast(_event: Event):
	var level: int = tower.get_level()
	var creeps: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), SUNLIGHT_RANGE)
	var towers: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), SUNLIGHT_RANGE)

	while true:
		var target_creep: Unit = creeps.next()

		if target_creep == null:
			break

		sunlight_bt.apply(tower, target_creep, level)

	while true:
		var target_tower: Unit = towers.next()

		if target_tower == null:
			break

		sunlight_bt.apply(tower, target_tower, level)
		

