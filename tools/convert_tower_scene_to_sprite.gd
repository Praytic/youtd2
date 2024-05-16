extends MainLoop


# NOTE: this script works for most towers but stumbles on
# some. Run TestTowersTool to check which towers failed and
# fix manually.


func _initialize():
	print("Begin")
	run()
	print("End")


func _process(_delta: float):
	var end_main_loop: bool = true
	return end_main_loop


func run():
	var file_list: PackedStringArray = DirAccess.get_files_at(".")

	for file in file_list:
		process_file(file)


func process_file(path: String):
	if !FileAccess.file_exists(path):
		push_error("No file found at path %s" % path)

		return

	var original_content: String = FileAccess.get_file_as_string(path)
	var result_content: String = make_result_content(original_content)

	# var result_path: String = path.replace(".tscn", "-result.tscn")
	var result_path: String = path
	var result_file: FileAccess = FileAccess.open(result_path, FileAccess.WRITE)
	result_file.store_string(result_content)


func make_result_content(original_content: String) -> String:
	var original_lines: Array = original_content.split("\n")
	var result_lines: Array = []

	for line in original_lines:
		var tower_resource: bool = line.contains("ext_resource type=\"PackedScene\"")
		var script_resource: bool = line.contains("ext_resource type=\"Script\"")
		if tower_resource || script_resource:
			continue

		var script_node: bool = line.contains("script = ")
		if script_node:
			# NOTE: also remove previous line and previous
			# empty line
			result_lines.pop_back()
			result_lines.pop_back()

			continue

		var sprite_node: bool = line.contains("node name=")
		if sprite_node:
			line = "[node name=\"Sprite2D\" type=\"Sprite2D\"]"

		var load_steps: bool = line.contains("load_steps")
		if load_steps:
			line = fix_load_steps(line)

		result_lines.append(line)

	var result_content: String = "\n".join(result_lines)

	return result_content


func fix_load_steps(line: String) -> String:
	var load_steps_left: String = "load_steps="
	var split_load_steps: Array = line.split(load_steps_left)

	if split_load_steps.size() == 1:
		push_error("Failed to fix load steps, error 1")

		return line

	var split_space: Array = split_load_steps[1].split(" ")

	if split_space.size() == 1:
		push_error("Failed to fix load steps, error 2")

		return line

	var original_steps_string: String = split_space[0]
	var original_steps: int = original_steps_string as int
#	NOTE: subtract 2 because there's -1 step from removal of
#	script and another -1 step from removal of Tower.tscn
	var result_steps: int = original_steps - 2

	var original_load_steps_substr: String = load_steps_left + original_steps_string
	var fixed_load_steps_substr: String = load_steps_left + str(result_steps)

	var fixed_line: String = line.replace(original_load_steps_substr, fixed_load_steps_substr)

	return fixed_line
