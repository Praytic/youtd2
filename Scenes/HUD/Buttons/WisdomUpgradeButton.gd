class_name WisdomUpgradeButton extends Button


@export var _indicator: TextureRect


#########################
###       Public      ###
#########################

func set_indicator_visible(value: bool):
	_indicator.visible = value


#########################
###      Private      ###
#########################

func _make_custom_tooltip(for_text: String) -> Object:
	var label: RichTextLabel = Utils.make_rich_text_tooltip(for_text)

	return label


#########################
###       Static      ###
#########################

static func make() -> WisdomUpgradeButton:
	var scene: PackedScene = load("res://Scenes/HUD/Buttons/WisdomUpgradeButton.tscn")
	var button: WisdomUpgradeButton = scene.instantiate()
	
	return button
