extends TowerBehavior


var freezing_bt: BuffType
var aura_bt: BuffType


func tower_init():
	freezing_bt = BuffType.new("freezing_bt", 5, 0.05, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.1, 0.008)
	freezing_bt.set_buff_modifier(mod)
	freezing_bt.set_buff_icon("res://resources/icons/generic_icons/energy_breath.tres")
	freezing_bt.set_buff_tooltip("Freezing Gust\nDoubles the effect of Gust Aura.")

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/atomic_slashes.tres")
	aura_bt.add_event_on_create(gust_on_create)
	aura_bt.add_periodic_event(gust_periodic, 1.0)
	aura_bt.add_event_on_cleanup(gust_on_cleanup)
	aura_bt.set_buff_tooltip("Gust Aura\nIncreases damage dealt to Air creeps.")


func gust_on_create(event: Event):
#	Sstore tower's bonus damage in buff's user_real
	var buff: Buff = event.get_buff()
	buff.user_real = 0.0


func gust_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var multiplier: float = 0.5 + 0.008 * tower.get_level()
	var dmg_to_air: float = target.get_damage_to_size(CreepSize.enm.AIR)

	var bonus_damage: float = 1.0 * (dmg_to_air - 1.0) * multiplier
	
	var target_has_freezing_gust: bool = target.get_buff_of_type(freezing_bt) != null
	if target_has_freezing_gust:
		bonus_damage *= 2.0

	target.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, bonus_damage - buff.user_real)
	buff.user_real = bonus_damage


func gust_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var bonus_dmg: float = buff.user_real
	target.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, -bonus_dmg)
