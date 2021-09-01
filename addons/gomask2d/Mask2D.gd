tool
extends Light2D

signal capture
signal changes
signal tex_resize(tex_size)
signal debug(value)
signal draw_debug(overlay)

enum WARN_CODE {IS_PARENT, IS_SELF, IS_EMPTY}
const COLOR = {
	"parent_line": Color("b966f1"),
	"child_line": Color("ed6790"),
	"parent_anchor": Color("6200fd"),
	"child_anchor": Color("fb001d")
}
const default_tex_path := "res://addons/gomask2d/_mask_textures/"

export(NodePath) var object_container setget set_object_container
export(String) var texture_name setget set_texture_name
export(String, DIR) var texture_path = default_tex_path setget set_texture_path

var _is_debug := false
var _object_container : Node2D
var _current_tex_size: Vector2 = Vector2.ZERO
var _temp_child_nodes := []
var _debug_achor_size := 2.0
var _debug_line_size := 1.0
var _child_node: Node
var _draw_node: Node2D
var _op_data: Dictionary
var _dir = Directory.new()


func set_object_container(value: NodePath) -> void:
	update_configuration_warning()
	if _object_container and _object_container.get_child_count():
		for c in _object_container.get_children():
			remove_meta("_linked_gomask2d_")

	object_container = value
	if get_node_or_null(object_container) and get_node(object_container) != get_parent() and get_node(object_container) != self:
		_object_container = get_node(object_container)
		for c in _object_container.get_children():
			c.set_meta("_linked_gomask2d_", true)
	else:
		_object_container = null
	emit_signal("changes")


func set_texture_name(value: String) -> void:
	texture_name = value
	emit_signal("changes")
	

func set_texture_path(value: String) -> void:
	texture_path = value
	if texture_path == "" or not _dir.dir_exists(texture_path):
		texture_path = default_tex_path


func _enter_tree() -> void:
	mode = MODE_MIX
	set_meta("_edit_lock_", true)


func _get_configuration_warning() -> String:
	match _check_object_container():
		WARN_CODE.IS_EMPTY:
			return "Object Container has no children"
		WARN_CODE.IS_PARENT:
			return "Don't use parent node"
		WARN_CODE.IS_SELF:
			return "Don't use self node"
	if not texture_name:
		return "Texture Name is required"
	return ""


func _ready() -> void:
	if Engine.editor_hint:
		set_object_container(object_container)
		set_texture_name(texture_name)
		set_texture_path(texture_path)
		connect("debug", self, "_on_Mask2D_debug")
		connect("capture", self, "_on_Mask2D_capture")
		connect("draw_debug", self, "_on_Mask2D_draw_debug")
	else:
		set_process(false)


func _process(_delta: float) -> void:
	if Engine.editor_hint:
		if _object_container and _object_container.get_child_count():
			if not _child_node and not _draw_node:
				_setup_child_node()
			_op_data = _object_position_data()

			if _op_data:
				_current_tex_size = _op_data.parent.bottom_right - _op_data.parent.top_left
				emit_signal("tex_resize", _current_tex_size)
				global_position = _op_data.parent.top_left
				if texture:
					offset = texture.get_size() / 2


