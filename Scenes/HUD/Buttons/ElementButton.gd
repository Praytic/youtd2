extends Button


@export var element: Element.enm
@export var texture_progress_bar: TextureProgressBar
@export var progress_label: Label


var research_mode: bool


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	ElementLevel.changed.connect(_on_element_level_changed)
	
	_on_mouse_exited()
	_on_element_level_changed()


func _make_custom_tooltip(for_text: String) -> Object:
	var label = RichTextLabel.new()
	label.append_text(for_text)
	return label


func _on_element_level_changed():
	var curent_element_level = ElementLevel.get_current(element)
	texture_progress_bar.value = curent_element_level
	if curent_element_level == 0:
		progress_label.text = ""
	else:
		progress_label.text = str(curent_element_level)


func _on_mouse_entered():
	texture_progress_bar.show()
	progress_label.show()


func _on_mouse_exited():
	texture_progress_bar.hide()
	progress_label.hide()

