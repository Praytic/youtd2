extends TowerBehavior


var aura_bt: BuffType
var slow_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	slow_bt = BuffType.new("slow_bt", 0.5, 0.012, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.60, 0.0)
	slow_bt.set_buff_modifier(mod)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/hammer_drop.tres")
	slow_bt.set_buff_tooltip("Smashed\nReduces movement speed.")

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/cog.tres")
	aura_bt.add_event_on_attack(aura_bt_on_attack)
	aura_bt.set_buff_tooltip("Earthquake Aura\nChance to trigger Ground Smash.")


func on_damage(_event: Event):
	CombatLog.log_ability(tower, null, "Ground Smash")

	smash()


func aura_bt_on_attack(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Tower = buff.get_buffed_unit()
	var ground_smash_chance: float = (0.03 + 0.0004 * tower.get_level()) * buffed_tower.get_base_attack_speed()

	if !buffed_tower.calc_chance(ground_smash_chance):
		return

	CombatLog.log_ability(buffed_tower, null, "Ground Smash")

	smash()


func smash():
	var level: int = tower.get_level()
	var smash_damage: float = (4300 + 230 * level) * tower.get_prop_spell_damage_dealt()

	var smash_range: float
	if level == 25:
		smash_range = 800
	else:
		smash_range = 750

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), smash_range)
	
	while true:
		var next: Unit = it.next()

		if next == null:
			break

		if next.get_size() == CreepSize.enm.AIR:
			continue

#		NOTE: using do_attack_damage() with args based on
#		spell damage is not a typo. Written this way in
#		original script on purpose.
		slow_bt.apply(tower, next, level)
		tower.do_attack_damage(next, smash_damage, tower.calc_spell_crit_no_bonus())
