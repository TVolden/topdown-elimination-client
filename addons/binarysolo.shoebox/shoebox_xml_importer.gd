##
# XMLSpritesheetImporter.gd
##
@tool
extends EditorPlugin

var import_plugin_tilesheet = null
var import_plugin_spritesheet = null


func get_name():
	return "Shoebox XML Importer"


func _enter_tree():
	import_plugin_spritesheet = preload("res://addons/binarysolo.shoebox/shoebox_import_spritesheet.gd").new()
	add_import_plugin(import_plugin_spritesheet)


func _exit_tree():
	remove_import_plugin(import_plugin_spritesheet)
	import_plugin_spritesheet = null
