extends Button


@export var item: Item

# Appends provided tooltip text in addition
# to generated text by ItemDescription.
func _make_custom_tooltip(for_text):
	var tooltip_res = preload("res://Scenes/HUD/RichTextLabels/ItemDescription.tscn")
	tooltip_res.item = item
	var tooltip = tooltip_res.instantiate()
	tooltip.append_text(for_text)
	return tooltip
