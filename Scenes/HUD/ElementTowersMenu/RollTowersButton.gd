extends Button


func _ready():
	HighlightUI.register_target("roll_towers_button", self)
	self.pressed.connect(func(): EventBus.player_performed_tutorial_advance_action.emit("press_roll_button"))
