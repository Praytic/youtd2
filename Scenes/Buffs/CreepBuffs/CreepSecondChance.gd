class_name CreepSecondChance extends BuffType


# TODO: what is the value of heal and does it consume mana?
# Currently creep heals for how much damage is taken.


func _init(parent: Node):
	super("creep_second_chance", 0, 0, true, parent)
	add_event_on_damaged(on_damaged)


func on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()

	var life: float = Unit.get_unit_state(creep, Unit.State.LIFE)
	var mana_ratio: float = creep.get_mana_ratio()
	var damage_is_mortal: bool = (life - event.damage) <= 0
	var chance_success: bool = creep.calc_chance(0.5)
	var enough_mana: bool = mana_ratio > 0.33

	if damage_is_mortal && chance_success && enough_mana:
		var life_after_heal: float = life + event.damage
		Unit.set_unit_state(creep, Unit.State.LIFE, life_after_heal)
