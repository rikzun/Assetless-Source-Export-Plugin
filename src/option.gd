@tool
extends HBoxContainer

@export var text: String
@export var key: String

var once = false

var checked: bool = true:
	set(value):
		if (!once):
			once = true
			_pre_force_checked = value

		_checkbox.button_pressed = value
	get:
		return _checkbox.button_pressed

signal on_checked(value: bool)

@onready var _label: Label = $Label
@onready var _checkbox: CheckBox = $CheckBox

var _pre_force_checked: bool

func _ready() -> void:
	_label.text = text
	_pre_force_checked = checked
	_checkbox.set_pressed_no_signal(checked)
	_checkbox.connect("toggled", func(value: bool): on_checked.emit(value))

func set_force_checked(value: bool):
	if (value):
		_pre_force_checked = _checkbox.button_pressed
		_checkbox.button_pressed = true
		_checkbox.disabled = true
	else:
		_checkbox.button_pressed = _pre_force_checked
		_checkbox.disabled = false

func _input(e: InputEvent) -> void:
	var event = e as InputEventMouseButton

	if (event == null): return
	if (!event.pressed || event.button_index != MOUSE_BUTTON_LEFT): return
	if (!self.get_global_rect().has_point(event.global_position)): return
	
	checked = !checked
