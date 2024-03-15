@tool
extends MultiplayerSpawner


# Called when the node enters the scene tree for the first time.
func _ready():
	clear_spawnable_scenes()
	var dir = DirAccess.open(TowerManager.towers_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() && file_name.ends_with(".tscn"):
				var file_path = "%s/%s" % [TowerManager.towers_dir, file_name]
				add_spawnable_scene(file_path)
			file_name = dir.get_next()


func _on_despawned(node):
	print_verbose("Node [%s] was despawned." % node.name)


func _on_spawned(node):
	print_verbose("Node [%s] was spawned." % node.name)
