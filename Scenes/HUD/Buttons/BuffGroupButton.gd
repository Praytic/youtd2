extends Button


enum Mode {
	OUTGOING,
	INCOMING,
	BOTH,
	NONE,
}

const _modes_list = [Mode.NONE, Mode.OUTGOING, Mode.INCOMING, Mode.BOTH]

var _current_mode_id: int = 0


func _on_pressed():
	_current_mode_id = (_current_mode_id + 1) % _modes_list.size()


func get_current_mode():
	return _modes_list[_current_mode_id]

