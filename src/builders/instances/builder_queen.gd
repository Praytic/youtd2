extends Builder


func _get_tower_modifier() -> Modifier:
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_ATTACKSPEED, 0.10, 0.0)
	mod.add_modification(ModificationType.enm.MOD_DMG_TO_AIR, 0.30, 0.02)

	return mod


func _get_creep_buff() -> BuffType:
	var queen_bt: BuffType = BuffType.new("queen_bt", 0, 0, false, self)
	queen_bt.add_event_on_create(_creep_bt_on_create)

	return queen_bt


func _creep_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var creep: Creep = buffed_unit as Creep

	if creep == null:
		return

	var creep_size: CreepSize.enm = creep.get_size()

	if creep_size == CreepSize.enm.AIR:
		creep.modify_property(ModificationType.enm.MOD_MOVESPEED_ABSOLUTE, -60)
