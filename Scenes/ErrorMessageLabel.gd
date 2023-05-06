class_name ErrorMessageLabel extends Label


# Displays an error message in the middle of the screen. Use
# by calling Messages.add_error


const DELAY_BEFORE_FADE_START: float = 1.0
const FADE_DURATION: float = 1.0

var _error_message_list: Array = []
var _prev_tween: Tween = null


func _ready():
	set_text("")


func add(new_message: String):
	set_visible(true)

	if _error_message_list.size() >= 3:
		_error_message_list.pop_back()

	_error_message_list.push_front(new_message)

	var all_messages_text: String = ""

	for message in _error_message_list:
		all_messages_text += message + "\n" 
	
	set_text(all_messages_text)

	if _prev_tween != null:
		_prev_tween.stop()

	set_modulate(Color.WHITE)
	var modulate_tween = create_tween()
	modulate_tween.tween_property(self, "modulate",
		Color(modulate.r, modulate.g, modulate.b, 0),
		FADE_DURATION).set_trans(Tween.TRANS_LINEAR).set_delay(DELAY_BEFORE_FADE_START)
	modulate_tween.finished.connect(_on_modulate_tween_finished)

	_prev_tween = modulate_tween


# Clear text when text is done fading
func _on_modulate_tween_finished():
	_error_message_list.clear()
