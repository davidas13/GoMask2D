tool
extends Light2D

signal draw_canvas(image, dst_position)
signal draw_custom_canvas(image, dst_position, canvas)
signal draw_texture_canvas(texture_, dst_position, lifetime, rotation_, scale_, modulate_, normal_map)
signal draw_texture_custom_canvas(texture_, dst_position, canvas, lifetime, rotation_, scale_, modulate_, normal_map)
#signal draw_texture_spread_canvas(texture_, normal_map)
signal reset_canvas


enum WARN_CODE {IS_PARENT, IS_SELF, IS_EMPTY}

const default_tex_path := "res://addons/gomask2d/_mask_textures/"

export(NodePath) var object_container setget set_object_container
export(String) var texture_name setget set_texture_name
export(String, DIR) var texture_path = default_tex_path setget set_texture_path

var is_debug := false
var is_capturing := false
var op_data: Dictionary
var object_container_node : Node2D
var _temp_child_nodes := []
var _child_node: Node
var _canvas_node: Sprite
var _texture_canvas_node: Node2D
var _dir := Directory.new()
var _canvases := []
var _draw_texture_canvas_datas := []
var _draw_texture_custom_canvas_datas := []


# Draw Runtime Group
var draw_activate: bool = false setget set_draw_activate
var draw_centered: bool = true setget set_draw_centered
var draw_global_coordinate: bool = true setget set_draw_global_coordinate
var draw_auto_crop: bool = false setget set_draw_auto_crop
var draw_crop_expand: float = 1.0 setget set_draw_crop_expand

# Draw Texture Runtime
var draw_texture_activate: bool = false
var draw_texture_centered: bool = true
var draw_texture_global_coordinate: bool = true
var draw_texture_default_lifetime: float = 3
var draw_texture_default_fadetime: float = 1
var draw_texture_max_applied: int = 100


const WARN_MSG = {
	"draw": "The signal '{0}' cannot be emitted, because export var '{1}' is unchecked",
	"draw_tex_max": "The maximum number of textures has been applied: {0}"
}


func _get_property_list():
	return [
		# Draw Runtime Group
		{
			"name": "Draw Runtime",
			"type": TYPE_NIL,
			"hint_string": "draw_",
			"usage": PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			"name": "draw_activate",
			"type": TYPE_BOOL,
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_NONE,
		},
		{
			"name": "draw_centered",
			"type": TYPE_BOOL,
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_NONE,
		},
		{
			"name": "draw_global_coordinate",
			"type": TYPE_BOOL,
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_NONE,
		},
		{
			"name": "draw_auto_crop",
			"type": TYPE_BOOL,
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_NONE,
		},
		{
			"name": "draw_crop_expand",
			"type": TYPE_REAL,
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0.1,10.0,0.1"
		},
		# Draw Texture Runtime Group
		{
			"name": "Draw Texture Runtime",
			"type": TYPE_NIL,
			"hint_string": "draw_texture_",
			"usage": PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			"name": "draw_texture_activate",
			"type": TYPE_BOOL,
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_NONE,
		},
		{
			"name": "draw_texture_centered",
			"type": TYPE_BOOL,
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_NONE,
		},
		{
			"name": "draw_texture_global_coordinate",
			"type": TYPE_BOOL,
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_NONE,
		},
		{
			"name": "draw_texture_default_lifetime",
			"type": TYPE_REAL,
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "1.0,30.0,0.1"
		},
		{
			"name": "draw_texture_default_fadetime",
			"type": TYPE_REAL,
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0.1,10.0,0.1"
		},
		{
			"name": "draw_texture_max_applied",
			"type": TYPE_INT,
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "1,300,1"
		}
	]


func set_object_container(value: NodePath) -> void:
	update_configuration_warning()
	object_container = value
	if get_node_or_null(object_container) and get_node(object_container) != get_parent() and get_node(object_container) != self:
		object_container_node = get_node(object_container)
	else:
		object_container_node = null
	property_list_changed_notify()


