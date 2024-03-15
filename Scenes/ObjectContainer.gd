extends Node2D


@export var _tower_stash: TowerStash
@export var _map: Map


func _on_child_entered_tree(node: Node):
	if node is Tower:
		_on_tower_entered_tree(node)


func _on_tower_entered_tree(tower: Tower):
	var tower_id: int = tower.get_id()
	
	if Globals.get_game_mode() != GameMode.enm.BUILD:
		_tower_stash.remove_tower(tower_id)

	if Globals.get_game_state() == Globals.GameState.TUTORIAL:
		HighlightUI.highlight_target_ack.emit("tower_placed_on_map")

	_map.add_space_occupied_by_tower(tower)
