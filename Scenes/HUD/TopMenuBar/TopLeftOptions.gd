extends Control


@onready var gameScene = get_tree().get_root().get_node("GameScene")
@onready var livesBar: TextureProgressBar = $MarginContainer/LivesProgressBar


func _process(_delta: float):
	livesBar.value = max(gameScene.portal_lives, 0)
	livesBar.tooltip_text = "Lives left: %s" % gameScene.portal_lives
