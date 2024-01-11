extends PanelContainer


@export var _tomes_status: ResourceStatusPanel
@export var _gold_status: ResourceStatusPanel


func _ready():
	HighlightUI.register_target("tomes_status", _tomes_status)
	HighlightUI.register_target("gold_status", _gold_status)
	_tomes_status.mouse_entered.connect(func(): HighlightUI.highlight_target_ack.emit("tomes_status"))
	_gold_status.mouse_entered.connect(func(): HighlightUI.highlight_target_ack.emit("gold_status"))


func _on_items_menu_gui_input(event):
	var left_click: bool = event.is_action_released("left_click")

	if left_click:
		ItemMovement.item_stash_was_clicked()
