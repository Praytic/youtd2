class_name CbStun
extends BuffType

# NOTE: analog of globally available cb_stun in JASS


# These values calibrate diminishing returns for stuns on
# creeps. Stuns will start to randomly cancel after the
# "min" value (in seconds). The chance to cancel stun
# reaches 100% at "max" value. Note that even at 100%
# chance, stuns will still apply and last for a short
# time(~0.3s) until periodic callback is called.
const DIMINISHING_RETURNS_MIN: float = 15.0
const DIMINISHING_RETURNS_MAX: float = 30.0


# NOTE: BuffType.createDuplicate(cb_stun...) in JASS
func _init(type: String, time_base: float, time_level_add: float,friendly: bool, parent: Node):
	super(type, time_base, time_level_add, friendly, parent)
	add_event_on_create(on_create)
	add_periodic_event(periodic, 0.3)
	add_event_on_cleanup(_on_cleanup)

#	NOTE: this is the default tooltip for stun buff. It may
#	be overriden in buffs that extend this buff.
	set_buff_tooltip("Stun\nStunned.")
	set_buff_icon("res://resources/icons/generic_icons/knocked_out_stars.tres")
	set_buff_icon_color(Color.WHITE)


func on_create(event: Event):
	var buff: Buff = event.get_buff()
	var target = buff.get_buffed_unit()

	target.add_stun()


# This function implements Diminishing Returns for stuns.
func periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target = buff.get_buffed_unit()

	if !target is Creep:
		return

	var total_stun_duration: float = target.get_total_stun_duration()

	var chance_to_cancel_stun: float = (total_stun_duration - DIMINISHING_RETURNS_MIN) / (DIMINISHING_RETURNS_MAX - DIMINISHING_RETURNS_MIN)
	chance_to_cancel_stun = clampf(chance_to_cancel_stun, 0.0, 1.0)

	if Utils.rand_chance(Globals.synced_rng, chance_to_cancel_stun):
		buff.remove_buff()


func _on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var target = buff.get_buffed_unit()

	target.remove_stun()
