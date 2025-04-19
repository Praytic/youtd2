extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] Fixed bug in original script
# where glimmer aura's initial level was set to 1 which
# caused the initial effect value to be 15% + 0.2%. Fixed so
# it's 15%.


var glimmer_bt: BuffType
var sunlight_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {},
	}


const SUNLIGHT_RANGE: float = 1000
const SUNLIGHT_DURATION: float = 1.5
const SUNLIGHT_DURATION_ADD: float = 0.02
const GLIMMER_MOD_DEBUFF_DURATION: float = 0.15
const GLIMMER_MOD_DEBUFF_DURATION_ADD: float = 0.002


func tower_init():
	glimmer_bt = BuffType.create_aura_effect_type("glimmer_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_DEBUFF_DURATION, -GLIMMER_MOD_DEBUFF_DURATION, -GLIMMER_MOD_DEBUFF_DURATION_ADD)
	glimmer_bt.set_buff_modifier(mod)
	glimmer_bt.set_buff_icon("res://resources/icons/generic_icons/star_swirl.tres")
	glimmer_bt.set_buff_tooltip(tr("IROC"))

	sunlight_bt = CbStun.new("sunlight_bt", SUNLIGHT_DURATION, SUNLIGHT_DURATION_ADD, false, self)
	sunlight_bt.set_buff_icon("res://resources/icons/generic_icons/shiny_omega.tres")


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
		

