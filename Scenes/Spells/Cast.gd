class_name Cast extends Node

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


class SwarmData:
	var damage: float = 0.0
	var start_radius: float = 0.0
	var end_radius: float = 0


class SpellData:
	var blizzard: BlizzardData = BlizzardData.new()
	var chain_lightning: ChaingLightningData = ChaingLightningData.new()
	var swarm: SwarmData = SwarmData.new()


var data: SpellData = SpellData.new()

var _order: String
var _lifetime: float
var _damage_event_handler: Callable = Callable()


# NOTE: ability is unused because it's supposed to reference
# something configured in wc3 object editor.
func _init(_ability: String, order: String, lifetime: float, parent: Node):
	parent.add_child(self)
	_order = order
	_lifetime = lifetime


# NOTE: cast.setDamageEvent() in JASS
func set_damage_event(handler: Callable):
	_damage_event_handler = handler


# NOTE: cast.pointCastFromCasterOnPoint() in JASS
func point_cast_from_unit_on_point(caster: Unit, origin: Unit, x: float, y: float, damage_ratio: float, crit_ratio: float):
	var spell_scene_path: String = _get_spell_scene_path()
	
	if spell_scene_path.is_empty():
		return

	var scene: PackedScene = load(spell_scene_path)
	var instance: SpellDummy = scene.instantiate()
	instance.position = origin.position
	instance.init_spell(caster, _lifetime, data, _damage_event_handler, x, y, damage_ratio, crit_ratio)
	tree_exited.connect(instance._on_cast_type_tree_exited)
	Utils.add_object_to_world(instance)


func point_cast_from_caster_on_point(caster: Unit, x: float, y: float, damage_ratio: float, crit_ratio: float):
	point_cast_from_unit_on_point(caster, caster, x, y, damage_ratio, crit_ratio)


# NOTE: cast.targetCastFromCasterOnPoint() in JASS
func target_cast_from_caster(caster: Unit, target: Unit, damage_ratio: float, crit_ratio: float):
	point_cast_from_caster_on_point(caster, target.position.x, target.position.y, damage_ratio, crit_ratio)


# TODO: what is the difference between point_cast_from_target_on_target() and target_cast_from_caster()?
# NOTE: cast.pointCastFromCasterOnTarget() in JASS
func point_cast_from_target_on_target(caster: Unit, target: Unit, damage_ratio: float, crit_ratio: float):
	target_cast_from_caster(caster, target, damage_ratio, crit_ratio)


# TODO: implement. Probably changes the height from which
# the cast visual originates.
# NOTE: cast.setSourceHeight() in JASS
func set_source_height(_height: float):
	pass


func _get_spell_scene_path() -> String:
	match _order:
		"blizzard": return "res://Scenes/Spells/SpellBlizzard.tscn"
		"chainlightning": return "res://Scenes/Spells/SpellChainLightning.tscn"
		"carrionswarm": return "res://Scenes/Spells/SpellSwarm.tscn"

	push_error("Unhandled order: ", _order)

	return ""
