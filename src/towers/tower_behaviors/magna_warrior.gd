extends TowerBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] Renamed
# "Magnataur Warrior"=>"Magna Warrior"


var stun_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {on_damage_chance = 0.10, damage_add = 0.01},
		2: {on_damage_chance = 0.11, damage_add = 0.02},
		3: {on_damage_chance = 0.12, damage_add = 0.03},
		4: {on_damage_chance = 0.13, damage_add = 0.04},
		5: {on_damage_chance = 0.14, damage_add = 0.05},
}


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var on_damage_chance: String = Utils.format_percent(_stats.on_damage_chance, 2)
	var damage_add: String = Utils.format_percent(_stats.damage_add, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Frozen Spears"
	ability.icon = "res://resources/icons/spears/many_spears_02.tres"
	ability.description_short = "Chance to deal additional attack damage and stun hit creeps.\n"
	ability.description_full = "%s chance to deal 50%% additional attack damage and stun hit creeps for 0.5 seconds.\n" % on_damage_chance \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage\n" % damage_add \
	+ "+0.01 seconds\n"
	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func tower_init():
	stun_bt = CbStun.new("stun_bt", 1.0, 0, false, self)


func on_damage(event: Event):
	if !tower.calc_chance(_stats.on_damage_chance):
		return

	var creep: Unit = event.get_target()
	var level: float = tower.get_level()

	CombatLog.log_ability(tower, creep, "Frozen Spears")

	if event.is_main_target():
		event.damage = event.damage * (1.5 + (_stats.damage_add * level))
		Effect.create_simple_at_unit("res://src/effects/blood_splatter.tscn", creep)
		stun_bt.apply_only_timed(tower, creep, 0.5 + tower.get_level() * 0.01)
		var damage_text: String = Utils.format_float(event.damage, 0)
		tower.get_player().display_small_floating_text(damage_text, tower, Color8(255, 150, 150), 0)
