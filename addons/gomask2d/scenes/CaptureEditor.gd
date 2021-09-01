tool
extends MarginContainer

const Mask2D := preload("res://addons/gomask2d/Mask2D.gd")

var mask2d: Mask2D
onready var capture_button := $VBoxContainer/HBoxContainer/CaptureButton
onready var debug_button := $VBoxContainer/HBoxContainer/DebugButton
onready var tex_size_label := $VBoxContainer/VBoxContainer/TexSizeLabel


func _ready() -> void:
	_toggle_disable_buttons()
	if mask2d:
		debug_button.pressed = mask2d._is_debug
		mask2d.connect("changes", self, "_on_Mask2D_changes")
		mask2d.connect("tex_resize", self, "_on_Mask2D_text_resize")


func _toggle_disable_buttons() -> void:
	if mask2d.object_container and mask2d.texture_name:
		capture_button.disabled = false
		debug_button.disabled = false
		return
	capture_button.disabled = true
	debug_button.disabled = true
	debug_button.pressed = false


func _on_Mask2D_changes() -> void:
	_toggle_disable_buttons()


func _on_Mask2D_text_resize(tex_size: Vector2) -> void:
	tex_size_label.text = "Texture Size:  {0} x {1}".format([int(tex_size.x), int(tex_size.y)])


func _on_ToolButton_toggled(button_pressed: bool) -> void:
	if mask2d:
		mask2d.emit_signal("debug", button_pressed)


func _on_CaptureButton_button_down() -> void:
	if mask2d:
		mask2d.emit_signal("capture")
		print("Capture")
