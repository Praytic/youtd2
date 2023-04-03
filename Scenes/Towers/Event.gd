class_name Event


enum Type {
	CLEANUP,
	CREATE,
	UPGRADE,
	REFRESH,
	DEATH,
	KILL,
	LEVEL_UP,
	ATTACK,
	ATTACKED,
	DAMAGE,
	DAMAGED,
	EXPIRE,
	SPELL_CAST,
	SPELL_TARGET,
	PURGE,
}


var _buff: Buff
# NOTE: damage may be modified in event handlers to change
# the final effect of the event
var damage: float
# target is of type Unit, can't use typing because of cyclic dependency...
var _target: Unit
# Only relevant for damage/damaged events. True for damage
# from normal tower attacks, for main target of splash tower
# attacks and for first target of tower bounce attack.
var _is_main_target: bool = false
# Only relevant for damaged events. True if damaged event is
# caused by spell damage.
var _is_spell_damage: bool = false
# Timer belonging to a buff that triggered this event. Used
# for cases where periodic event handler needs to modify
# duration of periodic event.
var _timer: Timer = null


#########################
### Code starts here  ###
#########################

func _init(target: Unit):
	_target = target


#########################
### Setters / Getters ###
#########################

func get_buff() -> Buff:
	return _buff

func get_target() -> Unit:
	return _target

func is_main_target() -> bool:
	return _is_main_target

func is_spell_damage() -> bool:
	return _is_spell_damage

func enable_advanced(wait_time: float, one_shot: bool):
	if _timer == null:
		return

	_timer.wait_time = wait_time
	_timer.one_shot = one_shot
