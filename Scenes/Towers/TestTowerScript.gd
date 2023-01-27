extends Node


var parameters: Dictionary = {
	Properties.ScriptParameter.ON_DAMAGE_CHANCE: 1.0,
	Properties.ScriptParameter.ON_DAMAGE_CHANCE_LEVEL_ADD: 0.0,
	Properties.ScriptParameter.ON_ATTACK_CHANCE: 1.0,
	Properties.ScriptParameter.ON_ATTACK_CHANCE_LEVEL_ADD: 0.0,
}

func _ready():
	pass


func on_attack(tower: Tower):
	print("on_attack!")


func on_damage(tower: Tower):
	print("on_damage!")
