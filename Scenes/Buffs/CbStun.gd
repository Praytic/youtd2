class_name CbStun
extends Buff

var stun_effect: int

func _init(type: String, time_base: float, time_level_add: float,friendly: bool):
	super(type, time_base, time_level_add, friendly)
	add_event_on_create(self, "_on_create")
	set_event_on_cleanup(self, "_on_cleanup")


func _on_create(_event: Event):
	var target = get_buffed_unit()

	target.movement_enabled = false 

	stun_effect = Effect.create_animated("res://Scenes/Effects/StunVisual.tscn", target.position.x, target.position.y, 0, 0)


func _on_cleanup(_event: Event):
	get_buffed_unit().movement_enabled = true
	
	Effect.destroy_effect(stun_effect)
