extends Node


var channel = null


func _exit_tree():
	unwatch()


func watch(p_channel, p_inserted: Callable, p_updated: Callable, p_deleted: Callable):
	unwatch()
	channel = p_channel
	channel.subscribe()
	channel.inserted.connect(p_inserted)
	channel.updated.connect(p_updated)
	channel.deleted.connect(p_deleted)


func unwatch():
	if channel != null:
		channel.unsubscribe()
		channel = null
