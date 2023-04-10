extends Control


# Tooltip used to display tower/item details when their
# buttons are hovered by mouse. Note that this is different
# from native Control tooltip because this tooltip has rich
# text and is displayed at a certain position, not under
# mouse cursor.

# TODO: load actual tooltip texts

@onready var _label: RichTextLabel = $PanelContainer/RichTextLabel


func set_tower_id(tower_id: int):
	_label.clear()

	_label.append_text("tower: " + str(tower_id))


func set_item_id(item_id: int):
	_label.clear()

	_label.append_text("item: " + str(item_id))
