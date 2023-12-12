extends Control


@export var _tomes_status: ResourceStatusPanel
@export var _gold_status: ResourceStatusPanel


func _ready():
	HighlightUI.register_target("tomes_status", _tomes_status)
	HighlightUI.register_target("gold_status", _gold_status)
