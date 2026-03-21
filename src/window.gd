@tool
extends Window

@onready var editor_theme = EditorInterface.get_editor_theme()
@onready var bg_panel: Panel = $background
@onready var container: PanelContainer = $background/vbox/panel
@onready var progress: ProgressBar = $background/vbox/panel/margin/progress
@onready var button_export: Button = $background/vbox/margin/export

func _ready() -> void:
	# for color in editor_theme.get_color_list("Editor"):
	# 	print(color + ": #" + editor_theme.get_color(color, "Editor").to_html(false).to_upper())
	var bg_color = editor_theme.get_color("background", "Editor")
	var border_color = bg_color + Color.from_rgba8(15, 15, 15)
	var container_color = bg_color + Color.from_rgba8(10, 10, 10)

	_set_panel_color(bg_panel, bg_color)
	_set_panel_color(container, container_color)
	
	button_export.connect("pressed", _export_button_pressed)

func _set_panel_color(panel: Variant, color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color

	panel.add_theme_stylebox_override("panel", style)

var thread: Thread

func _export_button_pressed():
	thread = Thread.new()
	thread.start(Handler.start.bind(progress))

func _exit_tree():
	if thread: thread.wait_to_finish()
