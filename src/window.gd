@tool
extends Window

@onready var editor_theme = EditorInterface.get_editor_theme()
@onready var panel: Panel = $Panel
@onready var container: PanelContainer = $Panel/VBoxContainer/PanelContainer

@onready var folder_line_edit: LineEdit = $Panel/VBoxContainer/PanelContainer/MarginBox/HBoxContainer/VBoxContainer2/HBoxContainer/LineEdit
@onready var select_folder: Button = $Panel/VBoxContainer/PanelContainer/MarginBox/HBoxContainer/VBoxContainer2/HBoxContainer/Button
@onready var dialog: FileDialog = $Panel/VBoxContainer/PanelContainer/MarginBox/HBoxContainer/VBoxContainer2/HBoxContainer/FileDialog

@onready var archive_name_line_edit: LineEdit = $Panel/VBoxContainer/PanelContainer/MarginBox/HBoxContainer/VBoxContainer2/HBoxContainer2/LineEdit

@onready var file_container: VBoxContainer = $Panel/VBoxContainer/PanelContainer/MarginBox/HBoxContainer/ScrollContainer/VBoxContainer

@onready var option1 = $Panel/VBoxContainer/PanelContainer/MarginBox/HBoxContainer/VBoxContainer2/HBoxContainer6
@onready var option2 = $Panel/VBoxContainer/PanelContainer/MarginBox/HBoxContainer/VBoxContainer2/HBoxContainer5
@onready var option3 = $Panel/VBoxContainer/PanelContainer/MarginBox/HBoxContainer/VBoxContainer2/HBoxContainer7

@onready var export_button: Button = $Panel/VBoxContainer/MarginBox/Button

@onready var file_scene = preload("./file.tscn")

var current_dir = get_script().resource_path.get_base_dir()
var plugin_dir = current_dir.get_base_dir()

var excluded_file_path = plugin_dir.path_join("excluded.json")
var excluded_files = _get_excluded_files()

var settings_file_path = plugin_dir.path_join("settings.json")
var settings = _get_settings()

func _get_excluded_files() -> Array[String]:
	if (!FileAccess.file_exists(excluded_file_path)):
		return []

	var excluded_file = FileAccess.open(excluded_file_path, FileAccess.READ)
	var file_content = excluded_file.get_as_text()
	excluded_file.close()

	if (file_content == ""):
		return []

	var parsed = JSON.parse_string(file_content) as Array
	if (parsed == null):
		DirAccess.remove_absolute(excluded_file_path)
		return []

	var ret: Array[String] = []
	ret.assign(parsed)

	return ret

func _set_excluded_path(path: String, exclude: bool):
	if (!FileAccess.file_exists(excluded_file_path)):
		if (!exclude):
			return
		else:
			FileAccess.open(excluded_file_path, FileAccess.WRITE).close()
	
	var excluded_file = FileAccess.open(excluded_file_path, FileAccess.READ)
	var file_content = excluded_file.get_as_text()
	excluded_file.close()

	if (file_content == ""):
		file_content = "[]"

	var parsed = JSON.parse_string(file_content) as Array
	if (parsed == null):
		if (exclude):
			parsed = []
		else:
			DirAccess.remove_absolute(excluded_file_path)
	
	if (exclude):
		parsed.append(path)
	else:
		parsed.erase(path)

	var new_json = JSON.stringify(parsed, "  ")

	var excluded_file2 = FileAccess.open(excluded_file_path, FileAccess.WRITE)
	excluded_file2.store_string(new_json)
	excluded_file2.close()

var _default_settings = {
	"input.archiveName": "source",
	"exclude.godotFolder": true,
	"exclude.pluginFolder": false,
	"exclude.pluginSettings": true
}

func _create_default_settings():
	var new_file = FileAccess.open(settings_file_path, FileAccess.WRITE)

	var json = JSON.stringify(_default_settings, "  ")

	new_file.store_string(json)
	new_file.close()

	return _default_settings

func _get_settings() -> Dictionary[String, Variant]:
	if (!FileAccess.file_exists(settings_file_path)):
		return _create_default_settings()

	var file_handle = FileAccess.open(settings_file_path, FileAccess.READ)
	var file_content = file_handle.get_as_text()
	file_handle.close()

	if (file_content == ""):
		return {}

	var parsed = JSON.parse_string(file_content)
	if (parsed == null):
		DirAccess.remove_absolute(settings_file_path)
		return {}

	var ret: Dictionary[String, Variant] = {}
	ret.assign(parsed)

	return ret

