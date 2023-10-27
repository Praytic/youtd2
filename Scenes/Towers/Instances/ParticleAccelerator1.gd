extends Tower


var red_terror_values: MultiboardValues
var cb_stun: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_value = 0.02},
		2: {mod_value = 0.03},
		3: {mod_value = 0.04},
	}


const MOD_VALUE_ADD: float = 0.001
const STUN_DURATION: float = 2


func get_ability_description() -> String:
	var mod_value: String = Utils.format_percent(_stats.mod_value, 2)
	var mod_value_add: String = Utils.format_percent(MOD_VALUE_ADD, 2)

	var text: String = ""

	text += "[color=GOLD]Energy Acceleration[/color]\n"
	text += "Every attack increases attack speed and damage by %s.\n" % mod_value
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s attack speed and damage\n" % mod_value_add
	text += " \n"
	text += "[color=GOLD]Errant Tachyons[/color]\n"
	text += "On kill, this tower is stunned for %s seconds and the bonus from Energy Acceleration is lost.\n" % STUN_DURATION

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Energy Acceleration[/color]\n"
	text += "Every attack increases attack speed and damage.\n"
	text += " \n"
	text += "[color=GOLD]Errant Tachyons[/color]\n"
	text += "On kill, this tower is stunned and the bonus from Energy Acceleration is lost.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_kill(on_kill)


func update_effect_speed():
	var tower: Tower = self
	var effect_id: int = tower.user_int2
	var new_speed: float = 0.5 + tower.user_real / 2
	Effect.set_animation_speed(effect_id, new_speed)


func tower_init():
	red_terror_values = MultiboardValues.new(1)
	red_terror_values.set_key(0, "Acceleration")

	cb_stun = CbStun.new("particle_accelerator_stun", 0, 0, false, self)


func on_attack(_event: Event):
	var tower: Tower = self
	var lvl: int = tower.get_level()
	var modify_value: float = _stats.mod_value + MOD_VALUE_ADD * lvl
	tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, modify_value)
	tower.modify_property(Modification.Type.MOD_ATTACKSPEED, modify_value)
	tower.user_real = tower.user_real + modify_value
	update_effect_speed()


func on_kill(event: Event):
	var tower: Tower = self
	SFX.sfx_at_unit("feralspiritdone.mdl", event.get_target())
	tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, -tower.user_real)
	tower.modify_property(Modification.Type.MOD_ATTACKSPEED, -tower.user_real)
	cb_stun.apply_only_timed(tower, tower, STUN_DURATION)
	tower.user_real = 0
	update_effect_speed()


func on_create(_preceding: Tower):
	var tower: Tower = self
	var effect: int = Effect.create_animated_scaled("SpiritLinkTarget.mdl", tower.get_visual_x(), tower.get_visual_y(), 8, 0, 1.5)
	tower.user_int2 = effect
	tower.user_real = 0
	update_effect_speed()


func on_destruct():
	var tower: Tower = self
	Effect.destroy_effect(tower.user_int2)


func on_tower_details() -> MultiboardValues:
	var tower: Tower = self
	red_terror_values.set_value(0, Utils.format_float(tower.user_real * 100, 1))

	return red_terror_values