func set_texture_name(value: String) -> void:
	texture_name = value
	property_list_changed_notify()
	

func set_texture_path(value: String) -> void:
	texture_path = value
	if texture_path == "" or not _dir.dir_exists(texture_path):
		texture_path = default_tex_path
	property_list_changed_notify()


func set_draw_activate(value: bool) -> void:
	draw_activate = value
	property_list_changed_notify()


func set_draw_centered(value: bool) -> void:
	draw_centered = value
	property_list_changed_notify()


func set_draw_global_coordinate(value: bool) -> void:
	draw_global_coordinate = value
	property_list_changed_notify()


func set_texture(value: Texture) -> void:
	texture = texture
	property_list_changed_notify()


func set_draw_auto_crop(value: bool) -> void:
	draw_auto_crop = value
	property_list_changed_notify()


func set_draw_crop_expand(value: float) -> void:
	draw_crop_expand = value
	property_list_changed_notify()


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
	else:
		if is_visible_in_tree():
			if draw_activate:
				_canvas_node = Sprite.new()
				_canvas_node.position = Vector2.ZERO
				add_child(_canvas_node)
				_setup_draw_canvas_node(_canvas_node)
			if draw_texture_activate:
				_texture_canvas_node = Node2D.new()
				_texture_canvas_node.position = Vector2.ZERO
				add_child(_texture_canvas_node)
				_setup_draw_texture_canvas_node(_texture_canvas_node)
				_texture_canvas_node.connect("draw", self, "_on_Mask2D_draw")

		connect("draw_canvas", self, "_on_Mask2D_draw_canvas")
		connect("draw_custom_canvas", self, "_on_Mask2D_draw_custom_canvas")
		connect("draw_texture_canvas", self, "_on_Mask2D_draw_texture_canvas")
		connect("draw_texture_custom_canvas", self, "_on_Mask2D_draw_texture_custom_canvas")
		connect("reset_canvas", self, "_on_Mask2D_reset_canvas")


func _process(_delta: float) -> void:
	if Engine.editor_hint:
		if is_instance_valid(object_container_node) and object_container_node.get_child_count():
			if not _child_node:
				_setup_child_node()
			op_data = _object_position_data()

			if op_data:
				global_position = op_data.parent.top_left
				if texture:
					offset = texture.get_size() / 2
	else:
		if not _canvases.empty():
			for c in _canvases:
				if is_instance_valid(c):
					c.global_position = global_position
				else:
					var idx := _canvases.find(c)
					_canvases.remove(idx)
	
	if draw_texture_activate:
		if not _draw_texture_canvas_datas.empty() or not _draw_texture_custom_canvas_datas.empty():
			if is_instance_valid(_texture_canvas_node):
				for dt in _draw_texture_canvas_datas:
					if is_instance_valid(dt.canvas):
						if is_instance_valid(dt.timer):
							if dt.timer.time_left < draw_texture_default_fadetime:
								dt.modulate.a = range_lerp(dt.timer.time_left, draw_texture_default_fadetime, 0.0, 1.0, 0.0)
								if dt.modulate.a < 0.0:
									_draw_texture_canvas_datas.erase(dt)
						else:
							_draw_texture_canvas_datas.erase(dt)
						
				_texture_canvas_node.update()


func _draw_texture() -> void:
	for dt in _draw_texture_canvas_datas:
		if dt.modulate.a > 0.0:
			dt.canvas.draw_set_transform(dt.dst_position, dt.rotation, dt.scale)
			dt.canvas.draw_texture(dt.texture, dt.tex_position, dt.modulate)


