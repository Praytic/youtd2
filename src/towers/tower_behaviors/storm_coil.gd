extends TowerBehavior


var surge_bt: BuffType
var slow_bt: BuffType
var aura_bt: BuffType

const AURA_RANGE: int = 1000


func get_ability_info_list() -> Array[AbilityInfo]:
	var energy_string: String = AttackType.convert_to_colored_string(AttackType.enm.ENERGY)

	var list: Array[AbilityInfo] = []
	
	var overload: AbilityInfo = AbilityInfo.new()
	overload.name = "Overload"
	overload.icon = "res://resources/icons/electricity/lightning_circle_white.tres"
	overload.description_short = "Deals %s damage and slow hit creeps. Effect is stronger for creeps far away.\n" % energy_string
	overload.description_full = "Deals %s damage and slows hit creeps for 1.5 seconds. Damage is equal to [color=GOLD][distance to the target x 12][/color] and is affected by bonuses to tower's attack damage. The further away the target is, the more it will be slowed. The maximum slow value is 30%%.\n" % energy_string
	list.append(overload)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	slow_bt = BuffType.new("slow_bt", 1.5, 0, false, self)
	var slow_bt_mod: Modifier = Modifier.new()
	slow_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.0001)
	slow_bt.set_buff_modifier(slow_bt_mod)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	slow_bt.set_buff_tooltip("Overload\nReduces movement speed.")

	surge_bt = BuffType.new("surge_bt", 4.0, 0.1, true, self)
	surge_bt.set_buff_icon("res://resources/icons/generic_icons/rss.tres")
	surge_bt.add_periodic_event(surge_bt_periodic, 0.4)
	surge_bt.set_buff_tooltip("Magnetic Surge\nDeals damage over time.")

	aura_bt = BuffType.create_aura_effect_type("aura_bt", false, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/electric.tres")
	aura_bt.add_event_on_damaged(aura_bt_on_damaged)
	aura_bt.set_buff_tooltip("Energetic Field Aura\nIncreases damage taken from Storm towers.")


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	autocast.title = "Magnetic Surge"
	autocast.icon = "res://resources/icons/electricity/electricity_blue.tres"
	autocast.description_short = "This tower creates a [color=GOLD]Magnetic Surge[/color] at its target's current location. Target will take periodic damage.\n"
	autocast.description = "This tower creates a [color=GOLD]Magnetic Surge[/color] at the target's current location. The creep will suffer spell damage equal to 4 times the distance to the spot where the surge was created every 0.4 seconds. This effect lasts 4 seconds.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+2% spell damage\n" \
	+ "+0.1 seconds duration\n"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.num_buffs_before_idle = 1
	autocast.cast_range = 1000
	autocast.auto_range = 1000
	autocast.cooldown = 4
	autocast.mana_cost = 40
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast

	return [autocast]


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var storm_string: String = Element.convert_to_colored_string(Element.enm.STORM)

	aura.name = "Energetic Field"
	aura.icon = "res://resources/icons/tower_icons/magic_battery.tres"
	aura.description_short = "Units in range receive extra damage from %s towers. Effect is stronger for creeps far away.\n" % storm_string
	aura.description_full = "Units in %d range around this tower are dealt up to 20%% bonus damage by %s towers. The further away creeps are from tower, the more damage is dealt.\n" % [AURA_RANGE, storm_string] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.6% maximum damage\n"

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 0
	aura.aura_effect = aura_bt

	return [aura]


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var distance_to_target: float = tower.get_position_wc3_2d().distance_to(target.get_position_wc3_2d())
	var damage: float = distance_to_target * 12.0 * tower.get_current_attack_damage_with_bonus() / tower.get_base_damage()

	tower.do_attack_damage(target, damage, tower.calc_attack_multicrit_no_bonus())
	tower.get_player().display_floating_text_x(str(int(damage)), target, Color8(255, 200, 0, 255), 0.05, 0.0, 2.0)

	var slow_buff_level: int = floori(distance_to_target * 3)
	slow_bt.apply(tower, target, slow_buff_level)


func on_autocast(event: Event):
	var creep: Unit = event.get_target()

	var buff: Buff = surge_bt.apply(tower, creep, tower.get_level())
	buff.user_real = creep.get_x()
	buff.user_real2 = creep.get_y()


func surge_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var surge_pos: Vector2 = Vector2(buff.user_real, buff.user_real2)
	var distance_to_target: float = surge_pos.distance_to(target.get_position_wc3_2d())
	var damage: float = 4 * distance_to_target * (1 + 0.02 * tower.get_level())

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())
	tower.get_player().display_floating_text_x(str(int(damage)), target, Color8(150, 150, 255, 255), 0.05, 0.0, 2.0)
	SFX.sfx_at_unit("AIlbSpecialArt.mdl", target)


func aura_bt_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var tower_pos: Vector2 = tower.get_position_wc3_2d()
	var target_pos: Vector2 = target.get_position_wc3_2d()
	var distance_to_target: float = tower_pos.distance_to(target_pos)
	var damage_multiplier: float = 1.0 + distance_to_target * (0.00020 + 0.000006 * tower.get_level())
	var attacking_tower: Tower = event.get_target()
	var attacking_element: Element.enm = attacking_tower.get_element()

	if attacking_element == Element.enm.STORM:
		event.damage *= damage_multiplier
