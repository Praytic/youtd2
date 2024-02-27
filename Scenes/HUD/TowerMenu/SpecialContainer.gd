class_name SpecialContainer
extends VBoxContainer


@export var special_name_label: Label
@export var title_container: Container
@export var special_description: RichTextLabel 

static func make(special_name: String, special_icon: TextureRect, special_description: String) -> SpecialContainer:
	var special_container: SpecialContainer = Globals.special_container.instantiate()
	special_container.special_name_label.text = special_name
	special_container.special_description.text = special_description
	special_icon.custom_minimum_size = Vector2(48, 48)
	special_container.title_container.add_child(special_icon)
	special_container.title_container.move_child(special_icon, 0)

	
	return special_container
