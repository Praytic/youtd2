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
	ethereal_active_buff.set_buff_icon("res://resources/icons/generic_icons/aries.tres")
	ethereal_active_buff.set_buff_icon_color(Color.CYAN)
	ethereal_active_buff.set_buff_tooltip(tr("W31K"))

	add_periodic_event(on_periodic, ETHEREAL_PERIOD)


func on_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	var creep_is_silenced: bool = creep.is_silenced()

	if creep_is_silenced:
		return

	ethereal_active_buff.apply(creep, creep, 0)


func on_damaged(event: Event):
	var caster: Unit = event.get_target()
	var is_arcane: bool = caster.get_attack_type() == AttackType.enm.ARCANE

	if event.is_spell_damage() || is_arcane:
		event.damage *= 1.4
	else:
		event.damage = 0


# NOTE: these two f-ns make the creep look transparent while
# ethereal
func on_create(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	creep.set_sprite_color(Color.html("aaffaaaa"))
	creep.add_ethereal()


func on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	creep.set_sprite_color(Color.WHITE)
	creep.remove_ethereal()
