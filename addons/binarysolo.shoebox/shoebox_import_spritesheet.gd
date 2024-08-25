@tool
extends EditorImportPlugin

enum Preset { PRESET_DEFAULT }
enum ShoeboxImportType { Sprites, Tileset }

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
	return [{
		"name": "Format",
		"type": TYPE_STRING,
		"property_hint": PROPERTY_HINT_ENUM,
		"hint_string": "Sprites,Tileset",
		"default_value": ShoeboxImportType.Sprites
		}, {
			"name": "TileSize",
			"type": TYPE_VECTOR2I,
			"default_value": Vector2i(0, 0)
		}]


func _get_option_visibility(path, option_name, options):
	return true


func _get_import_order():
	return 200

func _get_priority():
	return 1.0

func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	print("Options: ", options)
	# create spritesheet texture
	var spritesheet: CompressedTexture2D = get_spritesheet_texture(source_file.replace(".xml", ".png"))

	if spritesheet:
		# if spritesheet texture exists, proceed to open xml file
		if open_spritesheet_data(source_file):
			# start reading subtextures nodes
			var end: bool = false

			if options["Format"] == ShoeboxImportType.Sprites:
				# loop trough xml (not closing) elements
				while not end:
					edit_texture(spritesheet, source_file.get_basename())
					end = not read_next_texture()
			else:
				edit_tileset(spritesheet, source_file, source_file.get_base_dir(), options["TileSize"])


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
# Edit a new atlas texture, or edit it if already exists
##
func edit_texture(spritesheet: CompressedTexture2D, folder_path: String) -> void:
	var atlas_texture: AtlasTexture = null
	
	# texture full path
	var name: PackedStringArray = xml.get_named_attribute_value("name").split("_")
	var file_name: String = name[-1].trim_suffix(".png")
	var resource_path: String = folder_path.path_join(file_name + ".tres")
	
	# texture spritesheet region
	var rect: Rect2 = get_texture_region()

	if init_folder(folder_path):
		if not FileAccess.file_exists(resource_path):
			atlas_texture = AtlasTexture.new()
		else:
			atlas_texture = load(resource_path) as AtlasTexture

	atlas_texture.atlas = spritesheet
	atlas_texture.region = rect

	# save new/edited atlas texture to disk
	if ResourceSaver.save(atlas_texture, resource_path) == OK:
		print("Atlas texture: ", resource_path, " saved.")
	else:
		print("Error while saving atlas texture: ", resource_path)


##
# Edit existing tileset resource or create a new one
##
func edit_tileset(texture2D: CompressedTexture2D, texture_name: String, folder_path: String, tile_size: Vector2i) -> void:
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	
	print(folder_path)
	# markers of tileset name inside the path
	var begin: int = texture_name.rfind("/") + 1
	var length: int = texture_name.length() - begin - 4 # 4 = .xml

	# tileset name, derived from last subfolder name in its path
	var tileset_name: String = texture_name.substr(begin, length) + "_tileset"
	print(folder_path, " ", tileset_name)

	# full tileset path, including resource name and extension
	var tileset_path: String = folder_path.path_join(tileset_name + ".tres")
	print(tileset_path)
	
	var tileset: TileSet = null

	# create or load existent tileset
	if not FileAccess.file_exists(tileset_path):
		tileset = TileSet.new()
	else:
		tileset = load(tileset_path) as TileSet
	
	if tileset != null:
		for i in tileset.get_source_count():
			var source_id = tileset.get_source_id(i)
			var source = tileset.get_source(source_id)
			if source is TileSetAtlasSource:
				if source.resource_name == texture2D.resource_name:
					tileset.remove_source(source_id)
					break
	
	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = texture2D
	
	var end: bool = false
	var recalc_size: bool = false
	while not end:
		var name: PackedStringArray = xml.get_named_attribute_value("name").split("_")
		var file_name: String = name[-1].trim_suffix(".png")
		var rect = get_texture_region()
		if tile_size.x == 0:
			tile_size.x = rect.size.x
		if tile_size.y == 0:
			tile_size.y = rect.size.y
		var position = Vector2i(rect.position.x / tile_size.x, rect.position.y / tile_size.y)
		var size = Vector2i(max(1, rect.size.x / tile_size.x), max(1, rect.size.y / tile_size.y))
		print(file_name, " ", rect, " ", size)
		atlas_source.create_tile(position, size)
		end = not read_next_texture()
	
	atlas_source.texture_region_size = tile_size
	tileset.add_source(atlas_source)
	tileset.tile_size = tile_size

	if tileset:
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
