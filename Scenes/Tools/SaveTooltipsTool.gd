class_name SaveTooltipsTool extends Node


# Generates tooltips for all towers and saves them to file.
# Generating tower tooltips causes minor lag ingame so we
# want to avoid doing it during runtime. Generated tooltips
# are later accessed by RichTexts.gd. Enable
# config/run_save_tooltips_tool in project settings to run
# this tool at startup. Note that this tool needs to be used
# every time after making changes to tower properties or
# tower scripts, to update saved tooltips.


const RESULT_FILENAME: String = "Data/tower_tooltips.csv"


static func run():
	print("Saving tooltips...")
	
	var tower_id_list: Array = Properties.get_tower_id_list()

#	NOTE: sort id's so that diffs for the csv file are not
#	messy
	tower_id_list.sort()

	var result_file: FileAccess = FileAccess.open(RESULT_FILENAME, FileAccess.WRITE)

	var header_line: Array[String] = ["id", "tooltip"]
	result_file.store_csv_line(header_line)

	for tower_id in tower_id_list:
		var tooltip: String = RichTexts.generate_tower_tooltip(tower_id)
		var csv_line: Array[String] = [str(tower_id), tooltip]
		result_file.store_csv_line(csv_line)
	
	print("Done saving tooltips. Saved result to:", result_file.get_path_absolute())
