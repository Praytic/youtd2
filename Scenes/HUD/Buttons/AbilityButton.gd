class_name AbilityButton extends UnitButton


# Button for tower abilities. Note that this is for not-active abilities. Active abilities use AutocastButton.


const FALLBACK_ICON: String = "res://Resources/Icons/AbilityIcons/compass.tres"


var _icon_path: String = ""
var _tooltip_text: String = ""


#########################
###     Built-in      ###
#########################

func _ready():
	var icon_path_is_valid: bool = ResourceLoader.exists(_icon_path)
	if !icon_path_is_valid:
		push_error("Invalid icon path for ability: %s" % _icon_path)

		_icon_path = FALLBACK_ICON

	var ability_icon: Texture2D = load(_icon_path)
	set_button_icon(ability_icon)

	mouse_entered.connect(_on_mouse_entered)


static func make(ability_info: AbilityInfo) -> AbilityButton:
	var button: AbilityButton = Preloads.ability_button_scene.instantiate()
	button._icon_path = ability_info.icon
	
	var description: String = ability_info.description_full
	var description_colored: String = RichTexts.add_color_to_numbers(description)
	button._tooltip_text = "[color=GOLD]%s[/color]\n \n%s" % [ability_info.name, description_colored]
	
	return button


#########################
###     Callbacks     ###
#########################

func _on_mouse_entered():
	ButtonTooltip.show_tooltip(self, _tooltip_text)
