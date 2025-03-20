extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] (NOT FIXED) this tower will deal
# 0 damage if Frost Bolt ability hits a creep with no Icy
# Touch stacks. Kind of weird.


var cold_blood_bt: BuffType
var icy_touch_bt: BuffType
var frostbolt_pt: ProjectileType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_kill(on_kill)


func tower_init():
	cold_blood_bt = BuffType.new("cold_blood_bt", 3, 0, true, self)
	var dave_taita_blood_mod: Modifier = Modifier.new()
	dave_taita_blood_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.5, 0.005)
	cold_blood_bt.set_buff_modifier(dave_taita_blood_mod)
	cold_blood_bt.set_buff_icon("res://resources/icons/generic_icons/azul_flake.tres")
	cold_blood_bt.set_buff_tooltip("Cold Blood\nIncreases attack speed.")

	icy_touch_bt = BuffType.new("icy_touch_bt", 5, 0, false, self)
	var dave_taita_touch_mod: Modifier = Modifier.new()
	dave_taita_touch_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.1)
	icy_touch_bt.set_buff_modifier(dave_taita_touch_mod)
	icy_touch_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	icy_touch_bt.set_buff_tooltip("Icy Touch\nReduces movement speed.")

	frostbolt_pt = ProjectileType.create("path_to_projectile_sprite", 4, 900, self)
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
	var buff: Buff = target.get_buff_of_type(icy_touch_bt)
	var buff_level: int = 0
	var damage: float = tower.get_current_attack_damage_with_bonus()
	var level: int = tower.get_level()

	if buff != null:
		buff_level = buff.get_level()
		event.damage = event.damage * (1 + buff_level * (0.1 + 0.02 * level))

	if buff_level < 6:
		icy_touch_bt.apply(tower, target, buff_level + 1)

	buff = target.get_buff_of_type(icy_touch_bt)
	if buff != null:
		buff.set_displayed_stacks(buff.get_level())


func on_kill(_event: Event):
	var level: int = tower.get_level()

	cold_blood_bt.apply(tower, tower, level)


func frostbolt_pt_on_hit(_p: Projectile, creep: Unit):
	if creep == null:
		return

	var level: int = tower.get_level()
	var buff: Buff = creep.get_buff_of_type(icy_touch_bt)

	var buff_level: int
	if buff != null:
		buff_level = buff.get_level()
	else:
		buff_level = 0

	var damage: float = tower.get_current_attack_damage_with_bonus() * buff_level * (0.2 + (0.004 * level))
	if creep.is_stunned():
		damage *= 2

	CombatLog.log_ability(tower, creep, "Frost Bolt Hit AoE")

	tower.do_attack_damage_aoe_unit(creep, 200, damage, tower.calc_attack_multicrit_no_bonus(), 0.0)
