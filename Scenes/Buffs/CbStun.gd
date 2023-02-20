class_name CbStun
extends Buff


func _init().("cb_stun"):
	add_event_handler(Buff.EventType.CREATE, self, "_on_create")
	add_event_handler(Buff.EventType.EXPIRE, self, "_on_expire")


func _on_create(_event: Event):
	get_buffed_unit().movement_enabled = false

#	NOTE: adding stun visual to buff instead of mob for
#	automatic removal when buff expires
	var stun_visual = load("res://Scenes/StunVisual.tscn").instance()
	add_child(stun_visual)


func _on_expire(_event: Event):
	get_buffed_unit().movement_enabled = true
