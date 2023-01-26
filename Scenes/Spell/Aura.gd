extends Node


# Aura contains information about it's parameters and timers
# that determine when the aura applies and expires. Aura's
# should be used via AuraContainer, which manages their
# lifetime and application logic.

class_name Aura


signal applied(aura)
signal expired(aura)
signal killing_blow()


var type: int
var value_abs: float
var duration: float
var period: float

var is_expired: bool = false
var timer_list: Array = []
var run_called_first_time: bool = true
var is_running: bool = false


func _init(aura_info):
	type = aura_info[Properties.AuraParameter.TYPE]
	duration = aura_info[Properties.AuraParameter.DURATION]
	period = aura_info[Properties.AuraParameter.PERIOD]

	var value_is_range: bool = aura_info[Properties.AuraParameter.VALUE] is Array

	if value_is_range:
		var value_range: Array = aura_info[Properties.AuraParameter.VALUE] as Array

		value_abs = Utils.randi_range(int(value_range[0]), int(value_range[1]))
	else:
		value_abs = aura_info[Properties.AuraParameter.VALUE] as float


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func on_duration_timer_timeout():
	expire()


func on_period_timer_timeout():
	apply()

func apply():
	emit_signal("applied", self)


func expire():
	is_expired = true
	emit_signal("expired", self)
	queue_free()


# Get value with sign applied
func get_value() -> float:
	var value_sign: int = Properties.aura_value_sign_map[type]
	var value: float = value_sign * value_abs

	return value


func run():
	is_running = true

	if run_called_first_time:
		run_called_first_time = false

		if is_instant():
			apply()
			expire()
		elif is_status():
			apply()

		if duration > 0:
			var duration_timer: Timer = Timer.new()
			timer_list.append(duration_timer)
			add_child(duration_timer)
			duration_timer.connect("timeout", self, "on_duration_timer_timeout")
			duration_timer.start(duration)

		if period > 0:
			var period_timer: Timer = Timer.new()
			timer_list.append(period_timer)
			add_child(period_timer)
			period_timer.connect("timeout", self, "on_period_timer_timeout")
			period_timer.start(period)
	else:
		for timer in timer_list:
			timer.set_paused(false)


func pause():
	is_running = false
	
	for timer in timer_list:
		timer.set_paused(true)


func get_abs_dps() -> float:
	if period > 0:
		return value_abs / period
	else:
		return value_abs


func is_instant() -> bool:
	return duration == 0 && period == 0


func is_status() -> bool:
	return duration > 0 && period == 0


func is_poison() -> bool:
	return duration > 0 && period > 0


# NOTE: important to compare absolute values because if the
# aura sign is negative, the most negative aura will be the
# strongest
func is_stronger_than(other: Aura) -> bool:
	if is_poison():
		var this_dps: float = self.get_abs_dps()
		var other_dps: float = other.get_abs_dps()
		var is_stronger: bool = this_dps > other_dps

		return is_stronger
	else:
		var this_value: float = self.value_abs
		var other_value: float = other.value_abs
		var is_stronger: bool = this_value > other_value

		return is_stronger


func notify_about_killing_blow():
	emit_signal("killing_blow")