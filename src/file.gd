@tool
extends Button

@export var path: String

@onready var editor_theme = EditorInterface.get_editor_theme()
@onready var preview_rect: TextureRect = $HBoxContainer/TextureRect
@onready var container: MarginContainer = $HBoxContainer/MarginContainer
@onready var label: Label = $HBoxContainer/MarginContainer/Label
@onready var checkbox: CheckBox = $HBoxContainer/CheckBox

func setup(container: Object, path: String, checked: bool, on_checked: Callable):
	self.path = path
	
	container.add_child(self)

	EditorInterface.get_resource_previewer().queue_resource_preview(path, self, "_previewReady", null)

	checkbox.set_pressed_no_signal(checked)
	checkbox.connect("toggled", on_checked)

func _previewReady(path: String, preview: Texture2D, thumbnail_preview: Texture2D, userdata: Variant):
	preview_rect.texture = preview

func _ready() -> void:
	connect("button_up", _button_up)
	
	var base_color := editor_theme.get_color("base_color", "Editor")
	var pressed_color := base_color + Color.from_rgba8(25, 25, 25)
	var hover_color := base_color + Color.from_rgba8(11, 11, 11)
	var pressed_hover_color := pressed_color + Color.from_rgba8(11, 11, 11)
	
	var style = StyleBoxFlat.new()
	style.bg_color = base_color
	style.set_corner_radius_all(4)
	
	var style22 = style.duplicate()
	style22.bg_color = pressed_color
	
	var style2 = style.duplicate()
	style2.bg_color = hover_color
	
	var style3 = style.duplicate()
	style3.bg_color = pressed_hover_color

	self.add_theme_stylebox_override("normal", style)
	self.add_theme_stylebox_override("pressed", style22)
	self.add_theme_stylebox_override("focus", style)
	
	self.add_theme_stylebox_override("hover", style2)
	self.add_theme_stylebox_override("hover_pressed", style3)
	
	label.text = path
	container.tooltip_text = path

func _button_up():
	checkbox.button_pressed = !checkbox.button_pressed
