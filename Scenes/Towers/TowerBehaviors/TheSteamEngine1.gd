extends TowerBehavior


var cedi_steam_stun: BuffType
var cedi_steam_bt: BuffType
var multiboard: MultiboardValues
var power_level: int = 0
var powered_tower_count: int = 0
var permanent_effect_id: int = 0
var current_mana_degen: float = 0.0


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Power Surge[/color]\n"
	text += "Towers under the effect of Steam Power have a 1% base attackspeed adjusted chance to cause a surge in the Steam Engine, granting it 1 exp.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.04 exp\n"
	text += " \n"

	text += "[color=GOLD]Steam Power - Aura[/color]\n"
	text += "Increases attack damage of towers in 450 AOE by [color=GOLD][6 x power level]%[/color] and attackspeed by half this amount. In order to sustain this, the engine consumes a lot of mana. Mana regeneration is reduced by [color=GOLD][10 x power level x squareroot(towers powered)]%[/color]. If the mana of the engine reaches zero it will deactivate itself for 120 seconds. Does not stack with other Steam Engines!\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Power Surge[/color]\n"
	text += "Towers under the effect of Steam Power have a chance to cause a surge in the Steam Engine.\n"
	text += " \n"

	text += "[color=GOLD]Steam Power - Aura[/color]\n"
	text += "Increases attack damage and attack speed of towers in range. Consumes mana.\n"

	return text


func get_autocast_speed_up_description() -> String:
	return "Increases the power level of the engine by 1. Maximum power level is 50.\n"


func get_autocast_speed_up_description_short() -> String:
	return "Increases the power level of the engine.\n"


func get_autocast_speed_down_description() -> String:
	return "Decreases the power level of the engine by 1.\n"


func get_autocast_speed_down_description_short() -> String:
	return "Decreases the power level of the engine.\n"


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 1.0)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0, 10)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.0, 0.05)


func tower_init():
	cedi_steam_stun = CbStun.new("cedi_steam_stun", 1.0, 0, false, self)

	cedi_steam_bt = BuffType.new("cedi_steam_bt", 5, 0, true, self)
	cedi_steam_bt.set_buff_icon("gear_1.tres")
	cedi_steam_bt.add_event_on_create(cedi_steam_bt_on_create)
	cedi_steam_bt.add_event_on_attack(cedi_steam_bt_on_attack)
	cedi_steam_bt.add_periodic_event(cedi_steam_bt_periodic, 1.0)
	cedi_steam_bt.add_event_on_cleanup(cedi_steam_bt_on_cleanup)
	cedi_steam_bt.set_buff_tooltip("Steam Power\nIncreases attack damage and attack speed.")

	multiboard = MultiboardValues.new(2)
	multiboard.set_key(0, "Power Level")
	multiboard.set_key(1, "Towers Powered")

	var autocast_speed_up: Autocast = Autocast.make()
	autocast_speed_up.title = "Speed Up"
	autocast_speed_up.description = get_autocast_speed_up_description()
	autocast_speed_up.description_short = get_autocast_speed_up_description_short()
	autocast_speed_up.icon = "res://path/to/icon.png"
	autocast_speed_up.caster_art = ""
	autocast_speed_up.target_art = ""
	autocast_speed_up.autocast_type = Autocast.Type.AC_TYPE_NOAC_IMMEDIATE
	autocast_speed_up.num_buffs_before_idle = 0
	autocast_speed_up.cast_range = 0
	autocast_speed_up.auto_range = 0
	autocast_speed_up.cooldown = 0.5
	autocast_speed_up.mana_cost = 0
	autocast_speed_up.target_self = true
	autocast_speed_up.is_extended = false
	autocast_speed_up.buff_type = null
	autocast_speed_up.target_type = TargetType.new(TargetType.TOWERS)
	autocast_speed_up.handler = on_autocast_speed_up
	tower.add_autocast(autocast_speed_up)

	var autocast_speed_down: Autocast = Autocast.make()
	autocast_speed_down.title = "Speed Down"
	autocast_speed_down.description = get_autocast_speed_down_description()
	autocast_speed_down.description_short = get_autocast_speed_down_description_short()
	autocast_speed_down.icon = "res://path/to/icon.png"
	autocast_speed_down.caster_art = ""
	autocast_speed_down.target_art = ""
	autocast_speed_down.autocast_type = Autocast.Type.AC_TYPE_NOAC_IMMEDIATE
	autocast_speed_down.num_buffs_before_idle = 0
	autocast_speed_down.cast_range = 0
	autocast_speed_down.auto_range = 0
	autocast_speed_down.cooldown = 5.0
	autocast_speed_down.mana_cost = 0
	autocast_speed_down.target_self = true
	autocast_speed_down.is_extended = false
	autocast_speed_down.buff_type = null
	autocast_speed_down.target_type = TargetType.new(TargetType.TOWERS)
	autocast_speed_down.handler = on_autocast_speed_down
	tower.add_autocast(autocast_speed_down)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 450
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 1
	aura.level_add = 1
	aura.power = 1
	aura.power_add = 1
	aura.aura_effect = cedi_steam_bt

	return [aura]