func _object_position_data() -> Dictionary:
	var children_nodes := object_container_node.get_children()
	var parent_pos_data := {}
	var child_pos_datas := []
	var parent_pos_x_pools := []
	var parent_pos_y_pools := []

	for cn in children_nodes:
		var p_data: Dictionary
		p_data = _child_position_data(cn)
		if not _check_SS2D_Shape_node(cn):
			for c in cn.get_children():
				p_data = _child_position_data(c)
				if not p_data.empty():
					parent_pos_x_pools.push_back(p_data.top_left.x)
					parent_pos_x_pools.push_back(p_data.top_right.x)
					parent_pos_y_pools.push_back(p_data.top_left.y)
					parent_pos_y_pools.push_back(p_data.bottom_left.y)
					child_pos_datas.append(p_data)
		if not p_data.empty():
			parent_pos_x_pools.push_back(p_data.top_left.x)
			parent_pos_x_pools.push_back(p_data.top_right.x)
			parent_pos_y_pools.push_back(p_data.top_left.y)
			parent_pos_y_pools.push_back(p_data.bottom_left.y)
			child_pos_datas.push_back(p_data)

	
	if not parent_pos_x_pools.empty() and not parent_pos_y_pools.empty():
		var parent_pos_x_left = parent_pos_x_pools.min()
		var parent_pos_x_right = parent_pos_x_pools.max()
		var parent_pos_y_top = parent_pos_y_pools.min()
		var parent_pos_y_bottom = parent_pos_y_pools.max()
		
		parent_pos_data = {
			"top_left": Vector2(parent_pos_x_left, parent_pos_y_top),
			"top_right": Vector2(parent_pos_x_right, parent_pos_y_top),
			"bottom_left": Vector2(parent_pos_x_left, parent_pos_y_bottom),
			"bottom_right": Vector2(parent_pos_x_right, parent_pos_y_bottom)
		}
		
	return {"parent": parent_pos_data, "childs": child_pos_datas}


func _child_position_data(node: Node2D) -> Dictionary:
	var position_data := {}

	if node is Sprite:
		position_data = _get_sprite_pos_data(node)
	elif node is Polygon2D:
		position_data = _get_points_position(node, node.polygon)
	elif node is Path2D:
		var baked_points : PoolVector2Array = node.curve.get_baked_points()
		position_data = _get_points_position(node, baked_points)
	elif node is Line2D:
		position_data = _get_points_position(node, node.points)
	elif _check_SS2D_Shape_node(node):
		var baked_points : PoolVector2Array = node._curve.get_baked_points()
		position_data = _get_points_position(node, baked_points)

	return position_data


func _check_SS2D_Shape_node(node: Node2D) -> bool:
	var ss2d_path = "res://addons/rmsmartshape"
	if node.get_script():
		if ss2d_path in node.get_script().get_path():
			return true
	return false


func _setup_child_node() -> void:
	_child_node = Node.new()
	add_child(_child_node)


func _setup_draw_canvas_node(canvas: Sprite) -> void:
	canvas.centered = false
	canvas.light_mask = range_item_cull_mask
	if not canvas.material:
		canvas.material = load("res://addons/gomask2d/materials/Canvas.material")
	if not canvas.texture:
		canvas.texture = _setup_draw_canvas_texture()


func _setup_draw_canvas_texture() -> ImageTexture:
	var _texture = ImageTexture.new()
	var _image = Image.new()
	_image.create(texture.get_size().x, texture.get_size().y, false, Image.FORMAT_RGBA8)
	_texture.create_from_image(_image)
	return _texture
	
	
func _setup_draw_texture_canvas_node(canvas: Node2D) -> void:
	canvas.light_mask = range_item_cull_mask
	if not canvas.material:
		canvas.material = load("res://addons/gomask2d/materials/Canvas.material")


func _draw_canvas(image: Image, dst_position: Vector2, canvas: Sprite) -> void:
	if draw_activate:
		var image_size := image.get_size()
		var canvas_image := canvas.texture.get_data()
#		VisualServer.force_draw()
		yield(VisualServer, "frame_post_draw")
		if draw_auto_crop:
			image = image.get_rect(image.get_used_rect().grow(draw_crop_expand))
			image_size = image.get_size()
		if draw_global_coordinate:
			dst_position -= canvas.global_position
		if draw_centered:
			dst_position -= image_size / 2
		canvas_image.blend_rect(image, Rect2(Vector2.ZERO , image_size), dst_position)
		VisualServer.texture_set_data(canvas.texture.get_rid(), canvas_image)
		return


