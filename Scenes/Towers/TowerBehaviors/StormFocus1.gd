extends TowerBehavior


var freezing_bt: BuffType
var aura_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Gust - Aura[/color]\n"
	text += "Towers in 800 range around the Storm Focus gain additional attackdamage equal to 50% of the bonus damage against air they have.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.8% of bonus damage against air as additional attackdamage\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Gust - Aura[/color]\n"
	text += "Towers in range around the Storm Focus gain additional attackdamage scaled by their bonus damage against air.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "Casts a buff on a tower in 800 range, doubling the effect of 'Gust' and increasing that tower's damage against air units by 10% for 5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.05 seconds duration\n"
	text += "+0.8% damage against air\n"

	return text


func get_autocast_description_short() -> String:
	return "Casts a buff on a tower in range, doubling the effect of 'Gust'."


func load_specials(modifier: Modifier):
	tower.set_attack_air_only()
	modifier.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.10, 0.0)


func get_ability_ranges() -> Array[RangeData]:
	return [RangeData.new("Freezing Gust", 800, TargetType.new(TargetType.TOWERS))]


func tower_init():
	freezing_bt = BuffType.new("freezing_bt", 5, 0.05, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.1, 0.008)
	freezing_bt.set_buff_modifier(mod)
	freezing_bt.set_buff_icon("orb_swirly.tres")
	freezing_bt.set_buff_tooltip("Freezing Gust\nDoubles the effect of Gust Aura.")

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("orb_swirly.tres")
	aura_bt.add_event_on_create(gust_on_create)
	aura_bt.add_periodic_event(gust_periodic, 1.0)
	aura_bt.add_event_on_cleanup(gust_on_cleanup)
	aura_bt.set_buff_tooltip("Gust Aura\nIncreases damage dealt to Air creeps.")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Freezing Gust"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = "PolyMorphDoneGround.mdl"
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
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = Callable()
	tower.add_autocast(autocast)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 800
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
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
