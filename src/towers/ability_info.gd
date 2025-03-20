class_name AbilityInfo

var name_english: String = "PLACEHOLDER name"
var name: String = "PLACEHOLDER name"
var icon: String = "PLACEHOLDER icon"
var description_short: String = "PLACEHOLDER description_short"
var description_long: String = "PLACEHOLDER description_long"

# NOTE: these values should be defined if ability has a
# range
var radius: float = 0
var target_type: TargetType = null


#########################
###       Static      ###
#########################

static func make(ability_id: int) -> AbilityInfo:
	var ability: AbilityInfo = AbilityInfo.new()

	ability.name_english = AbilityProperties.get_name_english(ability_id)
	ability.name = AbilityProperties.get_ability_name(ability_id)
	ability.radius = AbilityProperties.get_ability_range(ability_id)
	ability.target_type = AbilityProperties.get_target_type(ability_id)
	ability.icon = AbilityProperties.get_icon_path(ability_id)
	ability.description_short = AbilityProperties.get_description_short(ability_id)
	ability.description_long = AbilityProperties.get_description_long(ability_id)

	return ability