func on_create(_preceding_tower: Tower):
	permanent_effect_id = Effect.create_animated_scaled("FireTrapUp.mdl", tower.get_visual_x() - 4, tower.get_visual_y() + 41, 75, 0, 0.55)
	engine_update_anims()


func on_destruct():
	Effect.destroy_effect(permanent_effect_id)


func periodic(_event: Event):
	var triggered_deactivate: bool = power_level > 0 &&  tower.get_mana() <= 1.0

	if !triggered_deactivate:
		return

	CombatLog.log_ability(tower, tower, "Deactivate")

	power_level = 0
	engine_update_mana_use()
	engine_update_anims()
	tower.get_player().display_floating_text("Power Level: 0", tower, Color8(50, 150, 100))
	cedi_steam_stun.apply_only_timed(tower, tower, 120)


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, str(power_level))
	multiboard.set_value(1, str(powered_tower_count))

	return multiboard


# TODO: functions used here are not implemented. Need to
# implement them and then update this code to use new
# functions.
# NOTE: engine_UpdateAnims() in original script
func engine_update_anims():
	pass
	# SetUnitTimeScale(tower, power_level / 10.0)
	# permanent_effect_id.set_animation_speed(0.5 + power_level / 20.0)
	# permanent_effect_id.set_scale(power_level / 20.0)


# Changes mana regen of tower based on current count of
# towers affected by aura. Note that regen here can be
# negative. More towers = more mana spent.
# NOTE: engine_UpdateManaUse() in original script
func engine_update_mana_use():
	var new_mana_degen: float = power_level * sqrt(powered_tower_count) * 10 / 100.0
	var degen_delta: float = current_mana_degen - new_mana_degen
	tower.modify_property(Modification.Type.MOD_MANA_REGEN_PERC, degen_delta)
	current_mana_degen = new_mana_degen


# NOTE: steam_buff_onCreate() in original script
func cedi_steam_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Unit = buff.get_buffed_unit()

	var mod_value: float = 0.06 * power_level

	buff.user_real = mod_value
	powered_tower_count += 1
	engine_update_mana_use()
	buffed_tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, mod_value)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, mod_value / 2.0)


# NOTE: steam_buff_onAttack() in original script
func cedi_steam_bt_on_attack(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var buffed_tower: Unit = buff.get_buffed_unit()
	var lvl: int = caster.get_level()
	var power_surge_chance: float = 0.01 * caster.get_base_attackspeed()

	if !caster.calc_chance(power_surge_chance):
		return

	CombatLog.log_ability(caster, buffed_tower, "Power Surge")
	caster.add_exp(1 + 0.04 * lvl)
	var effect: int = Effect.create_scaled("FragBoomSpawn.mdl", caster.get_visual_x() + 11, caster.get_visual_y() + 56, 40, 0, 5)
	Effect.destroy_effect_after_its_over(effect)


# Update value of property mods based on current power level of Steam Engine
# NOTE: steam_buff_periodic() in original script
func cedi_steam_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Unit = buff.get_buffed_unit()

	var current_mod_value: float = buff.user_real
	var new_mod_value: float = 0.06 * power_level
	var mod_value_delta: float = new_mod_value - current_mod_value
	buff.user_real = new_mod_value
	buffed_tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, mod_value_delta)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, mod_value_delta / 2.0)


# NOTE: steam_buff_onCleanup() in original script
func cedi_steam_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Unit = buff.get_buffed_unit()
	powered_tower_count -= 1
	
	var current_mod_value: float = buff.user_real
	buffed_tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, -current_mod_value)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, -current_mod_value / 2.0)


func on_autocast_speed_up(_event: Event):
	if power_level >= 50:
		return
	
	power_level += 1
	engine_update_mana_use()
	engine_update_anims()

	var floating_text: String = "Power Level: %d" % power_level
	tower.get_player().display_floating_text(floating_text, tower, Color8(50 + 4 * power_level, 150 - 3 * power_level, 100 - 2 * power_level))


func on_autocast_speed_down(_event: Event):
	if power_level <= 0:
		return

	power_level -= 1
	engine_update_mana_use()
	engine_update_anims()

	var floating_text: String = "Power Level: %d" % power_level
	tower.get_player().display_floating_text(floating_text, tower, Color8(50 + 4 * power_level, 150 - 3 * power_level, 100 - 2 * power_level))
