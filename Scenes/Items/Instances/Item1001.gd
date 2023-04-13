# Oil of Sharpness
extends Item

# NOTE: this is a test item. Couldn't find oils in the same
# place as other items so created a custom id for it,
# starting from 1000 to avoid collisions with other item
# id's.


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.04, 0.0016)
