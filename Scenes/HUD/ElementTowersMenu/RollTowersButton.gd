extends Button


func _ready():
	HighlightUI.register_target("roll_towers_button", self)
	self.pressed.connect(func(): HighlightUI.highlight_target_ack.emit("roll_towers_button"))
