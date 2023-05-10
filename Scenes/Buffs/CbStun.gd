class_name CbStun
extends BuffType

var _stun_effect_map: Dictionary

func _init(type: String, time_base: float, time_level_add: float,friendly: bool, parent: Node):
	super(type, time_base, time_level_add, friendly, parent)
	add_event_on_create(on_create)
	set_event_on_cleanup(_on_cleanup)

#	NOTE: this is the default tooltip for stun buff. It may
#	be overriden in buffs that extend this buff.
	set_buff_tooltip("Stunned\nThis unit is stunned and can't perform any actions.")


func on_create(event: Event):
	var buff: Buff = event.get_buff()
	var target = buff.get_buffed_unit()

	target.set_stunned(true)

	var stun_effect: int = Effect.create_simple_at_unit("res://Scenes/Effects/StunVisual.tscn", target)
	_stun_effect_map[buff] = stun_effect


func _on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var target = buff.get_buffed_unit()

	target.set_stunned(false)
	
	var stun_effect: int = _stun_effect_map[buff]
	Effect.destroy_effect(stun_effect)
