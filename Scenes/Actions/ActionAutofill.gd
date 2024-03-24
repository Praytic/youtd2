class_name ActionAutofill


static func make(recipe_arg: HoradricCube.Recipe, rarity_filter_arg: Array) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.AUTOFILL,
		Action.Field.AUTOFILL_RECIPE: recipe_arg,
		Action.Field.AUTOFILL_RARITY_FILTER: rarity_filter_arg,
		})

	return action


static func execute(action: Dictionary, player: Player):
	var recipe: HoradricCube.Recipe = action[Action.Field.AUTOFILL_RECIPE]
	var rarity_filter: Array = action[Action.Field.AUTOFILL_RARITY_FILTER]

	HoradricCube.autofill(player, recipe, rarity_filter)
