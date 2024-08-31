extends Node


# This class manages "secrets", which are loaded from csv
# file. Each secret is mapped to a key.


const SECRETS_CSV_PATH: String = "res://assets/secrets/secrets.csv"


class Key:
	const SERVER_KEY: String = "socket.server_key"
	const ICE_USERNAME: String = "ice.username"
	const ICE_CREDENTIAL: String = "ice.credential"


var KEY_LIST: Array[String] = [
	Secrets.Key.SERVER_KEY,
	Secrets.Key.ICE_USERNAME,
	Secrets.Key.ICE_CREDENTIAL,
]

var _csv_dict: Dictionary = {}


func _ready():
	var csv: Array[PackedStringArray] = UtilsStatic.load_csv(SECRETS_CSV_PATH)
	
	if csv.is_empty():
		push_error("Failed to load secrets csv from: %s" % SECRETS_CSV_PATH)
		
		return

	for csv_line in csv:
		if csv_line.size() != 2:
			push_error("Secrets csv is malformed")

			continue

		var key: String = csv_line[0]
		var value: String = csv_line[1]
		_csv_dict[key] = value

	for key in KEY_LIST:
		if !_csv_dict.has(key):
			push_error("Failed to load secret: %s" % key)


func get_secret(key: String):
	var value: String = _csv_dict.get(key, "")

	return value
