extends EditorInspectorPlugin

const CaptureEditor := preload("res://addons/gomask2d/scenes/CaptureEditor.tscn")

const Mask2D := preload("res://addons/gomask2d/Mask2D.gd")


func can_handle(object: Object) -> bool:
	return object is Mask2D


func parse_category(object: Object, category: String) -> void:
	if category == "Script Variables":
		var capture_editor := CaptureEditor.instance()
		capture_editor.mask2d = object
		add_custom_control(capture_editor)
