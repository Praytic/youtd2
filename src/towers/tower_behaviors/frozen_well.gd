extends TowerBehavior


var aura_bt: BuffType
var mist_bt: BuffType

const AURA_RANGE: int = 500


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var freezing_mist: AbilityInfo = AbilityInfo.new()
	freezing_mist.name = "Freezing Mist"
	freezing_mist.icon = "res://resources/icons/gems/crystal.tres"
	freezing_mist.description_short = "Slows hit creeps.\n"
	freezing_mist.description_full = "Slows hit creeps by 15% for 10 seconds.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.4% slow\n"
	list.append(freezing_mist)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	tower.set_attack_style_splash({
		150: 1.0,
		625: 0.2
		})


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var boekie_frozen_well_aura_mod: Modifier = Modifier.new()
	boekie_frozen_well_aura_mod.add_modification(Modification.Type.MOD_BUFF_DURATION, 0.25, 0.004)
	aura_bt.set_buff_modifier(boekie_frozen_well_aura_mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/star_swirl.tres")
	aura_bt.set_buff_tooltip("Flowing Frost Aura\nIncreases buff duration.")

	mist_bt = BuffType.new("mist_bt", 10, 0, false, self)
	var boekie_freezing_mist_mod: Modifier = Modifier.new()
	boekie_freezing_mist_mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.15, -0.004)
	mist_bt.set_buff_modifier(boekie_freezing_mist_mod)
	mist_bt.set_buff_icon("res://resources/icons/generic_icons/azul_flake.tres")
	mist_bt.set_buff_tooltip("Freezing Mist\nReduces movement speed.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	aura.name = "Flowing Frost"
	aura.icon = "res://resources/icons/tower_icons/ice_battery.tres"
	aura.description_short = "Increases buff duration of towers in range.\n"
	aura.description_full = "Increases the buff duration of towers in %d range by 25%%.\n" % AURA_RANGE \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.4% buff duration\n"

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = aura_bt
	return [aura]


func on_damage(event: Event):
	mist_bt.apply(tower, event.get_target(), tower.get_level())
