@tool
extends "res://Scenes/HUD/ResourceStatusPanel.gd"

func _ready():
	super()

	GoldManager.connect("gold_change",Callable(self,"_on_gold_change"))

	var initial_value: int = int(GoldManager.gold)
	_on_gold_change(initial_value)

func _on_gold_change(new_value):
	set_label_text(str(int(new_value)))
