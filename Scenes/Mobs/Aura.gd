extends Node


class_name Aura


signal applied(aura)
signal expired(aura)


var type: String
var value_is_range: bool
var value_fixed: float
var value_min: float
var value_max: float
var duration: float
var period: float

var is_expired: bool = false
var timer_list: Array = []
var run_called_first_time: bool = true
var is_running: bool = false


func _init(aura_info):
	type = aura_info["type"]
	duration = aura_info["duration"]
	period = aura_info["period"]

	value_is_range = aura_info["value"] is Array

	if value_is_range:
		var value_range: Array = aura_info["value"] as Array

		value_min = min(value_range[0], value_range[1])
		value_max = max(value_range[0], value_range[1])
	else:
		value_fixed = aura_info["value"] as float


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


# NOTE: not sure what to do here about float vs int
# It seems like values need to be float sometimes (when?)
# But want to do randomization as ints.
func get_value() -> float:
	if value_is_range:
		var out = Utils.randi_range(int(value_min), int(value_max))
		return out
	else:
		return value_fixed


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


func get_dps() -> float:
	if period > 0:
		return get_value() / period
	else:
		return get_value()


func is_instant() -> bool:
	return duration == 0 && period == 0


func is_status() -> bool:
	return duration > 0 && period == 0


func is_poison() -> bool:
	return duration > 0 && period > 0
