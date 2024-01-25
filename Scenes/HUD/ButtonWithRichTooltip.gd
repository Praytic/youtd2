extends Button


# This button has a RichTextLabel tooltip. Normal Button
# class supports only Label tooltips.


# TODO: currently, we assure that text fits inside the
# richtextlabel tooltip by setting the minimum size. If all
# lines in the text are shorter than the minimum size, there
# will be extra empty space to the right of the text. It
# looks bad. Would like the tooltip width to automatically
# shrink in such cases so that tooltip size fits text size
# without any empty space. Couldn't figure out how to do
# that. There also seems to be a bug with RichTextLabel,
# fit_content and embedding a RichTextLabel in tooltip which
# stands in the way of implementing such behavior.
func _make_custom_tooltip(for_text: String) -> Object:
	var label: RichTextLabel = RichTextLabel.new()
	label.custom_minimum_size = Vector2(500, 50)
	label.fit_content  = true
	label.append_text(for_text)

	return label
