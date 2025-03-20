class_name CreepSpellbinder extends BuffType


var silence_bt: BuffType


func _init(parent: Node):
	super("creep_spellbinder", 0, 0, true, parent)

	silence_bt = CbSilence.new("silence_bt", 0, 0, false, self)

	add_event_on_create(on_create)


func on_create(event: Event):
	var autocast: Autocast = Autocast.make_from_id(173, self)
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	creep.add_autocast(autocast)


func on_autocast(event: Event):
	var autocast: Autocast = event.get_autocast_type()
	var creep: Unit = autocast.get_caster()

	var I: Iterate = Iterate.over_units_in_range_of_caster(creep, TargetType.new(TargetType.TOWERS), 1100.0)

	var zap_count: int = 0

	while true:
		var tower: Unit = I.next_random()

		if tower == null:
			break

		var creep_mana_before: float = creep.get_mana()

		if zap_count >= 3:
			break

		var tower_mana_before: float = tower.get_mana()
		var stolen_mana: float = tower_mana_before * 0.3

		var creep_mana_after: float = creep_mana_before + stolen_mana
		creep.set_mana(creep_mana_after)

		var tower_mana_after: float = tower_mana_before - stolen_mana
		tower.set_mana(tower_mana_after)

		silence_bt.apply_only_timed(creep, tower, 5.0) 

		zap_count += 1