func _object_position_data() -> Dictionary:
	var children_nodes := _object_container.get_children()
	var child_transforms := []
	var parent_transform := {}
	var parent_pos_x_pools := []
	var parent_pos_y_pools := []

	for cn in children_nodes:
		var p_data
		if cn is Sprite:
			p_data = _get_sprite_pos_data(cn)
		elif cn is Polygon2D:
			p_data = _get_polygon_pos_data(cn, cn.polygon)
		elif cn is Path2D:
			p_data = _get_curve_pos_data(cn, cn.curve)
		elif cn is Line2D:
			p_data = _get_points_pos_data(cn, cn.points)
		elif "SS2D_Shape_Closed" in cn.name:
				p_data = _get_curve_pos_data(cn, cn._curve)
		elif cn is Node2D and cn.get_child_count():
			var childs = cn.get_children()
			if not childs.empty():
				for c in childs:
					if c is Sprite:
						var st = _get_sprite_pos_data(c)

						parent_pos_x_pools.push_back(st.pos_x_left)
						parent_pos_x_pools.push_back(st.pos_x_right)
						parent_pos_y_pools.push_back(st.pos_y_top)
						parent_pos_y_pools.push_back(st.pos_y_bottom)
						
						child_transforms.push_back({
							"top_left": Vector2(st.pos_x_left, st.pos_y_top),
							"top_right": Vector2(st.pos_x_right, st.pos_y_top),
							"bottom_left": Vector2(st.pos_x_left, st.pos_y_bottom),
							"bottom_right": Vector2(st.pos_x_right, st.pos_y_bottom)
						})
		if p_data:
			parent_pos_x_pools.push_back(p_data.pos_x_left)
			parent_pos_x_pools.push_back(p_data.pos_x_right)
			parent_pos_y_pools.push_back(p_data.pos_y_top)
			parent_pos_y_pools.push_back(p_data.pos_y_bottom)

			child_transforms.push_back({
				"top_left": Vector2(p_data.pos_x_left, p_data.pos_y_top),
				"top_right": Vector2(p_data.pos_x_right, p_data.pos_y_top),
				"bottom_left": Vector2(p_data.pos_x_left, p_data.pos_y_bottom),
				"bottom_right": Vector2(p_data.pos_x_right, p_data.pos_y_bottom)
			})

	if not parent_pos_x_pools.empty() and not parent_pos_y_pools.empty():
		var parent_pos_x_left = parent_pos_x_pools.min()
		var parent_pos_x_right = parent_pos_x_pools.max()
		var parent_pos_y_top = parent_pos_y_pools.min()
		var parent_pos_y_bottom = parent_pos_y_pools.max()
		
		parent_transform = {
			"top_left": Vector2(parent_pos_x_left, parent_pos_y_top),
			"top_right": Vector2(parent_pos_x_right, parent_pos_y_top),
			"bottom_left": Vector2(parent_pos_x_left, parent_pos_y_bottom),
			"bottom_right": Vector2(parent_pos_x_right, parent_pos_y_bottom)
		}

	return {"parent": parent_transform, "childs": child_transforms}


func _setup_child_node() -> void:
	_child_node = Node.new()
	add_child(_child_node)


func _get_sprite_pos_data(node: Sprite) -> Dictionary:
	var rect_size := Vector2(node.get_rect().size.x * node.scale.x, node.get_rect().size.y * node.scale.y)
	var pos_x_left: float
	var pos_x_right: float
	var pos_y_top: float
	var pos_y_bottom: float
	
	if node.centered:
		pos_x_left = (node.global_position.x + node.offset.x) - (rect_size.x / 2)
		pos_x_right = (node.global_position.x + node.offset.x) + (rect_size.x / 2)
		pos_y_top = (node.global_position.y + node.offset.y) - (rect_size.y / 2)
		pos_y_bottom = (node.global_position.y + node.offset.y) + (rect_size.y / 2)
	else:
		pos_x_left = (node.global_position.x + node.offset.x) - Vector2.ZERO.x
		pos_x_right = (node.global_position.x + node.offset.x) + (rect_size.x)
		pos_y_top = (node.global_position.y + node.offset.y) - Vector2.ZERO.y
		pos_y_bottom = (node.global_position.y + node.offset.y) + (rect_size.y)

	return {
		"pos_x_left": pos_x_left,
		"pos_x_right": pos_x_right,
		"pos_y_top": pos_y_top,
		"pos_y_bottom": pos_y_bottom
	}


func _get_points_pos_data(node: Node2D, points: PoolVector2Array) -> Dictionary:
	var pos_x_pool := []
	var pos_y_pool := []
	var pos_x_left: float
	var pos_x_right: float
	var pos_y_top: float
	var pos_y_bottom: float
	
	for bk in points:
		if bk:
			pos_x_pool.push_back(node.global_position.x + bk.x * node.scale.x)
			pos_y_pool.push_back(node.global_position.y + bk.y * node.scale.y)
	
	if not pos_x_pool.empty() and not pos_y_pool.empty():
		pos_x_left = pos_x_pool.min()
		pos_x_right = pos_x_pool.max()
		pos_y_top = pos_y_pool.min()
		pos_y_bottom = pos_y_pool.max()
	
	return {
		"pos_x_left": pos_x_left,
		"pos_x_right": pos_x_right,
		"pos_y_top": pos_y_top,
		"pos_y_bottom": pos_y_bottom
	}


