extends Node2D

# ProximitySpell periodically applies aura's to targets in
# range. Whenever the cast timer times out, ProximitySpell
# passes aura info list to all targets that are in range.
# Note that depending on aura parameters, aura's may be
# passed to Mobs or Towers.


var explosion_scene: PackedScene = preload("res://Scenes/Explosion.tscn")
onready var game_scene: Node = get_tree().get_root().get_node("GameScene")

var target_type: int
var default_cast_cd: float
var cast_cd_mod: float = 0.0
var aura_info_container: AuraInfoContainer

func _ready():
	pass


func init(spell_info: Dictionary):
	default_cast_cd = spell_info[Properties.SpellParameter.CAST_CD]
	$CastTimer.wait_time = default_cast_cd

	var cast_range = spell_info[Properties.SpellParameter.CAST_RANGE]
	Utils.circle_shape_set_radius($CastArea/CollisionShape2D, cast_range)

	target_type = spell_info[Properties.SpellParameter.TARGET_TYPE]

	var aura_info_list: Array = spell_info[Properties.SpellParameter.AURA_INFO_LIST]
	aura_info_container = AuraInfoContainer.new(aura_info_list)


func _on_CastTimer_timeout():
	var body_list: Array = $CastArea.get_overlapping_bodies()

	var aura_info_list: Array = aura_info_container.get_modded()

	for body in body_list:
		var body_is_valid_target = is_valid_target(body)

		if body_is_valid_target:
			body.add_aura_info_list(aura_info_list)

			if body is Mob:
				var explosion = explosion_scene.instance()
				explosion.position = body.position
				game_scene.call_deferred("add_child", explosion)


func is_valid_target(node: Node) -> bool:
	match target_type:
		Properties.SpellTargetType.MOBS:
			return node is Mob
		Properties.SpellTargetType.ALL_TOWERS:
			return node is Tower
		Properties.SpellTargetType.OTHER_TOWERS:
			var this_tower = get_parent()

			return node is Tower && node != this_tower
		Properties.SpellTargetType.TOWER_SELF:
			var this_tower = get_parent()

			return node is Tower && node == this_tower

	return false


func apply_aura(aura: Aura):
	match aura.type:
		Properties.AuraType.DECREASE_CAST_CD:
			if aura.is_expired:
				cast_cd_mod = 0.0
			else:
				cast_cd_mod = aura.get_value()

			$CastTimer.wait_time = default_cast_cd * (1.0 + cast_cd_mod)

	aura_info_container.apply_aura(aura)
