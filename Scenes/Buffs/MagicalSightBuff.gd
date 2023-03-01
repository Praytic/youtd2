class_name MagicalSightBuff
extends Buff

# Magical sight effect, makes mobs in radius visible. Mobs
# become invisible again once they leave range. Note that if
# mob leaves range of a unit with magical sight but stays in
# range of another unit with magical sight, then the mob
# will stay visible.


var magical_sight_aura_scene = preload("res://Scenes/Buffs/Aura.tscn")

var _radius: float = 0.0

func _init(radius: float).("magical_sight", 0, 0, true):
	_radius = radius


func _ready():
	var magical_sight_aura = magical_sight_aura_scene.instance()
	magical_sight_aura.aura_range = _radius
	magical_sight_aura.target_type = TargetType.new(TargetType.UnitType.MOBS)
	magical_sight_aura.target_self = false
	magical_sight_aura.level = 0
	magical_sight_aura.level_add = 0
	magical_sight_aura.power = 0
	magical_sight_aura.power_add = 0
	magical_sight_aura.aura_effect_is_friendly = false
	magical_sight_aura.create_aura_effect_function = "create_magical_sight_effect"
	magical_sight_aura.caster = get_caster()
	magical_sight_aura.create_aura_effect_object = self

	add_child(magical_sight_aura)


func create_magical_sight_effect() -> Buff:
	var buff = Buff.new("", 0, 0, false)
	buff.add_event_on_create(self, "on_effect_create")
	buff.set_event_on_cleanup(self, "on_effect_cleanup")
	
	return buff

func on_effect_create(event: Event):
	var target = event.get_target()
	target.add_invisible_watcher()


func on_effect_cleanup(event: Event):
	var target = event.get_target()
	target.remove_invisible_watcher()
