class_name CreepMeaty extends BuffType


func _init(parent: Node):
	super("creep_meaty", 0, 0, true, parent)

	add_event_on_death(on_death)


func on_death(event: Event):
	var buff: Buff = event.get_buff()
	var unit: Unit = buff.get_buffed_unit()
	var caster: Unit = event.get_target()

	var creep: Creep = unit as Creep

	if creep == null:
		return

#	NOTE: this condition is a bit confusing. The way it
#	works is that if creep is below max level, it will
#	always drop food. If it's above max level, it has 10%
#	chance to drop food. Currently, creeps can't go above
#	max level so this only applies to a potential future
#	"neverending" game length.
	if creep.get_spawn_level() < Utils.get_max_level() || creep.calc_bad_chance(0.1):
		creep.drop_item_by_id(caster, false, ItemProperties.CONSUMABLE_CHICKEN_ID)
