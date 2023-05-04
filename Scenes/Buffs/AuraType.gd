class_name AuraType

# AuraType stores information about an aura. Should be used
# to create Aura instances. Create an AuraType and set it's
# properties, then pass AuraType to Tower.add_aura() or
# BuffType.add_aura().


var aura_range: float = 10.0
var target_type: TargetType = null
var target_self: bool = false
var level: int = 0
var level_add: int = 0
var power: int = 0
var power_add: int = 0
var aura_effect_is_friendly: bool = false
var aura_effect: BuffType = null

var _include_invisible: bool = false

var _aura_scene: PackedScene = preload("res://Scenes/Buffs/Aura.tscn")


func make(caster: Unit) -> Aura:
	var aura: Aura = _aura_scene.instantiate()
	aura._aura_range = aura_range
	aura._target_type = target_type
	aura._target_self = target_self
	aura._level = level
	aura._level_add = level_add
	aura._power = power
	aura._power_add = power_add
	aura._aura_effect_is_friendly = aura_effect_is_friendly
	aura._aura_effect = aura_effect
	aura._include_invisible = _include_invisible

	aura._caster = caster

	return aura
