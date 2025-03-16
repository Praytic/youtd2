extends TowerBehavior


var freezing_bt: BuffType
var aura_bt: BuffType

const AURA_RANGE: int = 800


func load_specials(modifier: Modifier):
	tower.set_attack_air_only()
	modifier.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.10, 0.0)


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


func create_autocasts_DELETEME() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	autocast.title = "Freezing Gust"
	autocast.icon = "res://resources/icons/fire/flame_blue.tres"
	autocast.description_short = "Casts a buff on a tower in range, doubling the effect of [color=GOLD]Gust Aura[/color]."
	autocast.description = "Casts a buff on a tower in 800 range, doubling the effect of [color=GOLD]Gust Aura[/color] and increasing that tower's damage against air units by 10% for 5 seconds.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.05 seconds duration\n" \
	+ "+0.8% damage against air\n"
	autocast.caster_art = "res://src/effects/ancient_protector_missile.tscn"
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 800
	autocast.auto_range = 800
	autocast.cooldown = 0.1
	autocast.mana_cost = 15
	autocast.target_self = false
	autocast.is_extended = true
	autocast.buff_type = freezing_bt
	autocast.buff_target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = Callable()

	return [autocast]


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	aura.name = "Gust"
	aura.icon = "res://resources/icons/tower_icons/ice_battery.tres"
	aura.description_short = "Towers in range around the Storm Focus gain additional attack damage scaled by their bonus damage against air.\n"
	aura.description_full = "Towers in %d range around the Storm Focus gain additional attack damage equal to 50%% of the bonus damage against air they have.\n" % AURA_RANGE \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.8% of bonus damage against air as additional attack damage\n"

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = aura_bt
	return [aura]


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
