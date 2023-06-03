class_name Cast

# Cast is used to store information about spells. Used to
# create instances of SpellDummy.


class BlizzardData:
	var damage: float = 0.0
	var radius: float = 0.0
	var wave_count: int = 0


class ChaingLightningData:
	var damage: float = 0.0
	var damage_reduction: float = 0.0
	var chain_count: int = 0


class SpellData:
	var blizzard: BlizzardData = BlizzardData.new()
	var chain_lightning: ChaingLightningData = ChaingLightningData.new()


var data: SpellData = SpellData.new()

var _order: String
var _lifetime: float
var _damage_event_handler: Callable = Callable()


# NOTE: ability is unused because it's supposed to reference
# something configured in wc3 object editor.
func _init(_ability: String, order: String, lifetime: float):
	_order = order
	_lifetime = lifetime


func set_damage_event(handler: Callable):
	_damage_event_handler = handler


func point_cast_from_caster_on_point(caster: Unit, x: float, y: float, damage_ratio: float, crit_ratio: float):
	var spell_scene_path: String = _get_spell_scene_path()
	
	if spell_scene_path.is_empty():
		return

	var scene: PackedScene = load(spell_scene_path)
	var instance: DummyUnit = scene.instantiate()
	instance.init_spell(caster, _lifetime, data, _damage_event_handler, x, y, damage_ratio, crit_ratio)
	caster.add_child(instance)


func target_cast_from_caster(caster: Unit, target: Unit, damage_ratio: float, crit_ratio: float):
	point_cast_from_caster_on_point(caster, target.position.x, target.position.y, damage_ratio, crit_ratio)


# TODO: implement. Probably changes the height from which
# the cast visual originates.
func set_source_height(_height: float):
	pass


func _get_spell_scene_path() -> String:
	match _order:
		"blizzard": return "res://Scenes/Spells/SpellBlizzard.tscn"
		"chainlightning": return "res://Scenes/Spells/SpellChainLightning.tscn"

	push_error("Unhandled order: ", _order)

	return ""
