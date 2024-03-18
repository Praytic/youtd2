extends Label


func _ready():
	HighlightUI.register_target("element_level", self)
	self.mouse_entered.connect(func(): EventBus.player_performed_tutorial_advance_action.emit("mouse_over_element_level"))
