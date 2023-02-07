class_name Event
extends Node


var damage: float
# target is of type Unit, can't use typing because of cyclic dependency...
var target
var can_attack: bool = true


func _ready():
	pass
