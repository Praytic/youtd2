extends ScrollContainer


func _ready():
	var scroll_bar =  get_v_scroll_bar()
	scroll_bar.min_value = 0
	scroll_bar.max_value = get_child(0).size.y
# Each tower button has size of 96px and 4px margin
	scroll_bar.step = 100

