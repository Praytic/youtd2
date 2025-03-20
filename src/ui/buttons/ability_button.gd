class_name AbilityButton extends Button


# Button for tower abilities. Note that this is for not-active abilities. Active abilities use AutocastButton.


const FALLBACK_ICON: String = "res://resources/icons/mechanical/compass.tres"


var _icon_path: String = ""
var _tooltip_text: String = ""
var _ability_name_english: String = ""


#########################
###     Built-in      ###
#########################

func _ready():
	var icon_path_is_valid: bool = ResourceLoader.exists(_icon_path)
	if !icon_path_is_valid:
		if !_icon_path.is_empty():
			push_error("Invalid icon path for ability: %s" % _icon_path)

		_icon_path = FALLBACK_ICON

	var ability_icon: Texture2D = load(_icon_path)
	set_button_icon(ability_icon)

	mouse_entered.connect(_on_mouse_entered)


#########################
###       Public      ###
#########################

func get_ability_name_english() -> String:
	return _ability_name_english


#########################
###       Static      ###
#########################

static func make(ability_info: AbilityInfo) -> AbilityButton:
	var button: AbilityButton = Preloads.ability_button_scene.instantiate()
	button._icon_path = ability_info.icon
	
	var description: String = ability_info.description_long
	var description_colored: String = RichTexts.add_color_to_numbers(description)
	button._tooltip_text = "[color=GOLD]%s[/color]\n \n%s" % [ability_info.name, description_colored]

	button._ability_name_english = ability_info.name_english

	return button


static func make_from_aura_id(aura_id: int) -> AbilityButton:
	var button: AbilityButton = Preloads.ability_button_scene.instantiate()
	button._icon_path = AuraProperties.get_icon_path(aura_id)

	var aura_name: String = AuraProperties.get_aura_name(aura_id)
	var description: String = AuraProperties.get_description_long(aura_id)
	var description_colored: String = RichTexts.add_color_to_numbers(description)
	button._tooltip_text = "[color=GOLD]%s - Aura[/color]\n \n%s" % [aura_name, description_colored]
	
	button._ability_name_english = AuraProperties.get_name_english(aura_id)

	return button


#########################
###     Callbacks     ###
#########################

func _on_mouse_entered():
	ButtonTooltip.show_tooltip(self, _tooltip_text, ButtonTooltip.Location.BOTTOM)
