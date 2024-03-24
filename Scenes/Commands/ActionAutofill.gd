class_name ActionAutofill extends Action


var recipe: HoradricCube.Recipe:
	get:
		return _data[Action.Field.AUTOFILL_RECIPE]


var rarity_filter: Array:
	get:
		return _data[Action.Field.AUTOFILL_RARITY_FILTER]


static func make(recipe_arg: HoradricCube.Recipe, rarity_filter_arg: Array):
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.AUTOFILL,
		Action.Field.AUTOFILL_RECIPE: recipe_arg,
		Action.Field.AUTOFILL_RARITY_FILTER: rarity_filter_arg,
		})

	return action
