# Divine Book of Omnipotence
extends Item


func on_consume():
	KnowledgeTomesManager.add_knowledge_tomes(15)
