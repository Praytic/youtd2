extends ScrollContainer


func _ready():
	var scroll_bar: VScrollBar = get_v_scroll_bar()
	scroll_bar.step = 130
	
