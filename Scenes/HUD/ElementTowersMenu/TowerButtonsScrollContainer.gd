extends ScrollContainer


func update_scroll_bar():
	var scroll_bar: VScrollBar = get_v_scroll_bar()
	var buttons_container: GridContainer = get_child(0)
	var sep = buttons_container.get_theme_constant("v_separation")
	var max_size = buttons_container.size.y
	var button_size = 0
	if buttons_container.get_child_count() > 0:
		button_size = buttons_container.get_child(0).size.y
	
	scroll_bar.min_value = 0
	scroll_bar.max_value = max_size
	scroll_bar.step = sep + button_size
	
