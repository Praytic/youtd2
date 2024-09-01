extends Node


const BADWORDS_CSV_PATH: String = "res://assets/secrets/badwords.csv"


var _bad_words_pattern: String
var _regex_allowed_chars: RegEx
var _regex_replace: RegEx


#########################
###     Built-in      ###
#########################

func _ready():
	_regex_allowed_chars = RegEx.new()
	_regex_allowed_chars.compile(Constants.PLAYER_NAME_ALLOWED_CHARS)

	_bad_words_pattern = _create_bad_words_pattern()
	_regex_replace = RegEx.new()
	_regex_replace.compile(_bad_words_pattern)
	

#########################
###       Public      ###
#########################

# Removes invalid chars, removes bad words and applies
# length limits.
func sanitize_player_name(text: String) -> String:
	text = text.substr(0, Constants.PLAYER_NAME_LENGTH_MAX)

#	Remove invalid chars
#	NOTE: invalid chars are not allowed in player name
#	editor, but it's still possible for bad actors to put
#	them here
	var regexed_text: String = ""
	for valid_character in _regex_allowed_chars.search_all(text):
		regexed_text += valid_character.get_string()

	text = regexed_text

#	Remove out bad words
	var replace_all: bool = true
	text = _regex_replace.sub(text, "o", replace_all)

	while text.length() < Constants.PLAYER_NAME_LENGTH_MIN:
		text += "o"

	return text


#########################
###      Private      ###
#########################

func _create_bad_words_pattern() -> String:
	var csv: Array[PackedStringArray] = UtilsStatic.load_csv(BADWORDS_CSV_PATH)
	
	if csv.is_empty():
		push_error("Failed to load badwords csv from: %s" % BADWORDS_CSV_PATH)
		
		return "()"

	var word_list: Array[String] = []

	for csv_line in csv:
		if csv_line.size() != 1:
			push_error("Badwords csv is malformed. Size = %s" % csv_line.size())

			continue

		var word: String = csv_line[0]
		word_list.append(word)

	var pattern: String = "("

	for i in range(0, word_list.size()):
		if i > 0:
			pattern += "|"
			
		var word: String = word_list[i]
		pattern += word

	pattern += ")"

	return pattern