func _get_sprite_pos_data(node: Sprite) -> Dictionary:
	var points := []
	var rect = Rect2(node.global_position, node.get_rect().size * node.scale)
	var pos_left_top: Vector2
	var pos_right_top: Vector2
	var pos_left_bottom: Vector2
	var pos_right_bottom: Vector2
	
	if node.centered:
		pos_left_top = Vector2(
			rect.position.x - (rect.size.x/2),
			rect.position.y - (rect.size.y/2)
		)
		pos_right_top = Vector2(
			rect.end.x - (rect.size.x/2),
			rect.position.y - (rect.size.y/2)
			) 
		pos_left_bottom = Vector2(
			rect.position.x - (rect.size.x/2),
			rect.end.y - (rect.size.y/2)
			) 
		pos_right_bottom = Vector2(
			rect.end.x - (rect.size.x/2),
			rect.end.y - (rect.size.y/2)
			)
	else:
		pos_left_top = rect.position
		pos_right_top = Vector2(
			rect.end.x,
			rect.position.y
			) 
		pos_left_bottom = Vector2(
			rect.position.x,
			rect.end.y
			) 
		pos_right_bottom = Vector2(
			rect.end.x,
			rect.end.y
			) 

	for p in [pos_left_top, pos_right_top, pos_left_bottom, pos_right_bottom]:
		points.push_back(p)
	
	return _get_points_position(node, points)


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


func _get_points_position(node: Node2D, points: PoolVector2Array) -> Dictionary:
	var pos_x_pool := []
	var pos_y_pool := []
	var min_x: float
	var max_x: float
	var min_y: float
	var max_y: float
	var parent_scale = Vector2.ZERO
	var _offset = Vector2.ZERO

	if node.get_parent().get("scale"):
		parent_scale = node.get_parent().scale

	if node.get("offset"):
		_offset = node.offset

	for point in points:
		if point:
			var p: Vector2
			if node is Sprite:
				p = point
			elif node is Polygon2D or node is Path2D or node is Line2D or _check_SS2D_Shape_node(node):
				p = node.global_position + point * node.scale
			point = _rotate_point(node.global_position, p, _offset, node.rotation)
			pos_x_pool.push_back(point.x)
			pos_y_pool.push_back(point.y)
	
	if not pos_x_pool.empty() and not pos_y_pool.empty():
		min_x = pos_x_pool.min()
		max_x = pos_x_pool.max()
		min_y = pos_y_pool.min()
		max_y = pos_y_pool.max()
	
	return {
		"top_left": Vector2(min_x, min_y),
		"top_right": Vector2(max_x, min_y),
		"bottom_left": Vector2(min_x, max_y),
		"bottom_right": Vector2(max_x, max_y)
	}


func _rotate_point(pivot, point, offset, angle):
	point = point + offset
	var x = round((cos(angle) * (point[0] - pivot[0])) - (sin(angle) * (point[1] - pivot[1])) + pivot[0])
	var y = round((sin(angle) * (point[0] - pivot[0])) + (cos(angle) * (point[1] - pivot[1])) + pivot[1])
	return Vector2(x, y)


#func _random_id() -> int:
#	randomize()
#	var nums := PoolStringArray([
#		String(randi() % 256), String(OS.get_ticks_usec())])
#	return int(nums.join(""))


func get_image_file() -> String:
	return "{0}/{1}.png".format([texture_path, texture_name])


