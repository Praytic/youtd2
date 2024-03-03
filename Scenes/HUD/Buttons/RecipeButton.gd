class_name RecipeButton extends Button

@export var recipe: HoradricCube.Recipe


func _ready():
	var recipe_description: String = RecipeProperties.get_description(recipe)
	set_tooltip_text(recipe_description)
