class_name BuilderMenu extends PanelContainer


# NOTE: the buttons for this menu are created
# programmatically inside _ready().


signal finished()


@export var _beginner_container: GridContainer
@export var _advanced_container: GridContainer
@export var _specialist_container: GridContainer
@export var _hardcore_container: GridContainer


var _builder_id: int


func _ready():
	var builder_list: Array = BuilderProperties.get_id_list()
	
	for builder in builder_list:
		var short_name: String = BuilderProperties.get_short_name(builder)

		if short_name == "none":
			continue

		var display_name: String = BuilderProperties.get_display_name(builder)
		var description: String = BuilderProperties.get_description(builder)
		var required_level: int = BuilderProperties.get_required_level(builder)
		var local_player_level: int = Utils.get_local_player_level()
		var builder_is_unlocked: bool = local_player_level >= required_level

		var builder_tooltip: String
		if builder_is_unlocked:
			builder_tooltip = "%s\n \n%s" % [display_name, description]
		else:
			builder_tooltip = "[color=GOLD]%s[/color] [color=RED]%d[/color]\n \n%s\n \n%s" % [tr("BUILDER_REQUIRED_LEVEL"), required_level, display_name, description]
		
		var button: Button = Preloads.builder_button_scene.instantiate()
		var icon_path: String = BuilderProperties.get_icon_path(builder)
		button.icon = load(icon_path)
		button.tooltip_text = builder_tooltip
		button.pressed.connect(_on_generic_button_pressed.bind(builder))
		button.disabled = !builder_is_unlocked
		
		var container_for_button: GridContainer
		var builder_tier: BuilderTier.enm = BuilderProperties.get_tier(builder)
		match builder_tier:
			BuilderTier.enm.BEGINNER: container_for_button = _beginner_container
			BuilderTier.enm.ADVANCED: container_for_button = _advanced_container
			BuilderTier.enm.SPECIALIST: container_for_button = _specialist_container
			BuilderTier.enm.HARDCORE: container_for_button = _hardcore_container
		
		container_for_button.add_child(button)


func get_builder_id() -> int:
	return _builder_id

func _on_generic_button_pressed(builder_id: int):
	_builder_id = builder_id
	finished.emit()
