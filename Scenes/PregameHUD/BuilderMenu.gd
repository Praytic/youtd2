class_name BuilderMenu extends ScrollContainer


# NOTE: the buttons for this menu are created
# programmatically inside _ready().


signal finished()


@export var _beginner_container: VBoxContainer
@export var _advanced_container: VBoxContainer
@export var _specialist_container: VBoxContainer
@export var _hardcore_container: VBoxContainer


func _ready():
	var builder_list: Array[Builder.enm] = Builder.get_list()
	
	for builder in builder_list:
		var display_name: String = Builder.get_display_name(builder)
		var description: String = Builder.get_description(builder)
		
		var button: Button = Globals.button_with_rich_tooltip_scene.instantiate()
		button.text = display_name
		button.tooltip_text = "%s\n \n%s" % [display_name, description]
		button.pressed.connect(_on_generic_button_pressed.bind(builder))
		
		var container_for_button: VBoxContainer
		var builder_tier: BuilderTier.enm = Builder.get_tier(builder)
		match builder_tier:
			BuilderTier.enm.BEGINNER: container_for_button = _beginner_container
			BuilderTier.enm.ADVANCED: container_for_button = _advanced_container
			BuilderTier.enm.SPECIALIST: container_for_button = _specialist_container
			BuilderTier.enm.HARDCORE: container_for_button = _hardcore_container
		
		container_for_button.add_child(button)


func _on_generic_button_pressed(builder: Builder.enm):
	PregameSettings._builder = builder
	finished.emit()
