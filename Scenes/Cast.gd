class_name Cast

# Cast is used to store information about spells. Used to
# create instances of SpellDummy.


var _icon: String
var _spell: String
var _lifetime: float
var _damage_event_handler: Callable


func _init(icon: String, spell: String, lifetime: float):
	_icon = icon
	_spell = spell
	_lifetime = lifetime


func set_damage_event(callable: Callable):
	_damage_event_handler = callable


# TODO: create SpellDummy, pass data to SpellDummy.
func point_cast_from_caster_on_point(_caster: Unit, _x: float, _y: float, _damage_ratio: float, _crit_ratio: float):
	pass
