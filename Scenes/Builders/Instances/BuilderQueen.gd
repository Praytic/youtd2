extends Builder


func _get_tower_buff() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.10, 0.0)
	mod.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.30, 0.02)
	bt.set_buff_modifier(mod)

	return bt


func _get_creep_buff() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, false, self)
	bt.add_event_on_create(_creep_bt_on_create)

	return bt


func _creep_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var creep: Creep = buffed_unit as Creep

	if creep == null:
		return

	var creep_size: CreepSize.enm = creep.get_size()

	if creep_size == CreepSize.enm.AIR:
		creep.modify_property(Modification.Type.MOD_MOVESPEED_ABSOLUTE, -60)
