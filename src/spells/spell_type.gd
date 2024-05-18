class_name SpellType extends Node

# SpellType is used to store information about spells. Used to
# create instances of SpellDummy.

# NOTE: this class is called "Cast" in JASS


class BlizzardData:
	var damage: float = 0.0
	var radius: float = 0.0
	var wave_count: int = 0


class ChaingLightningData:
	var damage: float = 0.0
	var damage_reduction: float = 0.0
	var chain_count: int = 0


class ForkedLightningData:
	var damage: float = 0.0
	var target_count: int = 0


class SwarmData:
	var damage: float = 0.0
	var start_radius: float = 0.0
	var end_radius: float = 0


class SpellData:
	var blizzard: BlizzardData = BlizzardData.new()
	var chain_lightning: ChaingLightningData = ChaingLightningData.new()
	var forked_lightning: ForkedLightningData = ForkedLightningData.new()
	var swarm: SwarmData = SwarmData.new()


var data: SpellData = SpellData.new()

var _order: String
var _lifetime: float
var _source_height: float = 0.0
var _damage_event_handler: Callable = Callable()


#########################
###     Built-in      ###
#########################

# NOTE: ability is unused because it's supposed to reference
# something configured in wc3 object editor.
func _init(_ability: String, order: String, lifetime: float, parent: Node):
	parent.add_child(self)
	_order = order
	_lifetime = lifetime


#########################
###       Public      ###
#########################

# NOTE: cast.setDamageEvent() in JASS
func set_damage_event(handler: Callable):
	_damage_event_handler = handler


func point_cast_from_unit_on_point(caster: Unit, origin_unit: Unit, target_pos: Vector2, damage_ratio: float, crit_ratio: float):
	var target: Unit = null
	var origin_pos: Vector3 = origin_unit.get_position_wc3()
	_cast_generic(caster, origin_pos, target, target_pos, damage_ratio, crit_ratio)


func point_cast_from_caster_on_point(caster: Unit, target_pos: Vector2, damage_ratio: float, crit_ratio: float):
	var origin_pos: Vector3 = caster.get_position_wc3()
	var target: Unit = null
	_cast_generic(caster, origin_pos, target, target_pos, damage_ratio, crit_ratio)


# NOTE: cast.targetCastFromCaster() in JASS
func target_cast_from_caster(caster: Unit, target: Unit, damage_ratio: float, crit_ratio: float):
	var origin_pos: Vector3 = caster.get_position_wc3()
	var target_pos: Vector2 = target.get_position_wc3_2d()
	_cast_generic(caster, origin_pos, target, target_pos, damage_ratio, crit_ratio)


# NOTE: cast.targetCastFromPoint() in JASS
func target_cast_from_point(caster: Unit, target: Unit, origin_pos_2d: Vector2, damage_ratio: float, crit_ratio: float):
	var origin_pos: Vector3 = Vector3(origin_pos_2d.x, origin_pos_2d.y, 0)
	var target_pos: Vector2 = target.get_position_wc3_2d()
	_cast_generic(caster, origin_pos, target, target_pos, damage_ratio, crit_ratio)


# NOTE: point_cast_from_target_on_target() and
# target_cast_from_caster() are basically the same in
# current implementation. In original game, there's more
# nuance but for practical purposes there's no point in
# implementing this nuance.
# NOTE: cast.pointCastFromCasterOnTarget() in JASS
func point_cast_from_target_on_target(caster: Unit, target: Unit, damage_ratio: float, crit_ratio: float):
	var origin_pos: Vector3 = target.get_position_wc3()
	var target_pos: Vector2 = target.get_position_wc3_2d()
	_cast_generic(caster, origin_pos, target, target_pos, damage_ratio, crit_ratio)


# NOTE: cast.setSourceHeight() in JASS
func set_source_height(value: float):
	_source_height = value


#########################
###      Private      ###
#########################

func _cast_generic(caster: Unit, origin_pos: Vector3, target: Unit, target_pos: Vector2, damage_ratio: float, crit_ratio: float):
	var spell_scene_path: String = _get_spell_scene_path()
	
	if spell_scene_path.is_empty():
		return

	var scene: PackedScene = load(spell_scene_path)
	var instance: SpellDummy = scene.instantiate()
	origin_pos.z += _source_height
	instance.set_position_wc3(origin_pos)
	instance.init_spell(caster, target, _lifetime, data, _damage_event_handler, target_pos, damage_ratio, crit_ratio)
	tree_exited.connect(instance._on_cast_type_tree_exited)
	Utils.add_object_to_world(instance)


func _get_spell_scene_path() -> String:
	match _order:
		"blizzard": return "res://src/spells/spell_blizzard.tscn"
		"chainlightning": return "res://src/spells/spell_chain_lightning.tscn"
		"forkedlightning": return "res://src/spells/spell_forked_lightning.tscn"
		"carrionswarm": return "res://src/spells/spell_swarm.tscn"

	push_error("Unhandled order: ", _order)

	return ""
