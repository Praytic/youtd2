extends Node


class_name Aura


signal applied(aura)
signal expired(aura)


var type: String
var value: float
var duration: float
var period: float

var is_expired: bool = false


func _init(aura_info):
	type = aura_info["type"]
	value = aura_info["value"]
	duration = aura_info["duration"]
	period = aura_info["period"]


# Called when the node enters the scene tree for the first time.
func _ready():
#	NOTE: apply aura when it is created
#	This means that for periodic aura's, their first tick happens
#	when aura is created.
	apply()

	var aura_is_instant = duration == 0
	
	if duration > 0:
		var duration_timer: Timer = Timer.new()
		add_child(duration_timer)
		duration_timer.connect("timeout", self, "on_duration_timer_timeout")
		duration_timer.start(duration)
	else:
#		Aura's with duration of 0 are "instant", meaning that they apply
# 		once when created and then expire
		expire()

	if period > 0:
		var period_timer: Timer = Timer.new()
		add_child(period_timer)
		period_timer.connect("timeout", self, "on_period_timer_timeout")
		period_timer.start(period)


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