func _get_polygon_pos_data(node: Polygon2D, polygon: PoolVector2Array) -> Dictionary:
	var pt = _get_points_pos_data(node, polygon).duplicate()
	pt.pos_x_left += node.offset.x
	pt.pos_x_right += node.offset.x
	pt.pos_y_top += node.offset.y
	pt.pos_y_bottom += node.offset.y
	return pt


func _get_curve_pos_data(node: Node2D, curve: Curve2D) -> Dictionary:
	var baked_points := curve.get_baked_points()
	return _get_points_pos_data(node, baked_points)


func _get_all_children(node: Node2D) -> void:
	for n in node.get_children():
		_temp_child_nodes.append(n)
		_get_all_children(n)


func _check_object_container() -> int:
	if object_container:
		if get_node(object_container) == get_parent():
			return WARN_CODE.IS_PARENT
		elif get_node(object_container) == self:
			return WARN_CODE.IS_SELF
		elif get_node(object_container).get_child_count() == 0:
			return WARN_CODE.IS_EMPTY
	return -1


func _hide_all_collision(node: Node) -> void:
	_get_all_children(node)
	for i in _temp_child_nodes:
		if i is CollisionShape2D or i is CollisionPolygon2D or i is RayCast2D:
			i.visible = false
	_temp_child_nodes = []


func _on_Mask2D_draw_debug(overlay: Control) -> void:
	if _is_debug and _op_data:
		var viewport_canvas_transform := get_viewport_transform() * get_canvas_transform()

		for n in _op_data.childs:
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
			viewport_canvas_transform * _op_data.parent.top_left,
			viewport_canvas_transform * _op_data.parent.top_right, 
			COLOR.parent_line, 
			_debug_line_size)
		overlay.draw_line(
			viewport_canvas_transform * _op_data.parent.bottom_left, 
			viewport_canvas_transform * _op_data.parent.bottom_right, 
			COLOR.parent_line, 
			_debug_line_size)
		overlay.draw_line(
			viewport_canvas_transform * _op_data.parent.top_left, 
			viewport_canvas_transform * _op_data.parent.bottom_left, 
			COLOR.parent_line, 
			_debug_line_size)
		overlay.draw_line(
			viewport_canvas_transform * _op_data.parent.top_right, 
			viewport_canvas_transform * _op_data.parent.bottom_right, 
			COLOR.parent_line, 
			_debug_line_size)
#
		for p in _op_data.parent.values():
			overlay.draw_circle(
				viewport_canvas_transform * p, 
				_debug_achor_size, 
				COLOR.parent_anchor)


func _on_Mask2D_debug(value: bool) -> void:
	_is_debug = value


func _on_Mask2D_capture() -> void:
	if Engine.editor_hint and _object_container and texture_name and _op_data and _child_node:
		var viewport_container : ViewportContainer = preload("res://addons/gomask2d/ViewportContainer.tscn").instance()
		var viewport: Viewport = viewport_container.get_node("Viewport")
		var scn: Node2D = _object_container.duplicate()

		_hide_all_collision(scn)

		_child_node.add_child(viewport_container)
		
		scn.visible = true
		viewport_container.rect_position = _op_data.parent.top_left
		viewport_container.rect_size = _current_tex_size
		
		var viewport_container2 = viewport_container.duplicate()
		viewport.add_child(viewport_container2)
		viewport_container2.rect_position = Vector2.ZERO
		viewport_container2.rect_size = viewport_container.rect_size

		viewport_container2.get_node("Viewport").add_child(scn)
		scn.global_position = Vector2(
			_object_container.global_position.x - viewport_container.rect_global_position.x,
			_object_container.global_position.y - viewport_container.rect_global_position.y
			)

		yield(VisualServer, "frame_post_draw")
		var img = viewport.get_texture().get_data()
		img.fix_alpha_edges()
		var img_file = "{0}/{1}.png".format([texture_path, texture_name])
		img.flip_y()
		img.save_png(img_file)
		var tex = ImageTexture.new()
		tex.create_from_image(img)
		texture = tex
		texture = texture
		if texture:
			offset = texture.get_size() / 2
		yield(get_tree().create_timer(1), "timeout")
		_child_node.remove_child(viewport_container)
		viewport_container.queue_free()
