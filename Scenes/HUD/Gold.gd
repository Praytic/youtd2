extends "res://Scenes/HUD/ResourceStatusPanel.gd"

func _init():
	var _connect_error = GoldManager.connect("gold_change", self, "_on_gold_change")
	
func _on_gold_change(new_value):
	self.label_text = str(int(new_value))
