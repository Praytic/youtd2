extends Button


func _ready():
	HighlightUI.register_target("upgrade_element_button", self)
	self.pressed.connect(func(): EventBus.player_performed_tutorial_advance_action.emit("press_upgrade_element_button"))
