class_name RoomMenu extends VBoxContainer


@export var _player_list: ItemList


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var peer_id_list: Array = multiplayer.get_peers()
	var local_peer_id: int = multiplayer.get_unique_id()
	peer_id_list.append(local_peer_id)
	
	_player_list.clear()
	
	for peer_id in peer_id_list:
		var peer_string: String = "Player %d" % peer_id
		_player_list.add_item(peer_string)
	
	for i in _player_list.item_count:
		_player_list.set_item_selectable(i, false)
