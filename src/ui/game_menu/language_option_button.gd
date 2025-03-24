extends OptionButton


# Called when the language option button init to set default selection
func _ready() -> void:
	var locale = OS.get_locale_language()
	var index = Language.get_option_from_locale(locale)
	selected = index

func _on_item_selected(index: int) -> void:
	TranslationServer.set_locale(Language.get_locale_from_option(index))
