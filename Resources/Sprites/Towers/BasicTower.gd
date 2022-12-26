extends Node2D


func _init(var tier: int = 1):
	pass


func _ready():
	for node in get_children():
		node.hide()


func update_tier(tier: int):
	for t in range(tier):
		var allowed_node: Node2D = get_node("Tier%s" % [t + 1])
		allowed_node.show()
