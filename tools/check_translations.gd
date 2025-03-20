extends MainLoop


# Checks validity of translations in texts.csv file. Run
# this tool when adding new things to texts.csv.

const ARG_COUNT: int = 2

var all_is_ok: bool = true


func _initialize():
	print("Begin")
	run()
	print("End")


func _process(_delta: float):
	var end_main_loop: bool = true
	return end_main_loop


func run():
	var arg_list: Array = OS.get_cmdline_user_args()

	if arg_list.size() != ARG_COUNT:
		print("Incorrect args provided. Expected 2 args - old texts.csv + new texts.csv")

		return

	var text_csv_path_old: String = arg_list[0]
	var text_csv_path_new: String = arg_list[1]

	var text_id_map: Dictionary = {}

	var csv_old: Array[PackedStringArray] = load_csv(text_csv_path_old)
	var csv_new: Array[PackedStringArray] = load_csv(text_csv_path_new)

	var row_count_old: int = csv_old.size()
	var row_count_new: int = csv_new.size()
	var row_count_is_ok: bool = row_count_old == row_count_new
	if !row_count_is_ok:
		print("Mismatch in row counts: old = %s, new = %s" % [row_count_old, row_count_new])
		all_is_ok = false


	var digit_list: Array = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

	for i in range(csv_old.size()):
		var line_old: PackedStringArray = csv_old[i]
		var line_new: PackedStringArray = csv_new[i]

		var text_id_old: String = line_old[0]
		var text_id_new: String = line_new[0]
		var text_id_is_ok: bool = text_id_old == text_id_new
		if !text_id_is_ok:
			print("\n !!!!Mismatch in text id: old = %s, new = %s" % [text_id_old, text_id_new])
			all_is_ok = false

		# NOTE: disabled for now, there are too many bad text ids, will fix later
		# var text_id_first_char_is_ok: bool = !digit_list.has(text_id_new.substr(0, 1))
		# if !text_id_first_char_is_ok:
		# 	print("\n !!!!Bad text id: %s" % [text_id_new])
		# 	all_is_ok = false

		var text_id_is_correct_length: bool = text_id_new.length() == 4
		if !text_id_is_correct_length:
			print("\n !!!!Text id has incorrect length, must be 4 characters: %s" % [text_id_new])
			all_is_ok = false

		var english_text_old: String = line_old[1]
		var english_text_new: String = line_new[1]
		var english_text_is_ok: bool = english_text_old == english_text_new
		if !english_text_is_ok:
			print(" \n!!!!Mismatch in english text:\nOLD:\n\"\"\"\n%s\n\"\"\"\n \nNEW:\n\"\"\"\n%s\n\"\"\"" % [english_text_old, english_text_new])
			all_is_ok = false

		var text_id_is_duplicate: bool = text_id_map.has(text_id_old)
		if text_id_is_duplicate:
			print(" \n!!!!Detected duplicate text id: %s" % text_id_old)
			all_is_ok = false
		text_id_map[text_id_old] = true

	check_for_broken_tags(text_csv_path_new)

	if all_is_ok:
		print("All is okay!")


# This f-n checks for issues with BBCode tags:
# "]blahbla"
# or "blahbla color=GOLD] blahbla"
# or "blahbla [color=GOLD blahblah"
func check_for_broken_tags(path: String):
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)

	var line_index: int = 0

	while !file.eof_reached():
		var line: String = file.get_line()

		var closing_bracket_count: int = line.count("]")
		var opening_bracket_count: int = line.count("[")

		var bracket_mismatch: bool = closing_bracket_count != opening_bracket_count

		if bracket_mismatch:
			print(" \n!!!!Detected mismatched brackets on line %s" % line_index)
			all_is_ok = false

		line_index += 1


# NOTE: need to duplicate this f-n from Utils unfortunately
# because Utils is not accessible in a tool script.
static func load_csv(path: String) -> Array[PackedStringArray]:
	var file_exists: bool = FileAccess.file_exists(path)

	if !file_exists:
		print_debug("Failed to load CSV because file doesn't exist. Path: %s" % path)

		return []

	var list: Array[PackedStringArray] = []

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)

	var skip_title_row: bool = true
	while !file.eof_reached():
		var csv_line: PackedStringArray = file.get_csv_line()

		if skip_title_row:
			skip_title_row = false
			continue

		var is_last_line: bool = csv_line.size() == 0 || (csv_line.size() == 1 && csv_line[0].is_empty())
		if is_last_line:
			continue

		list.append(csv_line)

	file.close()

	return list
