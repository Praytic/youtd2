@tool
extends ResourceStatusPanel

func _ready():
	super()

	if not Engine.is_editor_hint():
		KnowledgeTomesManager.changed.connect(_on_knowledge_tomes_changed)
		_on_knowledge_tomes_changed()
	
func _on_knowledge_tomes_changed():
	var new_value: int = KnowledgeTomesManager.get_current()
	set_label_text(str(new_value))
