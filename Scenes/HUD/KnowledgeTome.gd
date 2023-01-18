tool
extends "res://Scenes/HUD/ResourceStatusPanel.gd"

func _init():
	KnowledgeTomesManager.connect("knowledge_tomes_change", self, "_on_knowledge_tomes_change")
	
func _on_knowledge_tomes_change(new_value: int):
	self.label_text = str(new_value)
