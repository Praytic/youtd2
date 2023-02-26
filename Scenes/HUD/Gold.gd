tool
extends "res://Scenes/HUD/ResourceStatusPanel.gd"

func _ready():
	GoldManager.connect("gold_change", self, "_on_gold_change")

	var initial_value: int = int(GoldManager.gold)
	_on_gold_change(initial_value)

func _on_gold_change(new_value):
	set_label_text(str(int(new_value)))
