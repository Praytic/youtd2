extends TowerBehavior


var slow_bt: BuffType
var stun_bt: BuffType


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Freezing Breath"
	ability.icon = "res://resources/icons/elements/ice.tres"
	ability.description_short = "Whenever this tower hits a creep, it has a chance to slow or stun the target.\n"
	ability.description_full = "Whenever this tower hits a creep, it has a 25% chance to slow the target by 27% for 4 seconds and a 5% chance to stun the target for 1.5 seconds.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1% chance to slow\n" \
	+ "+0.2% chance to stun\n" \
	+ "+0.2% slow\n" \
	+ "+0.24s slow duration\n"
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	tower.set_attack_style_splash({550: 0.20})


func tower_init():
	stun_bt = CbStun.new("stun_bt", 1.5, 0.0, false, self)

	slow_bt = BuffType.new("slow_bt", 4.0, 0.24, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.27, -0.002)
	slow_bt.set_buff_modifier(mod)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/energy_breath.tres")
	slow_bt.set_buff_tooltip("Freezing Breath\nReduces movement speed.")


func on_damage(event: Event):
	var level: int = tower.get_level()
	var target: Creep = event.get_target()
	var slow_chance: float = 0.25 + 0.01 * level
	var stun_chance: float = 0.05 + 0.002 * level

	if tower.calc_chance(slow_chance):
		CombatLog.log_ability(tower, target, "Freezing Breath slow")
		slow_bt.apply(tower, target, level)

	if tower.calc_chance(stun_chance):
		CombatLog.log_ability(tower, target, "Freezing Breath stun")
		stun_bt.apply(tower, target, level)

