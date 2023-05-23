class_name MagicalSightBuff
extends BuffType

# Magical sight effect, makes creeps in radius visible. Creeps
# become invisible again once they leave range. Note that if
# creep leaves range of a unit with magical sight but stays in
# range of another unit with magical sight, then the creep
# will stay visible.

var magical_sight_debuff: BuffType

func _init(type: String, radius: float, parent: Node):
	super(type, 0, 0, true, parent)

	set_buff_tooltip("Magical Sight\nThis unit reveals invisible units in range")
	
	magical_sight_debuff = BuffType.create_aura_effect_type("magical_sight_debuff", false, self)
	magical_sight_debuff.add_event_on_create(on_effect_create)
	magical_sight_debuff.set_event_on_cleanup(on_effect_cleanup)
	
	magical_sight_debuff.set_buff_tooltip("Seen\nThis unit is within range of a tower that sees invisible units, it's invisibility has been dispelled.")

	var aura_type: AuraType = AuraType.new()
	aura_type.aura_range = radius
	aura_type.target_type = TargetType.new(TargetType.CREEPS)
	aura_type.target_self = false
	aura_type.level = 0
	aura_type.level_add = 0
	aura_type.power = 0
	aura_type.power_add = 0
	aura_type.aura_effect_is_friendly = false
	aura_type.aura_effect = magical_sight_debuff

#	NOTE: normally, aura's do not affect invisible units, so
#	to be able to make invisible units visible using an
#	aura, we need to force the aura to affect invisible
#	units.
	aura_type._include_invisible = true

	add_aura(aura_type)


func on_effect_create(event: Event):
	var target = event.get_target()
	target.add_invisible_watcher()


func on_effect_cleanup(event: Event):
	var target = event.get_target()
	target.remove_invisible_watcher()
