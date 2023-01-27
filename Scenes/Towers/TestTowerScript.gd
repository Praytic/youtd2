extends Node


var parameters: Dictionary = {
	Properties.ResourceParameter.ON_DAMAGE_CHANCE: 1.0,
	Properties.ResourceParameter.ON_DAMAGE_CHANCE_LEVEL_ADD: 0.0,
}

func _ready():
	pass


func on_damage(tower: Tower):
	print("on_damage!")
