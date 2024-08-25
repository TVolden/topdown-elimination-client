@tool
extends EditorImportPlugin

enum Preset { PRESET_DEFAULT }

var imageLoader: ImageLoader = preload("res://addons/binarysolo.shoebox/image_loader.gd").new()
var xml: XMLParser = XMLParser.new()

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		imageLoader.free()

func _get_importer_name():
	return "binarysolo.shoebox_import_spritesheet"


func _get_visible_name():
	return "SpriteSheet from Shoebox"


func _get_recognized_extensions():
	return ["xml"]


func _get_save_extension():
	return "res"


func _get_resource_type():
	return "Resource"


func _get_preset_count():
	return Preset.size()


func _get_preset_name(preset):
	match preset:
		Preset.PRESET_DEFAULT: return "Default"


func _get_import_options(path, preset_index):
	return []


func _get_option_visibility(path, option_name, options):
	return true


func _get_import_order():
	return 200

func _get_priority():
	return 1.0

func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	# create spritesheet texture
	var spritesheet: CompressedTexture2D = get_spritesheet_texture(source_file.replace(".xml", ".png"))

	if spritesheet:
		# if spritesheet texture exists, proceed to open xml file
		if open_spritesheet_data(source_file):
			# start reading subtextures nodes
			var end: bool = false

			# loop trough xml (not closing) elements
			while not end:
				edit_tileset(spritesheet, source_file, source_file.get_basename())
				end = not read_next_texture()


##
# Create and return a stream texture from the spritesheet
##
func get_spritesheet_texture(image_path) -> CompressedTexture2D:
	var spritesheet: CompressedTexture2D = null
	var sprites_path: String = image_path

	# check if spritesheet image exists and load it
	if FileAccess.file_exists(sprites_path):
		spritesheet = load(sprites_path) as CompressedTexture2D

	return spritesheet


##
# Check if a folder exists, if not, create it
##
func init_folder(path: String) -> bool:
	# check if folder exists
	if not DirAccess.dir_exists_absolute(path):
		# if not, try to create it
		if DirAccess.make_dir_recursive_absolute(path) == OK:
			print("Create ", path, " folder: SUCCESS.")
		else:
			print("Create ", path, " folder: FAIL.")
			return false
	else:
		# folder already exists, do nothing
		print(path, " folder already exists.")
		
	return true


##
# Open spritesheet xml data to get it ready to be readed
##
func open_spritesheet_data(image_path) -> bool:
	# try to open spritesheet xml file
	if xml.open(image_path) == OK:
	# go to first subtexture element
		if xml.seek(1) == OK:
			if read_next_texture():
				print("Open xml data: SUCCESS")
				return true

	print("Open xml data: FAIL")
	return false


##
# Try to read the next xml element.
##
func read_next_texture() -> bool:
	if xml.read() == OK:
		# check if the current element is not an ending one
		if xml.get_node_type() == xml.NODE_ELEMENT:
			print("Read next sprite: SUCCESS")
			return true

	print("Read next sprite: FAIL")
	return false


##
# Edit existing tileset resource or create a new one
##
func edit_tileset(texture2D: CompressedTexture2D, texture_name: String, folder_path: String) -> void:
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	# markers of tileset name inside the path
	var begin: int = folder_path.rfind("/") + 1
	var length: int = folder_path.length() - begin

	# tileset name, derived from last subfolder name in its path
	var tileset_name: String = folder_path.substr(begin, length)

	if tileset_name == "tile":
		# if las subfolder name is just "tile" call the tileset simply "tileset"
		tileset_name = "tileset"
	else:
		# call it "lastSubfolderName_tileset"
		tileset_name += "_tileset"

	# full tileset path, including resource name and extension
	var tileset_path: String = folder_path.path_join(tileset_name + ".tres")

	var tileset: TileSet = null

	# create or load existent tileset
	if not FileAccess.file_exists(tileset_path):
		tileset = TileSet.new()
	else:
		tileset = load(tileset_path) as TileSet

	if tileset:
		# check if tile already exists
		var tile_id: int = tileset.find_tile_by_name(texture_name)
		print("id: ", tile_id)

		if tile_id == -1:
			# tile doesn't exists, create a new one
			tile_id = tileset.get_last_unused_tile_id()
			print("new id: ", tile_id)
			tileset.create_tile(tile_id)

		tileset.tile_set_name(tile_id, texture_name)
		tileset.tile_set_texture(tile_id, texture.atlas)
		tileset.tile_set_region(tile_id, texture.region)

		# save new/edited tileset to disk
		if ResourceSaver.save(tileset, tileset_path) == OK:
			print("tileset: ", tileset_path, " saved.")
		else:
			print("Error while saving tileset: ", tileset_path)


##
# Get subtexture region from 'x','y','width', and 'height' element's attributes
##
func get_texture_region() -> Rect2:
	var x: float = xml.get_named_attribute_value("x") as float
	var y: float = xml.get_named_attribute_value("y") as float
	var width: float = xml.get_named_attribute_value("width") as float
	var height: float = xml.get_named_attribute_value("height") as float

	return Rect2(x, y, width, height)
