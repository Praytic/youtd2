extends Button


func _ready():
	HighlightUI.register_target("upgrade_element_button", self)
	self.pressed.connect(func(): HighlightUI.highlight_target_ack.emit("upgrade_element_button"))
