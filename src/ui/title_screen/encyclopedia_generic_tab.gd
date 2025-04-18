class_name EncyclopediaGenericTab extends VBoxContainer



signal search_text_changed(new_text: String)
signal close_pressed()


@export var _info_label: RichTextLabel
@export var _button_grid: GridContainer
@export var _selected_tower_button: TowerButton
@export var _selected_name_label: Label


#########################
###     Built-in      ###
#########################

func _ready() -> void:
	_selected_tower_button.hide()
	_selected_tower_button.set_tooltip_is_enabled(false)
	_selected_tower_button.set_tier_visible(true)
	
	_info_label.clear()
	_selected_name_label.text = ""


#########################
###       Public      ###
#########################

func add_button_to_grid(button: Button):
	_button_grid.add_child(button)


func set_selected_tower_id(tower_id: int):
	_selected_tower_button.set_tower_id(tower_id)
	_selected_tower_button.show()
	

func set_selected_name(selected_name: String):
	_selected_name_label.text = selected_name


func set_info_text(text: String):
	_info_label.clear()
	_info_label.append_text(text)


#########################
###     Callbacks     ###
#########################

func _on_close_button_pressed() -> void:
	close_pressed.emit()


func _on_search_box_text_changed(new_text: String) -> void:
	search_text_changed.emit(new_text)
