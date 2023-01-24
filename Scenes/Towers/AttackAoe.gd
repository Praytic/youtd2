extends Node2D


var explosion_scene: PackedScene = preload("res://Scenes/Explosion.tscn")
onready var game_scene: Node = get_tree().get_root().get_node("GameScene")

var aura_list: Array = []


func _ready():
	pass


func init(properties):
	$AttackTimer.wait_time = properties["attack_cd"]

	var attack_range = properties["attack_range"]
	Utils.circle_shape_set_radius($AttackArea/CollisionShape2D, attack_range)

	aura_list = properties["aura_list"]


func _on_AttackTimer_timeout():
	for aura_info in aura_list:
		var aura_add_range: float = aura_info["add_range"]
		var mob_list: Array = Utils.get_mob_list_in_range(global_position, aura_add_range)

		for mob in mob_list:
			mob.add_aura_list(aura_list)
			
			var explosion = explosion_scene.instance()
			explosion.position = mob.position
			game_scene.call_deferred("add_child", explosion)
