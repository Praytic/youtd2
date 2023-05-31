extends ResourceStatusPanel

func _ready():
	super()

	KnowledgeTomesManager.knowledge_tomes_change.connect(_on_knowledge_tomes_change)

	_on_knowledge_tomes_change()
	
func _on_knowledge_tomes_change():
	var new_value: int = KnowledgeTomesManager.get_current()
	set_label_text(str(new_value))
