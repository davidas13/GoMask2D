tool
extends EditorPlugin

const COLOR := {
	"parent_line": Color("1e73e1"),
	"child_line": Color("ffd166"),
	"parent_anchor": Color("ffb703"),
	"child_anchor": Color("fb8500")
}
const CaptureInspector := preload("res://addons/gomask2d/scenes/CaptureInspector.gd")
const Mask2D := preload("res://addons/gomask2d/Mask2D.gd")

var mask2d: Mask2D
var _mask2d_name := "Mask2D"
var _plugin_name := "GoMask2D"
var _capture_inspector := CaptureInspector.new()
var _debug_achor_size := 4.0
var _debug_line_size := 2.0


func _enter_tree() -> void:
	add_custom_type(_mask2d_name, "Light2D", preload("res://addons/gomask2d/Mask2D.gd"), preload("res://addons/gomask2d/mask.png"))
	add_inspector_plugin(_capture_inspector)


func _exit_tree() -> void:
	remove_custom_type(_mask2d_name)
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
	_on_draw_debug(overlay)


func _on_draw_debug(overlay: Control) -> void:
	var op_data = mask2d.op_data
	var is_debug = mask2d.is_debug
	if is_debug and op_data:
		var viewport_canvas_transform := mask2d.get_viewport_transform() * mask2d.get_canvas_transform()
		for n in op_data.childs:
			overlay.draw_line(
				viewport_canvas_transform * n.top_left, 
				viewport_canvas_transform * n.top_right,
				COLOR.child_line,
				_debug_line_size)
			overlay.draw_line(
				viewport_canvas_transform * n.bottom_left,
				viewport_canvas_transform * n.bottom_right, 
				COLOR.child_line, 
				_debug_line_size)
			overlay.draw_line(
				viewport_canvas_transform * n.top_left, 
				viewport_canvas_transform * n.bottom_left, 
				COLOR.child_line, 
				_debug_line_size)
			overlay.draw_line(
				viewport_canvas_transform * n.top_right, 
				viewport_canvas_transform * n.bottom_right, 
				COLOR.child_line, 
				_debug_line_size)
			for p in n.values():
				overlay.draw_circle(
					viewport_canvas_transform * p, 
					_debug_achor_size, 
					COLOR.child_anchor)
#
		overlay.draw_line(
			viewport_canvas_transform * op_data.parent.top_left,
			viewport_canvas_transform * op_data.parent.top_right, 
			COLOR.parent_line, 
			_debug_line_size)
		overlay.draw_line(
			viewport_canvas_transform * op_data.parent.bottom_left, 
			viewport_canvas_transform * op_data.parent.bottom_right, 
			COLOR.parent_line, 
			_debug_line_size)
		overlay.draw_line(
			viewport_canvas_transform * op_data.parent.top_left, 
			viewport_canvas_transform * op_data.parent.bottom_left, 
			COLOR.parent_line, 
			_debug_line_size)
		overlay.draw_line(
			viewport_canvas_transform * op_data.parent.top_right, 
			viewport_canvas_transform * op_data.parent.bottom_right, 
			COLOR.parent_line, 
			_debug_line_size)
#
		for p in op_data.parent.values():
			overlay.draw_circle(
				viewport_canvas_transform * p, 
				_debug_achor_size, 
				COLOR.parent_anchor)


func get_plugin_name() -> String:
	return _plugin_name

