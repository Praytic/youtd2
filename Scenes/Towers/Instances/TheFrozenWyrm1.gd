extends Tower


var cassim_wyrm_slow_bt: BuffType
var cassim_wyrm_stun_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Freezing Breath[/color]\n"
	text += "Each creep damaged by this tower's attacks has a 25% chance to get slowed by 27% for 4 seconds and a 5% chance to get stunned for 1.5 seconds.\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Freezing Breath[/color]\n"
	text += "Chance to slow or stun damaged creeps.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	_set_attack_style_splash({550: 0.20})


func tower_init():
	cassim_wyrm_stun_bt = CbStun.new("cassim_wyrm_stun_bt", 1.5, 0.0, false, self)
	cassim_wyrm_stun_bt.set_buff_icon("@@1@@")

	cassim_wyrm_slow_bt = BuffType.new("cassim_wyrm_slow_bt", 4.0, 0.24, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.27, -0.002)
	cassim_wyrm_slow_bt.set_buff_modifier(mod)
	cassim_wyrm_slow_bt.set_buff_icon("@@0@@")
	cassim_wyrm_slow_bt.set_buff_tooltip("Freezing Breath\nThis creep was under the Freezing Breath; it has reduced movement speed.")


func on_damage(event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	var target: Creep = event.get_target()
	var slow_chance: float = 0.25 + 0.01 * level
	var stun_chance: float = 0.05 + 0.002 * level

	if tower.calc_chance(slow_chance):
		cassim_wyrm_slow_bt.apply(tower, target, level)

	if tower.calc_chance(stun_chance):
		cassim_wyrm_stun_bt.apply(tower, target, level)

