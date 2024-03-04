extends Button


# This button has a RichTextLabel tooltip. Normal Button
# class supports only Label tooltips.


func _make_custom_tooltip(for_text: String) -> Object:
	var label: RichTextLabel = Utils.make_rich_text_tooltip(for_text)

	return label
