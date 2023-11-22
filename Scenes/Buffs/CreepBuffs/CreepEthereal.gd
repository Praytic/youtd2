class_name CreepEthereal extends BuffType


const ETHEREAL_PERIOD: float = 5.0
const ETHEREAL_DURATION: float = 2.0


var ethereal_active_buff: BuffType


func _init(parent: Node):
	super("creep_ethereal", 0, 0, true, parent)

	ethereal_active_buff = BuffType.new("creep_ethereal_active", ETHEREAL_DURATION, 0, true, self)
	ethereal_active_buff.add_event_on_damaged(on_damaged)
	ethereal_active_buff.add_event_on_create(on_create)
	ethereal_active_buff.add_event_on_cleanup(on_cleanup)
	ethereal_active_buff.set_buff_tooltip("Ethereal\nThis unit is Ethereal; it is immune against physical attacks but will take more damage from magic attacks and spells.")

	add_periodic_event(on_periodic, ETHEREAL_PERIOD)


func on_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()

	ethereal_active_buff.apply(creep, creep, 0)


func on_damaged(event: Event):
	var caster: Unit = event.get_target()
	var is_magic: bool = caster.get_attack_type()

	if event.is_spell_damage() || is_magic:
		event.damage *= 1.4
	else:
		event.damage = 0


# NOTE: these two f-ns make the creep look transparent while
# ethereal
func on_create(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	creep.set_sprite_color(Color.html("aaffaaaa"))


func on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	creep.set_sprite_color(Color.WHITE)
