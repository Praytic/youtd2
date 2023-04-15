class_name CbStun
extends BuffType

var _stun_effect_map: Dictionary

func _init(type: String, time_base: float, time_level_add: float,friendly: bool):
	super(type, time_base, time_level_add, friendly)
	add_event_on_create(self, "on_create")
	set_event_on_cleanup(self, "_on_cleanup")


func on_create(event: Event):
	var buff: Buff = event.get_buff()
	var target = buff.get_buffed_unit()

	target.movement_enabled = false 

	var stun_effect: int = Effect.create_simple_at_unit("res://Scenes/Effects/StunVisual.tscn", target)
	_stun_effect_map[buff] = stun_effect


func _on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var target = buff.get_buffed_unit()

	target.movement_enabled = true
	
	var stun_effect: int = _stun_effect_map[buff]
	Effect.destroy_effect(stun_effect)
