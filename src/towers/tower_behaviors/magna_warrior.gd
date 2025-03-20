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
