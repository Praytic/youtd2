extends Node2D


var explosion_scene: PackedScene = preload("res://Scenes/Explosion.tscn")
onready var game_scene: Node = get_tree().get_root().get_node("GameScene")

var aura_list: Array


func _ready():
	pass


func init(spell_info: Dictionary):
	$CastTimer.wait_time = spell_info["cast_cd"]

	var cast_range = spell_info["cast_range"]
	Utils.circle_shape_set_radius($CastArea/CollisionShape2D, cast_range)

	aura_list = spell_info["aura_list"]


func _on_CastTimer_timeout():
	var body_list: Array = $CastArea.get_overlapping_bodies()
	
	for body in body_list:
		if body is Mob:
			var mob: Mob = body as Mob
			mob.add_aura_list(aura_list)
			
			var explosion = explosion_scene.instance()
			explosion.position = mob.position
			game_scene.call_deferred("add_child", explosion)
