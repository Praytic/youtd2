# Consumable Hobbit
extends Item


func on_consume():
	FoodManager.modify_food_cap(8)
	KnowledgeTomesManager.add_knowledge_tomes(20)
	GoldControl.modify_income_rate(0.06)