func _set_settings(key: String, value: Variant):
	if (!FileAccess.file_exists(settings_file_path)):
		_create_default_settings()
	
	var file_handle = FileAccess.open(settings_file_path, FileAccess.READ)
	var file_content = file_handle.get_as_text()
	file_handle.close()

	var parsed: Dictionary
	if (file_content == ""):
		parsed = _default_settings
	else:
		parsed = JSON.parse_string(file_content)

		if (parsed == null):
			parsed = _default_settings
	
	parsed.set(key, value)

	var new_json = JSON.stringify(parsed, "  ")

	var file_handle2 = FileAccess.open(settings_file_path, FileAccess.WRITE)
	file_handle2.store_string(new_json)
	file_handle2.close()

var project_files
var show_files

func _ready() -> void:
	var bg_color = editor_theme.get_color("background", "Editor")
	var container_color = bg_color + Color.from_rgba8(11, 11, 11)
	var border_color = bg_color + Color.from_rgba8(40, 40, 40)
	
	_set_panel_color(panel, bg_color)
	_set_panel_color(container, container_color)
	
	var line_edit_style = StyleBoxFlat.new()
	line_edit_style.bg_color = bg_color + Color.from_rgba8(7, 7, 7)
	line_edit_style.border_color = border_color
	line_edit_style.set_border_width_all(1)
	line_edit_style.set_corner_radius_all(4)
	line_edit_style.content_margin_left = 10
	line_edit_style.content_margin_right = 10
	line_edit_style.content_margin_top = 4
	line_edit_style.content_margin_bottom = 4
	
	folder_line_edit.add_theme_stylebox_override("normal", line_edit_style)
	archive_name_line_edit.add_theme_stylebox_override("normal", line_edit_style)
	
	select_folder.icon = editor_theme.get_icon("Folder", "EditorIcons")
	select_folder.connect("pressed", dialog.popup_centered)
	
	dialog.connect("dir_selected", _folder_selected)

	option1.checked = settings.get("exclude.godotFolder")
	option1.connect("on_checked", func(value: bool):
		_set_settings("exclude.godotFolder", value)
	)

	option2.checked = settings.get("exclude.pluginFolder")
	option2.connect("on_checked", func(value: bool):
		_set_settings("exclude.pluginFolder", value)
		option3.set_force_checked(value)
	)

	if (option2.checked):
		option3.set_force_checked(true)
	
	option3.checked = settings.get("exclude.pluginSettings")
	option3.connect("on_checked", func(value: bool):
		_set_settings("exclude.pluginSettings", value)
	)

	folder_line_edit.text = settings.get("input.archivePath")
	folder_line_edit.connect("text_changed", func(value: String):
		folder_line_edit.tooltip_text = value
		_set_settings("input.archivePath", value)
	)

	archive_name_line_edit.text = settings.get("input.archiveName")
	archive_name_line_edit.connect("text_changed", func(value: String):
		archive_name_line_edit.tooltip_text = value
		_set_settings("input.archiveName", value)
	)
	
	project_files = _collect_project_files()
	show_files = _filter_project_files(project_files, plugin_dir)

	for file_path in show_files:
		if file_path.begins_with(plugin_dir): continue

		var checked = !excluded_files.has(file_path)
		var file_scene = file_scene.instantiate()
		
		file_scene.setup(
			file_container,
			file_path,
			checked,
			func(checked: bool):
				_set_excluded_path(file_path, !checked)
		)
	
	export_button.connect("button_up", _export)

func _export():
	var output_path = folder_line_edit.text
	var archive_name = archive_name_line_edit.text + ".zip"
	var full_archive_path = output_path.path_join(archive_name)

	var error = DirAccess.make_dir_recursive_absolute(folder_line_edit.text)
	if (error != OK):
		var dialog := AcceptDialog.new()
		dialog.title = "Error"
		dialog.dialog_text = "Wrong output path"
		dialog.exclusive = true
		
		self.add_child(dialog)
		dialog.popup_centered()
		return

	var tempFile = FileAccess.open(full_archive_path, FileAccess.WRITE)
	if (tempFile == null):
		var dialog := AcceptDialog.new()
		dialog.title = "Error"
		dialog.dialog_text = "Wrong archive name"
		dialog.exclusive = true
		
		self.add_child(dialog)
		dialog.popup_centered()
		return
	else:
		tempFile.close()
		DirAccess.remove_absolute(full_archive_path)

	var zip = ZIPPacker.new()
	var zip_open_error = zip.open(full_archive_path)
	
	if (zip_open_error != OK):
		var dialog := AcceptDialog.new()
		dialog.title = "Error"
		dialog.dialog_text = "Cannot write to a zip file"
		dialog.exclusive = true
		
		self.add_child(dialog)
		dialog.popup_centered()
		return

	for file_path in project_files:
		if (option1.checked && file_path.begins_with("res://.godot")): continue
		if (option2.checked && file_path.begins_with(plugin_dir)): continue
		if (option3.checked && (file_path == excluded_file_path || file_path == settings_file_path)): continue

		if (file_path.ends_with(archive_name)):
			if (ProjectSettings.globalize_path(file_path) == full_archive_path): continue

		var excluded = excluded_files.has(file_path)
		var file = FileAccess.open(file_path, FileAccess.READ)

		if (excluded):
			var buffer = file.get_buffer(file.get_length())
			file.close()

			zip.start_file(file_path.trim_prefix("res://"))
			zip.write_file(buffer)
			zip.close_file()
			continue

		var split = file_path.split(".")
		var extension = split[split.size() - 1] if split.size() > 1 else ""

		var buffer: PackedByteArray

		match extension:
			"svg":
				var size = _svg_size_extractor(file)

				if (size.is_empty()):
					var content = _svg_patttern.format({"w": size.x, "h": size.y})
					buffer = content.to_utf8_buffer()
				else:
					buffer = file.get_buffer(file.get_length())

				file.close()
			
			"bmp", "dds", "exr", "jpg", "ktx", "png", "tga", "webp":
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
				var resource = _tres_extractor2(file)

				if resource.type == "" || resource.type == "Resource":
					buffer = file.get_buffer(file.get_length())
					file.close()
					break
				
				file.close()

				var content = _resource_pattern.format({"start": resource.line})
				buffer = content.to_utf8_buffer()

			_:
				buffer = file.get_buffer(file.get_length())
				file.close()

		if (buffer):
			zip.start_file(file_path.trim_prefix("res://"))
			zip.write_file(buffer)
			zip.close_file()

	zip.close()

