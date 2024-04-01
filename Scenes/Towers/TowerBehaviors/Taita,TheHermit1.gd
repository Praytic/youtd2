extends TowerBehavior


# NOTE: this tower will deal 0 damage if frost bolt hits a
# creep with no Icy Touch stacks. Kind of weird.


var dave_taita_blood_bt: BuffType
var dave_taita_touch_bt: BuffType
var frostbolt_pt: ProjectileType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Frost Bolt[/color]\n"
	text += "On attack, this tower has a chance, equal to the percentage of movement speed the attacked unit is missing, to launch a frost bolt, dealing 20% of the tower's attack damage as elemental damage in 200 AoE around the target for each stack of icy touch the creep has. This spell deals double damage to stunned targets.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% damage per stack\n"
	text += " \n"

	text += "[color=GOLD]Icy Touch[/color]\n"
	text += "Each attack slows the attacked unit by 10% for 5 seconds, stacking up to 6 times. This tower deals additional 10% damage for every stack of icy touch the target has.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.2% damage per stack\n"
	text += " \n"

	text += "[color=GOLD]Cold Blood[/color]\n"
	text += "Every time it kills a unit, this tower gains 50% attack speed for 3 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.5% attack speed\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Frost Bolt[/color]\n"
	text += "Chance to launch a frost bolt, dealing AoE damage around the target.\n"
	text += " \n"

	text += "[color=GOLD]Icy Touch[/color]\n"
	text += "Each attack slows the attacked unit..\n"
	text += " \n"

	text += "[color=GOLD]Cold Blood[/color]\n"
	text += "Every time it kills a unit, this tower temporarily gains attack speed.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_kill(on_kill)


func tower_init():
	dave_taita_blood_bt = BuffType.new("dave_taita_blood_bt", 3, 0, true, self)
	var dave_taita_blood_mod: Modifier = Modifier.new()
	dave_taita_blood_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.5, 0.005)
	dave_taita_blood_bt.set_buff_modifier(dave_taita_blood_mod)
	dave_taita_blood_bt.set_buff_icon("crystal.tres")
	dave_taita_blood_bt.set_buff_tooltip("Cold Blood\nIncreases attack speed.")

	dave_taita_touch_bt = BuffType.new("dave_taita_touch_bt", 5, 0, false, self)
	var dave_taita_touch_mod: Modifier = Modifier.new()
	dave_taita_touch_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.1)
	dave_taita_touch_bt.set_buff_modifier(dave_taita_touch_mod)
	dave_taita_touch_bt.set_buff_icon("cup_with_wings.tres")
	dave_taita_touch_bt.set_buff_tooltip("Icy Touch\nReduces movement speed.")

	frostbolt_pt = ProjectileType.create("FreezingBreathMissile.mdl", 4, 900, self)
	frostbolt_pt.enable_homing(frostbolt_pt_on_hit, 0)


func on_attack(event: Event):
	var creep: Unit = event.get_target()
	var speed: float = Constants.DEFAULT_MOVE_SPEED
	var current_speed: float = creep.get_current_movespeed()
	var slow: float = (speed - current_speed) / speed

	if !tower.calc_chance(slow):
		return

	CombatLog.log_ability(tower, creep, "Frost Bolt")

	Projectile.create_from_unit_to_unit(frostbolt_pt, tower, 1, 1, tower, creep, true, false, false)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var buff: Buff = target.get_buff_of_type(dave_taita_touch_bt)
	var buff_level: int = 0
	var damage: float = tower.get_current_attack_damage_with_bonus()
	var level: int = tower.get_level()

	if buff != null:
		buff_level = buff.get_level()
		event.damage = event.damage * (1 + buff_level * (0.1 + 0.02 * level))

	if buff_level < 6:
		dave_taita_touch_bt.apply(tower, target, buff_level + 1)


func on_kill(_event: Event):
	var level: int = tower.get_level()

	dave_taita_blood_bt.apply(tower, tower, level)


func frostbolt_pt_on_hit(_p: Projectile, creep: Unit):
	if creep == null:
		return

	var level: int = tower.get_level()
	var buff: Buff = creep.get_buff_of_type(dave_taita_touch_bt)

	var buff_level: int
	if buff != null:
		buff_level = buff.get_level()
	else:
		buff_level = 0

	var damage: float = tower.get_current_attack_damage_with_bonus() * buff_level * (0.2 + (0.004 * level))
	if creep.is_stunned():
		damage *= 2

	CombatLog.log_ability(tower, creep, "Frost Bolt Hit AOE")

	tower.do_attack_damage_aoe_unit(creep, 200, damage, tower.calc_attack_multicrit_no_bonus(), 0.0)
