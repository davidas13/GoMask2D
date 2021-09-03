tool
extends EditorPlugin

const CaptureInspector := preload("res://addons/gomask2d/scenes/CaptureInspector.gd")
const Mask2D := preload("res://addons/gomask2d/Mask2D.gd")

var mask2d: Mask2D
var _node_name := "Mask2D"
var _plugin_name := "Go Mask"
var _capture_inspector := CaptureInspector.new()


func _enter_tree() -> void:
	add_custom_type(_node_name, "Light2D", preload("res://addons/gomask2d/Mask2D.gd"), preload("res://addons/gomask2d/icon.png"))
	add_inspector_plugin(_capture_inspector)


func _exit_tree() -> void:
	remove_custom_type(_node_name)
	remove_inspector_plugin(_capture_inspector)


func edit(object: Object) -> void:
	if object is Mask2D:
		mask2d = object
		mask2d.set_meta("_edit_lock_", true)


func handles(object: Object) -> bool:
	if object is Mask2D or object is Node2D:
		return true
	return false


func forward_canvas_draw_over_viewport(overlay: Control) -> void:
	if not is_instance_valid(mask2d) or not mask2d.is_inside_tree():
		return
	mask2d.emit_signal("draw_debug", overlay)


func get_plugin_name() -> String:
	return _plugin_name

