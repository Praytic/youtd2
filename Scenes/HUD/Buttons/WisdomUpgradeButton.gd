class_name WisdomUpgradeButton extends Button


@export var _indicator: TextureRect


#########################
###       Public      ###
#########################

func set_upgrade_used_status(value: bool):
	if value:
		modulate = Color.WHITE
	else:
		modulate = Color(0.3, 0.3, 0.3, 1.0)


#########################
###      Private      ###
#########################

func _make_custom_tooltip(for_text: String) -> Object:
	var label: RichTextLabel = Utils.make_rich_text_tooltip(for_text)

	return label


#########################
###       Static      ###
#########################

static func make(upgrade_id: int ) -> WisdomUpgradeButton:
	var scene: PackedScene = load("res://Scenes/HUD/Buttons/WisdomUpgradeButton.tscn")
	var button: WisdomUpgradeButton = scene.instantiate()
	
	var tooltip: String = WisdomUpgradeProperties.get_tooltip(upgrade_id)
	button.set_tooltip_text(tooltip)

	var icon_path: String = WisdomUpgradeProperties.get_icon_path(upgrade_id)
	var icon_exists: bool = ResourceLoader.exists(icon_path)
	if icon_exists:
		button.icon = load(icon_path)

	return button
