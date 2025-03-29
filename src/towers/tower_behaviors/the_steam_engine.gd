extends TowerBehavior


var stun_bt: BuffType
var steam_bt: BuffType
var multiboard: MultiboardValues
var power_level: int = 0
var powered_tower_count: int = 0
var permanent_effect_id: int = 0
var current_mana_degen: float = 0.0


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 1.0)


func tower_init():
	stun_bt = CbStun.new("stun_bt", 1.0, 0, false, self)

	steam_bt = BuffType.new("steam_bt", 5, 0, true, self)
	steam_bt.set_buff_icon("res://resources/icons/generic_icons/pokecog.tres")
	steam_bt.add_event_on_create(steam_bt_on_create)
	steam_bt.add_event_on_attack(steam_bt_on_attack)
	steam_bt.add_periodic_event(steam_bt_periodic, 1.0)
	steam_bt.add_event_on_cleanup(steam_bt_on_cleanup)
	steam_bt.set_buff_tooltip(tr("Z4JU"))

	multiboard = MultiboardValues.new(2)
	var power_level_label: String = tr("MMIX")
	var towers_powered_label: String = tr("E78H")
	multiboard.set_key(0, power_level_label)
	multiboard.set_key(1, towers_powered_label)


func on_create(_preceding_tower: Tower):
	permanent_effect_id = Effect.create_animated_scaled("res://src/effects/cloud_of_fog_cycle.tscn", Vector3(tower.get_x(), tower.get_y(), tower.get_z() + 60), 0, 0.7)
	Effect.set_color(permanent_effect_id, Color8(150, 150, 150, 100))
	Effect.set_auto_destroy_enabled(permanent_effect_id, false)


func on_destruct():
	Effect.destroy_effect(permanent_effect_id)


func periodic(_event: Event):
	var triggered_deactivate: bool = power_level > 0 &&  tower.get_mana() <= 1.0

	if !triggered_deactivate:
		return

	CombatLog.log_ability(tower, tower, "Deactivate")

	power_level = 0
	engine_update_mana_use()
	var power_level_text: String = tr("UQAM").format({POWER_LEVEL = 0})
	tower.get_player().display_floating_text(power_level_text, tower, Color8(50, 150, 100))
	stun_bt.apply_only_timed(tower, tower, 120)


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, str(power_level))
	multiboard.set_value(1, str(powered_tower_count))

	return multiboard


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
func steam_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Unit = buff.get_buffed_unit()

	var mod_value: float = 0.06 * power_level

	buff.user_real = mod_value
	powered_tower_count += 1
	engine_update_mana_use()
	buffed_tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, mod_value)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, mod_value / 2.0)


# NOTE: steam_buff_onAttack() in original script
func steam_bt_on_attack(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var buffed_tower: Unit = buff.get_buffed_unit()
	var lvl: int = caster.get_level()
	var power_surge_chance: float = 0.01 * caster.get_base_attack_speed()

	if !caster.calc_chance(power_surge_chance):
		return

	CombatLog.log_ability(caster, buffed_tower, "Power Surge")
	caster.add_exp(1 + 0.04 * lvl)
	Effect.create_scaled("res://src/effects/frag_boom_spawn.tscn", Vector3(caster.get_x() + 11, caster.get_y() + 56, caster.get_z()), 0, 2)


# Update value of property mods based on current power level of Steam Engine
# NOTE: steam_buff_periodic() in original script
func steam_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Unit = buff.get_buffed_unit()

	var current_mod_value: float = buff.user_real
	var new_mod_value: float = 0.06 * power_level
	var mod_value_delta: float = new_mod_value - current_mod_value
	buff.user_real = new_mod_value
	buff.set_displayed_stacks(power_level)
	buffed_tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, mod_value_delta)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, mod_value_delta / 2.0)


# NOTE: steam_buff_onCleanup() in original script
func steam_bt_on_cleanup(event: Event):
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

	var power_level_text: String = tr("UQAM").format({POWER_LEVEL = power_level})
	tower.get_player().display_floating_text(power_level_text, tower, Color8(50 + 4 * power_level, 150 - 3 * power_level, 100 - 2 * power_level))


func on_autocast_speed_down(_event: Event):
	if power_level <= 0:
		return

	power_level -= 1
	engine_update_mana_use()

	var power_level_text: String = tr("UQAM").format({POWER_LEVEL = power_level})
	tower.get_player().display_floating_text(power_level_text, tower, Color8(50 + 4 * power_level, 150 - 3 * power_level, 100 - 2 * power_level))
