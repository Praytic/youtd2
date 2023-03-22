class_name TriggersBuffType
extends BuffType

# Convenience subclass for buffs which are used only to add
# triggers (event handlers). Can create without having to
# pass unimportant parameters to constructor.

func _init():
	super("", 0, 0, true)
