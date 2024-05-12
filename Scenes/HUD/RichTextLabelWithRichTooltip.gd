class_name RichTextLabelWithRichTooltip extends RichTextLabel


func _make_custom_tooltip(for_text: String) -> Object:
	var label: RichTextLabel = Utils.make_rich_text_tooltip(for_text)

	return label
