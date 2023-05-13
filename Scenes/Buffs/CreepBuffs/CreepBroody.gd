class_name CreepBroody extends BuffType


func _init(parent: Node):
	super("creep_broody", 0, 0, true, parent)

	add_event_on_create(on_create)


func on_create(event: Event):
	var autocast: Autocast = Autocast.make()
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.cast_range = 1200
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 6
	autocast.is_extended = false
	autocast.mana_cost = 30
	autocast.buff_type = null
	autocast.target_type = null
	autocast.auto_range = 0
	autocast.handler = on_autocast

	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	creep.add_autocast(autocast)


# TODO: lay an egg here
func on_autocast(_event: Event):
	pass
