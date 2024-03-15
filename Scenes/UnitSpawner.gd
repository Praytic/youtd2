extends MultiplayerSpawner


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_despawned(node):
	print_verbose("Node [%s] was despawned." % node.name)


func _on_spawned(node):
	print_verbose("Node [%s] was spawned." % node.name)
