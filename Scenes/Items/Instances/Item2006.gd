# Arcane Book of Power
extends Item


func on_consume():
	KnowledgeTomesManager.add_knowledge_tomes(8)
