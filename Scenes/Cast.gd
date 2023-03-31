class_name Cast

# Cast is used to store information about spells. Used to
# create instances of SpellDummy.


class BlizzardData:
	var damage_base: float = 0.0
	var damage_add: float = 0.0
	var radius: float = 0.0
	var wave_count: int = 0


class SpellData:
	var blizzard: BlizzardData = BlizzardData.new()


var data: SpellData = SpellData.new()

var _order: String
var _lifetime: float
var _damage_event_handler: Callable


# NOTE: ability is unused because it's supposed to reference
# something configured in wc3 object editor.
func _init(_ability: String, order: String, lifetime: float):
	_order = order
	_lifetime = lifetime


func set_damage_event(callable: Callable):
	_damage_event_handler = callable


func point_cast_from_caster_on_point(caster: Unit, x: float, y: float, damage_ratio: float, crit_ratio: float):
	var spell_scene_path: String = _get_spell_scene_path()
	
	if spell_scene_path.is_empty():
		return

	var scene: PackedScene = load(spell_scene_path)
	var instance: DummyUnit = scene.instantiate()
	instance.init_spell(caster, _lifetime, data, _damage_event_handler, x, y, damage_ratio, crit_ratio)
	caster.add_child(instance)


func _get_spell_scene_path() -> String:
	match _order:
		"blizzard": return "res://Scenes/SpellBlizzard.tscn"
		_:
			print_debug("Invalid order name: ", _order)

	return ""