static var _svg_patttern = (
	'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}">' +
	'<rect width="{w}" height="{h}" fill="white"/>' +
    '</svg>'
)

static func _svg_size_extractor(file: FileAccess) -> Array[String]:
	var file_content = file.get_buffer(2048).get_string_from_utf8()
	var file_content_size = file_content.length()

	var str_width = _extract_svg_attr(file_content, "width")
	if str_width.is_empty(): return []

	var str_height = _extract_svg_attr(file_content, "height")
	if str_height.is_empty(): return []

	return [str_width, str_height]

static func _extract_svg_attr(content: String, name: String) -> String:
	var key = name + '="'
	var start = content.find(key)

	if start == -1: return ''
	else: start += key.length()

	var end = content.find('"', start)
	if end == -1: return ''

	return content.substr(start, end - start)

func _folder_selected(path: String):
	folder_line_edit.text = path
	folder_line_edit.tooltip_text = folder_line_edit.text
	_set_settings("input.archivePath", path)

func _set_panel_color(panel: Variant, color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color

	panel.add_theme_stylebox_override("panel", style)

var thread: Thread

func _open_folder():
	var index = folder_line_edit.text.rfind("/")
	var path = folder_line_edit.text.substr(0, index)
	OS.shell_show_in_file_manager(path)

func _exit_tree():
	if thread: thread.wait_to_finish()
	
func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_cancel")):
		var focus = get_viewport().gui_get_focus_owner()
		
		if focus != null:
			focus.release_focus()
		else:
			queue_free()
	
	if event is InputEventMouseButton:
		if not folder_line_edit.get_global_rect().has_point(event.global_position):
			folder_line_edit.release_focus()
		
		if not archive_name_line_edit.get_global_rect().has_point(event.global_position):
			archive_name_line_edit.release_focus()

func _collect_project_files() -> Array[String]:
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
				dirs.append(path)
				full_name = dir.get_next()
				continue

			file_paths.append(path)
			full_name = dir.get_next()
		
		dir.list_dir_end()
	
	return file_paths
	
func _filter_project_files(files: Array[String], plugin_dir: String) -> Array[String]:
	var filtered: Array[String] = []
	var images = ["svg", "bmp", "dds", "exr", "jpg", "ktx", "png", "tga", "webp"]
	
	for file_path in files:
		if file_path.begins_with(plugin_dir): continue
		if file_path.begins_with("res://.godot"): continue
		
		var index = file_path.rfind(".")
		if index == -1: continue
		
		var ext = file_path.substr(index + 1)
		if images.has(ext):
			filtered.push_back(file_path)
		
		if ext == "tres":
			var resource = _tres_extractor(file_path)
			if resource.type == "": continue
			if resource.type == "Resource": continue
			
			filtered.push_back(file_path)
			
	return filtered
	
static var _resource_pattern = (
	"{start}\n" +
	"\n" +
	"[resource]\n"
)

static func _tres_extractor(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	var file_content = file.get_line()
	file.close()

	var is_resource = file_content.begins_with("[gd_resource")
	if !is_resource: return {}

	var index = file_content.find("type=")
	if index == -1: return {}
	index += "type=".length() + 1
	
	var type = ""
	for char in file_content.substr(index):
		if char == '"': break
		type += char
	
	return {
		"type": type,
		"line": file_content
	}

static func _tres_extractor2(file: FileAccess):
	var file_content = file.get_line()
	var is_resource = file_content.begins_with("[gd_resource")
	if !is_resource: return {}

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
