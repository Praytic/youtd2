extends Node2D

# ProximitySpell periodically applies aura's to targets in
# range. Whenever the cast timer times out, ProximitySpell
# passes aura info list to all targets that are in range.
# Note that depending on aura parameters, aura's may be
# passed to Mobs or Towers.

signal killing_blow()


var spell_scene: PackedScene = preload("res://Scenes/Spell/Spell.tscn")
var explosion_scene: PackedScene = preload("res://Scenes/Explosion.tscn")
onready var game_scene: Node = get_tree().get_root().get_node("GameScene")

var spell: Spell


func _ready():
	pass


func init(spell_info: Dictionary):
	spell = spell_scene.instance()
	add_child(spell)
	spell.init(spell_info)

	var cast_timer: Timer = spell.get_cast_timer()
	cast_timer.connect("timeout", self, "_on_CastTimer_timeout")
# 	NOTE: cast timer starts in running state and loops
	cast_timer.one_shot = false
	cast_timer.start()


func _on_CastTimer_timeout():
	var cast_area: Area2D = spell.get_cast_area()
	var body_list: Array = cast_area.get_overlapping_bodies()

	var aura_info_list: Array = spell.get_modded_aura_info()

	for body in body_list:
		var body_is_valid_target = is_valid_target(body)

		if body_is_valid_target:
			body.add_aura_info_list(aura_info_list, self)

			if body is Mob:
				var explosion = explosion_scene.instance()
				explosion.position = body.position
				game_scene.call_deferred("add_child", explosion)


func is_valid_target(node: Node) -> bool:
	var target_type = spell.get_spell_parameter(Properties.SpellParameter.TARGET_TYPE)
	
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
	spell.apply_aura(aura)


func on_killing_blow():
	emit_signal("killing_blow")
	pass


func change_level(new_level: int):
	spell.change_level(new_level)