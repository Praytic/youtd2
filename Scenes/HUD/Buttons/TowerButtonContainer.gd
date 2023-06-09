extends Control


@onready var tower_button = $UnitButton


func set_tower(tower_id: int):
	tower_button.set_tower(tower_id)
