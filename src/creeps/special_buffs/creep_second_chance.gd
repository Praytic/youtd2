class_name CreepSecondChance extends BuffType

# NOTE: this special is not affected by silence, on purpose.
# This is how it was in the original game.


func _init(parent: Node):
	super("creep_second_chance", 0, 0, true, parent)
	add_event_on_damaged(on_damaged)


func on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()

	var life: float = creep.get_health()
	var mana_ratio: float = creep.get_mana_ratio()
	var damage_is_mortal: bool = (life - event.damage) <= 0
	var chance_success: bool = creep.calc_chance(0.5)
	var enough_mana: bool = mana_ratio > 0.33

	if damage_is_mortal && chance_success && enough_mana:
		var life_after_heal: float = Globals.synced_rng.randf_range(0.2, 1.0) * creep.get_overall_health() * mana_ratio + event.damage
		creep.set_health_over_max(life_after_heal)
		var mana_to_subtract: float = creep.get_overall_mana() / 3
		creep.subtract_mana(mana_to_subtract, false)
		creep.get_player().display_floating_text(tr("CREEP_SPECIAL_SECOND_CHANCE"), creep, Color.RED)

#		NOTE: this is how it works in original game. Need to
#		modify lowest health so that the creep deals less
#		portal damage after reviving.
		creep._lowest_health = creep.get_health() * creep.get_mana_ratio()
