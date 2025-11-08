class_name CreepEvolving extends BuffType

# NOTE: this special is not affected by silence, on purpose.
# This is how it was in the original game.


func _init(parent: Node):
	super("creep_evolving", 0, 0, true, parent)

	add_event_on_damaged(on_damaged)
	add_event_on_create(on_create)


func on_create(event: Event):
	var buff: Buff = event.get_buff()
	buff.user_int = 0


func on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()

	var life_max: float = creep.get_overall_health()
	var damage_ratio: float = Utils.divide_safe(event.damage, life_max)

	var attacker: Unit = event.get_target()
	var tower: Tower = attacker as Tower

	if tower == null:
		return

	var element: Element.enm = tower.get_element()

	var proc_count: int = buff.user_int

	if damage_ratio > 0.05:
		var mod_type: ModificationType.enm = Element.convert_to_dmg_from_element_mod(element)

		var mod_value: float = -0.4
		for i in range(0, proc_count):
			mod_value /= 2

		creep.modify_property(mod_type, mod_value)

		var new_proc_count: int = proc_count + 1
		buff.user_int = new_proc_count
