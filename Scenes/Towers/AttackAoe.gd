extends Node2D


var explosion_scene: PackedScene = preload("res://Scenes/Explosion.tscn")
onready var game_scene: Node = get_tree().get_root().get_node("GameScene")


func _ready():
	pass


func init(properties):
	$AttackTimer.wait_time = properties["attack_cd"]

	var attack_range = properties["attack_range"]
	Utils.circle_shape_set_radius($AttackArea/CollisionShape2D, attack_range)


func _on_AttackTimer_timeout():
	var body_list: Array = $AttackArea.get_overlapping_bodies()
	
	for body in body_list:
		if body is Mob:
			var mob: Mob = body as Mob
			mob.apply_damage(4)
			
			var explosion = explosion_scene.instance()
			explosion.position = mob.position
			game_scene.call_deferred("add_child", explosion)
