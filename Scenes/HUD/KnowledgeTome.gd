extends MenuButton

func _init():
	var _connect_error = KnowledgeTomesManager.connect("knowledge_tomes_change", self, "_on_knowledge_tomes_change")
	
func _on_knowledge_tomes_change(new_value: int):
	self.text = str(new_value)
