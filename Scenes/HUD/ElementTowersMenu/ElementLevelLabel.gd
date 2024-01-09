extends Label


func _ready():
	HighlightUI.register_target("element_level", self)
	self.mouse_entered.connect(func(): HighlightUI.highlight_target_ack.emit("element_level"))
