extends Node


var parameters: Dictionary = {
	Properties.ScriptParameter.ON_DAMAGE_CHANCE: 1.0,
	Properties.ScriptParameter.ON_DAMAGE_CHANCE_LEVEL_ADD: 0.0,
	Properties.ScriptParameter.ON_ATTACK_CHANCE: 1.0,
	Properties.ScriptParameter.ON_ATTACK_CHANCE_LEVEL_ADD: 0.0,
}

var test_buff: Buff


func _init():
	test_buff = Buff.new(5.0)


func _ready():
	pass


func on_attack(tower: Tower, event: Event):
	print("on_attack!")

	var target: Mob = event.target
	test_buff.apply(tower, target, 1.0)


func on_damage(tower: Tower, event: Event):
	print("on_damage!")
