class_name Language extends Node

enum enm {
	ENGLISH,
	CHINESE,
}

static var language_map: Dictionary = {
	Language.enm.ENGLISH: "en",
	Language.enm.CHINESE: "zh",
}

static var language_option_map: Dictionary = {
	Language.enm.ENGLISH: 0,
	Language.enm.CHINESE: 1,
}

static var language_option_locale_map: Dictionary = {
	0:"en",
	1:"zh",
}

static func get_locale_from_enum (lan: Language.enm) -> String:
	return language_map[lan]

static func get_enum_from_option (opt: int) -> Language.enm:
	return language_option_map[opt]

static func get_option_from_locale (lan: String) -> int:
	return language_option_locale_map.find_key(lan)

static func get_locale_from_option (opt: int) -> String:
	return language_option_locale_map[opt]
