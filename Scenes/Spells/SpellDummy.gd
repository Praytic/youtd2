class_name SpellDummy extends DummyUnit


# Instance of a spell. Should be created using SpellType.


# NOTE: target may be null if spell was cast on point
var _target: Unit = null
var _target_position: Vector2 = Vector2.ZERO
var _lifetime: float = 0.0


@export var _debug_sprite: Sprite2D
@export var _debug_sprite_target: Sprite2D
@export var _lifetime_timer: Timer


func _ready():
	super()
	
	_debug_sprite.visible = Config.visible_spell_dummys_enabled()
	_debug_sprite_target.visible = Config.visible_spell_dummys_enabled()
	_debug_sprite_target.position = _target_position - position

	_lifetime_timer.start(_lifetime)


func init_spell(caster: Unit, target: Unit, lifetime: float, data: SpellType.SpellData, damage_event_handler: Callable, x: float, y: float, damage_ratio: float, crit_ratio: float):
	_caster = caster
	_lifetime = lifetime
	_set_subclass_data(data)

	set_damage_event(damage_event_handler)

	_target = target
	_target_position = Vector2(x, y)
	_damage_ratio = damage_ratio
	_crit_ratio = crit_ratio


# NOTE: subclasses override this to save data that is useful
# for them
func _set_subclass_data(_data: SpellType.SpellData):
	pass


func _on_lifetime_timer_timeout():
	_cleanup()


func _on_cast_type_tree_exited():
	_cleanup()
