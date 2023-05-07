class_name Rarity
extends Object


enum enm {
	COMMON,
	UNCOMMON,
	RARE,
	UNIQUE,
}


static func convert_from_string(string: String) -> Rarity.enm:
	match string:
		"common": return Rarity.enm.COMMON
		"uncommon": return Rarity.enm.UNCOMMON
		"rare": return Rarity.enm.RARE
		"unique": return Rarity.enm.UNIQUE

	push_error("Unhandled rarity: ", string)

	return Rarity.enm.COMMON


static func convert_to_string(rarity: Rarity.enm) -> String:
	match rarity:
		Rarity.enm.COMMON: return "common"
		Rarity.enm.UNCOMMON: return "uncommon"
		Rarity.enm.RARE: return "rare"
		Rarity.enm.UNIQUE: return "unique"

	push_error("Unhandled rarity: ", rarity)

	return "unknown"
