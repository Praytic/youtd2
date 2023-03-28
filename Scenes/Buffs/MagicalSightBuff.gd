class_name MagicalSightBuff
extends BuffType

# Magical sight effect, makes creeps in radius visible. Creeps
# become invisible again once they leave range. Note that if
# creep leaves range of a unit with magical sight but stays in
# range of another unit with magical sight, then the creep
# will stay visible.


func _init(radius: float):
	super("magical_sight", 0, 0, true)

	var magical_sight_debuff: BuffType = BuffType.create_aura_effect_type("magical_sight_debuff", false)
	magical_sight_debuff.add_event_on_create(self, "on_effect_create")
	magical_sight_debuff.set_event_on_cleanup(self, "on_effect_cleanup")
	
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

	add_aura(aura_type)


func on_effect_create(event: Event):
	var target = event.get_target()
	target.add_invisible_watcher()


func on_effect_cleanup(event: Event):
	var target = event.get_target()
	target.remove_invisible_watcher()
