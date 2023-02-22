class_name CbStun
extends Buff

var stun_effect: int

func _init().("cb_stun"):
	add_event_handler(Buff.EventType.CREATE, self, "_on_create")
	add_event_handler(Buff.EventType.CLEANUP, self, "_on_cleanup")


func _on_create(_event: Event):
	var target = get_buffed_unit()

	target.movement_enabled = false 

	stun_effect = Effect.create_animated("res://Scenes/StunVisual.tscn", target.position.x, target.position.y, 0, 0)


func _on_cleanup(_event: Event):
	get_buffed_unit().movement_enabled = true
	
	Effect.destroy_effect(stun_effect)
