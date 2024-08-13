@tool
extends EditorPlugin

func _enter_tree():
	# Initialization of the plugin goes here
	# NOTE: removed icon to avoid needing to commit png to repo
	add_custom_type("HolePunch", "Node", preload("holepunch_node.gd"), Texture2D.new())

func _exit_tree():
	# Clean-up of the plugin goes here
	remove_custom_type("HolePunch")
