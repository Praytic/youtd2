class_name TextureRectWithRichTooltip extends TextureRect


# This TextureRect has a RichTextLabel tooltip. Normal
# TextureRect class supports only Label tooltips.


func _make_custom_tooltip(for_text: String) -> Object:
	var label: RichTextLabel = Utils.make_rich_text_tooltip(for_text)

	return label
