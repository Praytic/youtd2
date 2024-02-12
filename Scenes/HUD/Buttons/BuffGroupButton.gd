extends Button


enum Mode {
	OUTGOING,
	INCOMING,
	BOTH,
	NONE,
}

const _modes_list = [Mode.NONE, Mode.OUTGOING, Mode.INCOMING, Mode.BOTH]

var _current_mode_id: int = 0
@export var _buff_group_number: int


func _on_pressed():
	_current_mode_id = (_current_mode_id + 1) % _modes_list.size()
	text = "%s (%s)" % [_buff_group_number, get_current_mode()]


func get_current_mode() -> Mode:
	return _modes_list[_current_mode_id]

