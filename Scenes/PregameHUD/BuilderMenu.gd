class_name BuilderMenu extends ScrollContainer


# NOTE: the buttons for this menu are created
# programmatically inside _ready().


signal finished()


@export var _beginner_container: VBoxContainer
@export var _advanced_container: VBoxContainer
@export var _specialist_container: VBoxContainer
@export var _hardcore_container: VBoxContainer


func _ready():
	var builder_list: Array = BuilderProperties.get_id_list()
	
	for builder in builder_list:
		var short_name: String = BuilderProperties.get_short_name(builder)

		if short_name == "none":
			continue

		var display_name: String = BuilderProperties.get_display_name(builder)
		var description: String = BuilderProperties.get_description(builder)
		
		var button: Button = Globals.button_with_rich_tooltip_scene.instantiate()
		button.text = display_name
		button.tooltip_text = "%s\n \n%s" % [display_name, description]
		button.pressed.connect(_on_generic_button_pressed.bind(builder))
		
		var container_for_button: VBoxContainer
		var builder_tier: BuilderTier.enm = BuilderProperties.get_tier(builder)
		match builder_tier:
			BuilderTier.enm.BEGINNER: container_for_button = _beginner_container
			BuilderTier.enm.ADVANCED: container_for_button = _advanced_container
			BuilderTier.enm.SPECIALIST: container_for_button = _specialist_container
			BuilderTier.enm.HARDCORE: container_for_button = _hardcore_container
		
		container_for_button.add_child(button)
	
#	TODO: unhide these containers when their builders are implemented
	_specialist_container.hide()
	_hardcore_container.hide()


func _on_generic_button_pressed(builder_id: int):
	PregameSettings._builder_id = builder_id
	finished.emit()
