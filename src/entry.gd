@tool
extends EditorPlugin

func _enter_tree():
	add_tool_menu_item("Assetless Source Export...", _on_source_export_pressed)

func _exit_tree():
	remove_tool_menu_item("Assetless Source Export...")

func _on_source_export_pressed():
	var scene = preload("./window.tscn")
	
	var window = scene.instantiate()
	window.close_requested.connect(_on_window_close_requested.bind(window))
	
	EditorInterface.get_base_control().add_child(window)

func _on_window_close_requested(window):
	window.queue_free()
