class_name TestTowersTool extends Node


# Tests towers by building and destroying all towers. This
# can detect basic script errors which would otherwise
# require opening each tower script in editor.


static func run(gamescene: Node):
	var scene_tree: SceneTree = gamescene.get_tree()
	var tower_id_list: Array = Properties.get_tower_id_list()

	var i: int = 0

	for tower_id in tower_id_list:
		var tower_name: String = TowerProperties.get_display_name(tower_id)
		print("(%d/%d) Testing tower %d %s" % [i + 1, tower_id_list.size(), tower_id, tower_name])

#		Test tower preview
		var tower_preview: TowerPreview = Globals.tower_preview_scene.instantiate()
		tower_preview.tower_id = tower_id
		gamescene.add_child(tower_preview)
		await scene_tree.create_timer(0.01).timeout
		tower_preview.queue_free()
		await scene_tree.create_timer(0.01).timeout

#		Test building tower
		var tower: Tower = TowerManager.get_tower(tower_id)
		tower.position = Vector2(123, 123)
		Utils.add_object_to_world(tower)
		await scene_tree.create_timer(0.01).timeout
		tower.queue_free()
		await scene_tree.create_timer(0.01).timeout

		i += 1