func capture_mask() -> void:
	if Engine.editor_hint and object_container_node and texture_name and op_data and _child_node:
		is_capturing = true
		var viewport_container : ViewportContainer = preload("res://addons/gomask2d/ViewportContainer.tscn").instance()
		var viewport: Viewport = viewport_container.get_node("Viewport")
		var scn: Node2D = object_container_node.duplicate()

		_hide_all_collision(scn)

		_child_node.add_child(viewport_container)
		
		scn.visible = true
		viewport_container.rect_position = op_data.parent.top_left
		viewport_container.rect_size = op_data.parent.bottom_right - op_data.parent.top_left
		
		var viewport_container2 = viewport_container.duplicate()
		viewport.add_child(viewport_container2)
		viewport_container2.rect_position = Vector2.ZERO
		viewport_container2.rect_size = viewport_container.rect_size

		viewport_container2.get_node("Viewport").add_child(scn)
		scn.global_position = Vector2(
			object_container_node.global_position.x - viewport_container.rect_global_position.x,
			object_container_node.global_position.y - viewport_container.rect_global_position.y
			)

		yield(VisualServer, "frame_post_draw")
		var img = viewport.get_texture().get_data()
		var img_file = get_image_file()
		img.fix_alpha_edges()
		img.flip_y()
		img.save_png(img_file)
		var tex = ImageTexture.new()
		tex.create_from_image(img)
		texture = tex #load(img_file)
		if texture:
			offset = texture.get_size() / 2
		yield(get_tree().create_timer(1), "timeout")
		_child_node.remove_child(viewport_container)
		viewport_container.queue_free()
		is_capturing = false

func _on_Mask2D_draw_canvas(image: Image, dst_position: Vector2) -> void:
	if not is_instance_valid(_canvas_node):
		push_warning(WARN_MSG.draw.format(["draw_canvas", "draw_activate"]))
		return
	_draw_canvas(image, dst_position, _canvas_node)


func _on_Mask2D_draw_custom_canvas(image: Image, dst_position: Vector2, canvas: Sprite) -> void:
	if not is_instance_valid(canvas):
		push_warning(WARN_MSG.draw.format(["draw_canvas", "draw_activate"]))
		return
	_setup_draw_canvas_node(canvas)
	_draw_canvas(image, dst_position, canvas)
	if not canvas in _canvases:
		_canvases.push_back(canvas)


func _on_Mask2D_draw_texture_canvas(texture_: Texture, dst_position: Vector2, lifetime: float = draw_texture_default_lifetime, rotation_: float = 0.0 , scale_: Vector2 = Vector2.ONE, modulate_: Color = Color.white, normal_map: Texture = null) -> void:
	if not is_instance_valid(_texture_canvas_node):
		push_warning(WARN_MSG.draw.format(["draw_texture_canvas", "draw_texture_activate"]))
		return
	if _draw_texture_canvas_datas.size() >= draw_texture_max_applied:
		push_warning(WARN_MSG.draw_tex_max.format([draw_texture_max_applied]))
		return
	var tex_position = Vector2.ZERO
	if draw_texture_global_coordinate:
		dst_position -= _texture_canvas_node.global_position
	if draw_texture_centered:
		tex_position -= (texture_.get_size() / 2)
	_draw_texture_canvas_datas.push_back({
		"texture": texture_,
		"dst_position": dst_position,
		"tex_position": tex_position,
		"lifetime": lifetime,
		"timer": get_tree().create_timer(lifetime),
		"rotation": rotation_,
		"scale": scale_,
		"modulate": modulate_,
		"canvas": _texture_canvas_node
	})


func _on_Mask2D_draw_texture_custom_canvas(texture_: Texture, dst_position: Vector2, canvas, lifetime: float = draw_texture_default_lifetime, rotation_: float = 0.0 , scale_: Vector2 = Vector2.ONE, modulate_: Color = Color.white, normal_map: Texture = null) -> void:
	if not is_instance_valid(canvas):
		push_warning(WARN_MSG.draw.format(["draw_texture_canvas", "draw_texture_activate"]))
		return


func _on_Mask2D_reset_canvas() -> void:
	_canvas_node.texture = _setup_draw_canvas_texture()


func _on_Mask2D_draw() -> void:
	_draw_texture()
