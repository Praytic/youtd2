extends MultiplayerSynchronizer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func _on_delta_synchronized():
	print_verbose("New delta synchronization state recieved.")


func _on_synchronized():
	print_verbose("New synchronization state recieved.")
