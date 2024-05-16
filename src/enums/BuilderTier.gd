class_name BuilderTier extends Node


enum enm {
	BEGINNER,
	ADVANCED,
	SPECIALIST,
	HARDCORE,
}


static var _string_map: Dictionary = {
	BuilderTier.enm.BEGINNER: "beginner",
	BuilderTier.enm.ADVANCED: "advanced",
	BuilderTier.enm.SPECIALIST: "specialist",
	BuilderTier.enm.HARDCORE: "hardcore",
}


static func convert_to_string(type: BuilderTier.enm):
	return _string_map[type]


static func from_string(string: String) -> BuilderTier.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return BuilderTier.enm.BEGINNER
