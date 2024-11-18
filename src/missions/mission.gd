class_name Mission extends Node


signal was_failed()


var _id: int


#########################
###     Built-in      ###
#########################

func _init(id: int):
	_id = id


#########################
###       Public      ###
#########################

func get_id() -> int:
	return _id


# This f-n gets called periodically to check for fail conditions.
# Override in subclass to implement mission logic.
func check_for_fail():
	pass


# Override this f-n in subclasses to implement mission
# reaction to game finish. Return true if mission was
# completed, false if failed.
func process_game_win() -> bool:
	return true


# Call in subclass to declare that mission was failed
func mission_failed():
	was_failed.emit()
