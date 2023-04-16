extends Node

# NOTE: use for print calls that should be easy to
# enable/disable globally. This is a workaround for godot's
# native print_debug() not being disabled in non-debug
# builds.
static func debug(args):
	if FF.log_debug_enabled():
		print("[%s] " % (Time.get_ticks_msec() / 1000.0), args)
