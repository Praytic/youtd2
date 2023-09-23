class_name PackedMetadata


# Stores metadata about packed sprite sheets that are
# produced by PackSpriteSheet.gd.
# 
# Source rects are always 512x512 but packed rect can be any
# size and not square.
#
# Offset is the difference between center of original frame
# and packed frame. Note that this is stored in ratio of
# sprite sheet width/height and not pixels. This is for
# cases where sprite sheet is resized during load.


enum Column {
	NAME = 0,
	ROW_COUNT,
	COL_COUNT,
	OFFSET_X,
	OFFSET_Y,
	COUNT,
}

const METADATA_FILENAME: String = "metadata.csv"

var _name: String = ""
var _row_count: int = 0
var _col_count: int = 0
var _offset: Vector2 = Vector2.ZERO


func get_row_count() -> int:
	return _row_count


func get_col_count() -> int:
	return _col_count


func get_offset() -> Vector2:
	return _offset


static func make(sheet_path: String, packed_sheet: Image, rect: Rect2i, offset_pixels: Vector2) -> PackedMetadata:
	var metadata: PackedMetadata = PackedMetadata.new()
	metadata._name = PackedMetadata._get_animation_name(sheet_path)
	metadata._row_count = roundi(float(packed_sheet.get_height()) / rect.size.y)
	metadata._col_count = roundi(float(packed_sheet.get_width()) / rect.size.x)
	metadata._offset = offset_pixels / Vector2(packed_sheet.get_size())

	return metadata


func convert_to_csv_line() -> Array:
	var csv_line: Array = []
	csv_line.resize(Column.COUNT)

	csv_line[Column.NAME] = _name
	csv_line[Column.ROW_COUNT] = _row_count
	csv_line[Column.COL_COUNT] = _col_count
	csv_line[Column.OFFSET_X] = _offset.x
	csv_line[Column.OFFSET_Y] = _offset.y

	return csv_line


static func convert_from_csv_line(csv_line: Array) -> PackedMetadata:
	if csv_line.size() != Column.COUNT:
		push_error("Malformed metadata string: ", csv_line)

		return PackedMetadata.new()

	var name: String = csv_line[Column.NAME]

	var row_count: int = csv_line[Column.ROW_COUNT].to_int()
	var col_count: int = csv_line[Column.COL_COUNT].to_int()

	var offset_x: float = csv_line[Column.OFFSET_X].to_float()
	var offset_y: float = csv_line[Column.OFFSET_Y].to_float()
	var offset: Vector2 = Vector2(offset_x, offset_y)

	var metadata: PackedMetadata = PackedMetadata.new()
	metadata._name = name
	metadata._row_count = row_count
	metadata._col_count = col_count
	metadata._offset = offset

	return metadata


static func get_metadata_for_sheet(sheet_path: String) -> PackedMetadata:
	var metadata_path: String = PackedMetadata.get_metadata_path(sheet_path)

	var animation_name: String = PackedMetadata._get_animation_name(sheet_path)

	var csv: Array[PackedStringArray] = UtilsStatic.load_csv(metadata_path)

	var metadata: PackedMetadata = PackedMetadata.new()
	for csv_line in csv:
		var this_metadata: PackedMetadata = PackedMetadata.convert_from_csv_line(csv_line)

		if this_metadata._name == animation_name:
			metadata = this_metadata

			break

	return metadata


static func _get_animation_name(sheet_path: String) -> String:
	var animation_name: String = sheet_path.get_file().trim_suffix(sheet_path.get_extension()).trim_suffix(".")

	return animation_name


static func get_metadata_path(sheet_path: String) -> String:
	var metadata_path: String = "%s/%s" % [sheet_path.get_base_dir(), METADATA_FILENAME]

	return metadata_path


static func get_legend_line() -> Array:
	var legend_line: Array = [
		"name",
		"row_count",
		"col_count",
		"offset_x",
		"offset_y",
	]

	return legend_line
