extends TowerBehavior


var multiboard: MultiboardValues
var stun_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_value = 0.02},
		2: {mod_value = 0.03},
		3: {mod_value = 0.04},
	}


const MOD_VALUE_ADD: float = 0.001
const STUN_DURATION: float = 2


func get_ability_info_list() -> Array[AbilityInfo]:
	var mod_value: String = Utils.format_percent(_stats.mod_value, 2)
	var mod_value_add: String = Utils.format_percent(MOD_VALUE_ADD, 2)

	var list: Array[AbilityInfo] = []
	
	var energy_accel: AbilityInfo = AbilityInfo.new()
	energy_accel.name = "Energy Acceleration"
	energy_accel.icon = "res://resources/icons/trinkets/trinket_10.tres"
	energy_accel.description_short = "Every attack increases attack speed and attack damage.\n"
	energy_accel.description_full = "Every attack increases attack speed and attack damage by %s.\n" % mod_value \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s attack speed and attack damage\n" % mod_value_add
	list.append(energy_accel)

	var errant: AbilityInfo = AbilityInfo.new()
	errant.name = "Errant Tachyons"
	errant.icon = "res://resources/icons/magic/fire.tres"
	errant.description_short = "On kill, this tower is stunned and the bonus from [color=GOLD]Energy Acceleration[/color] is lost.\n"
	errant.description_full = "On kill, this tower is stunned for %s seconds and the bonus from [color=GOLD]Energy Acceleration[/color] is lost.\n" % STUN_DURATION
	list.append(errant)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_kill(on_kill)


func update_effect_speed():
	var effect_id: int = tower.user_int2
	var new_speed: float = 0.5 + tower.user_real / 2
	Effect.set_animation_speed(effect_id, new_speed)


func tower_init():
	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Acceleration")

	stun_bt = CbStun.new("particle_accelerator_stun", 0, 0, false, self)


func on_attack(_event: Event):
	var lvl: int = tower.get_level()
	var modify_value: float = _stats.mod_value + MOD_VALUE_ADD * lvl
	tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, modify_value)
	tower.modify_property(Modification.Type.MOD_ATTACKSPEED, modify_value)
	tower.user_real = tower.user_real + modify_value
	update_effect_speed()


func on_kill(event: Event):
	SFX.sfx_at_unit(SfxPaths.ELECTRIC_BUZZ, event.get_target())
	tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, -tower.user_real)
	tower.modify_property(Modification.Type.MOD_ATTACKSPEED, -tower.user_real)
	stun_bt.apply_only_timed(tower, tower, STUN_DURATION)
	tower.user_real = 0
	update_effect_speed()


func on_create(_preceding: Tower):
	var effect: int = Effect.create_animated_scaled("SpiritLinkTarget.mdl", tower.get_position_wc3(), 0, 1.5)
	Effect.set_auto_destroy_enabled(effect, false)
	tower.user_int2 = effect
	tower.user_real = 0
	update_effect_speed()


func on_destruct():
	Effect.destroy_effect(tower.user_int2)


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, Utils.format_float(tower.user_real * 100, 1))

	return multiboard
