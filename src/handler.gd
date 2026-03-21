@tool
class_name Handler

static func start(progress: ProgressBar):
	var file_paths = _collect_project_files()
	var max_size = file_paths.size()

	var zip = ZIPPacker.new()
	zip.open("res://source.zip")

	for index in max_size:
		var file_path = file_paths[index]
		var file = FileAccess.open(file_path, FileAccess.READ)

		if file == null:
			push_error("file_path " + file_path + " cannot be opened")
			continue

		var split = file_path.split(".")
		var extension = split[split.size() - 1] if split.size() > 1 else ""

		var buffer: PackedByteArray

		match extension:
			"svg":
				var size = _svg_size_extractor(file)
				var content = _svg_patttern.format({"w": size.x, "h": size.y})
				buffer = content.to_utf8_buffer()
			
			"bmp",
			"dds",
			"exr",
			"jpg",
			"ktx",
			"png",
			"tga",
			"webp":
				var origin = Image.new()
				var file_buffer = file.get_buffer(file.get_length())
				file.close()

				match extension:
					"bmp": origin.load_bmp_from_buffer(file_buffer)
					"dds": origin.load_dds_from_buffer(file_buffer)
					"exr": origin.load_exr_from_buffer(file_buffer)
					"jpg": origin.load_jpg_from_buffer(file_buffer)
					"ktx": origin.load_ktx_from_buffer(file_buffer)
					"png": origin.load_png_from_buffer(file_buffer)
					"tga": origin.load_tga_from_buffer(file_buffer)
					"webp": origin.load_webp_from_buffer(file_buffer)

				var image = Image.create(
					origin.get_width(),
					origin.get_height(),
					false,
					origin.get_format()
				)

				image.fill(Color.WHITE)

				match extension:
					"dds": buffer = image.save_dds_to_buffer()
					"exr": buffer = image.save_exr_to_buffer()
					"png": buffer = image.save_png_to_buffer()
					"webp": buffer = image.save_webp_to_buffer()
					_: buffer = image.save_jpg_to_buffer()

			"tres":
				var resource = _tres_extractor(file)

				if resource.type == "":
					buffer = file.get_buffer(file.get_length())
					file.close()
					break
				
				file.close()

				var content = _resource_pattern.format({"start": resource.line})
				buffer = content.to_utf8_buffer()

			_:
				buffer = file.get_buffer(file.get_length())
				file.close()

		if buffer:
			zip.start_file(file_path.trim_prefix("res://"))
			zip.write_file(buffer)
			zip.close_file()
		
		progress.set_deferred("value", (index + 1) / max_size * 100)

	zip.close()

static func _collect_project_files() -> Array[String]:
	var dirs = ["res://"]
	var file_paths: Array[String] = []

	while not dirs.is_empty():
		var dir_path = dirs.pop_back()
		var dir = DirAccess.open(dir_path)

		dir.list_dir_begin()

		var full_name = dir.get_next()

		while full_name != "":
			var path = dir_path.trim_suffix("/") + "/" + full_name

			if dir.current_is_dir():
				if path == "res://.godot":
					full_name = dir.get_next()
					continue

				dirs.append(path)
				full_name = dir.get_next()
				continue

			file_paths.append(path)
			full_name = dir.get_next()
		
		dir.list_dir_end()
	
	return file_paths

static var _resource_pattern = (
	"{start}\n" +
	"\n" +
	"[resource]\n"
)

static func _tres_extractor(file: FileAccess):
	var file_content = file.get_line()
	var is_resource = file_content.begins_with("[gd_resource")
	if !is_resource: return ""

	var index = file_content.find("type=")
	if index == -1: return ""
	index += "type=".length() + 1

	var type = ""
	for char in file_content.substr(index):
		if char == '"': break
		type += char
	
	return {
		"type": type,
		"line": file_content
	}


static var _svg_patttern = (
	'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}">' +
	'<rect width="{w}" height="{h}" fill="white"/>' +
    '</svg>'
)

## also closes file
static func _svg_size_extractor(file: FileAccess) -> Vector2i:
	var file_content = file.get_buffer(2048).get_string_from_utf8()
	var file_content_size = file_content.length()
	file.close()

	var str_width = _extract_svg_attr(file_content, "width")
	if str_width.is_empty(): return Vector2i(0, 0)

	var str_height = _extract_svg_attr(file_content, "height")
	if str_height.is_empty(): return Vector2i(0, 0)

	var width = _svg_size_to_px(str_width)
	var height = _svg_size_to_px(str_height)

	return Vector2i(width, height)

static func _extract_svg_attr(content: String, name: String) -> String:
	var key = name + '="'
	var start = content.find(key)

	if start == -1: return ''
	else: start += key.length()

	var end = content.find('"', start)
	if end == -1: return ''

	return content.substr(start, end - start)

const UNITS = {
	 "px": 1.0,
	 "pt": 1.333,
	 "pc": 16.0,
	 "in": 96.0,
	 "cm": 37.8,
	 "mm": 3.78,
	  "q": 0.945,
	 "em": 1.0,
	"rem": 1.0,
	  "%": 1.0
}

static func _svg_size_to_px(size: String) -> int:
	size = size.strip_edges()

	if size.is_valid_float():
		return int(round(float(size)))

	for unit in UNITS:
		if size.ends_with(unit):
			var value := size.trim_suffix(unit)

			if value.is_valid_float():
				return int(round(float(value) * UNITS[unit]))

	return 0
