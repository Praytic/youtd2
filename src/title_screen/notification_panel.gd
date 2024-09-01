class_name NotificationPanel extends PanelContainer


# Used for displaying notifications in title screen.
# Fades out after a delay.

const VISIBLE_DURATION: float = 10.0
const FADEOUT_DURATION: float = 1.0

@export var _label: RichTextLabel
@export var _fadeout_timer: Timer


func display_text(text: String):
	_label.clear()
	_label.append_text(text)
	
	modulate = Color.WHITE
	_fadeout_timer.start(VISIBLE_DURATION)
	
	print(modulate)
	print(visible)


func _on_fadeout_timer_timeout():
	var modulate_tween = create_tween()
	modulate_tween.tween_property(self, "modulate",
		Color(modulate.r, modulate.g, modulate.b, 0),
		FADEOUT_DURATION).set_trans(Tween.TRANS_LINEAR)
