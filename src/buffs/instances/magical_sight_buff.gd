class_name MagicalSightBuff
extends BuffType

# Magical sight effect, makes creeps in radius visible. Creeps
# become invisible again once they leave range. Note that if
# creep leaves range of a unit with magical sight but stays in
# range of another unit with magical sight, then the creep
# will stay visible.

# NOTE: aura definition was removed because invisiblity
# mechanic was disabled

var magical_sight_debuff: BuffType

func _init(type: String, radius: float, parent: Node):
	super(type, 0, 0, true, parent)

	set_buff_icon("res://resources/icons/generic_icons/semi_closed_eye.tres")
	set_buff_tooltip("Magical Sight\nReveals invisible units in range.")
	
	magical_sight_debuff = BuffType.create_aura_effect_type("magical_sight_debuff", false, self)
	magical_sight_debuff.add_event_on_create(on_effect_create)
	magical_sight_debuff.add_event_on_cleanup(on_effect_cleanup)
	
	magical_sight_debuff.set_buff_tooltip("Seen\nDispells invisibility.")


func on_effect_create(event: Event):
	var target = event.get_target()
	target.add_invisible_watcher()


func on_effect_cleanup(event: Event):
	var target = event.get_target()
	target.remove_invisible_watcher()
