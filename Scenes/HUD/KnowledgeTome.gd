@tool
extends "res://Scenes/HUD/ResourceStatusPanel.gd"

func _ready():
	KnowledgeTomesManager.connect("knowledge_tomes_change",Callable(self,"_on_knowledge_tomes_change"))

	var initial_value: int = KnowledgeTomesManager.knowledge_tomes
	_on_knowledge_tomes_change(initial_value)
	
func _on_knowledge_tomes_change(new_value: int):
	set_label_text(str(new_value))
