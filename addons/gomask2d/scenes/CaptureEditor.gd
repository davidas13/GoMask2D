tool
extends MarginContainer

const Mask2D := preload("res://addons/gomask2d/Mask2D.gd")

var mask2d: Mask2D
onready var capture_button := $VBoxContainer/HBoxContainer/CaptureButton
onready var debug_button := $VBoxContainer/HBoxContainer2/DebugButton
onready var swith_tex_button := $VBoxContainer/HBoxContainer2/SwitchTextureButton
onready var tex_size_label := $VBoxContainer/VBoxContainer/TexSizeLabel

func _ready() -> void:
	if mask2d:
		debug_button.pressed = mask2d.is_debug


func _toggle_disable_buttons() -> void:
	var is_enabled = mask2d and mask2d.object_container_node and \
	 mask2d.object_container_node.get_child_count() and mask2d.texture_name and not mask2d.is_capturing
	capture_button.disabled = not is_enabled
	debug_button.disabled = not is_enabled
	swith_tex_button.disabled = not is_enabled
	
	if not is_enabled:
		debug_button.pressed = not is_enabled


func _process(delta: float) -> void:
	if mask2d:
		_toggle_disable_buttons()
		if mask2d.op_data:
			var tex_size: Vector2 = mask2d.op_data.parent.bottom_right - mask2d.op_data.parent.top_left
			tex_size_label.text = "Texture Size:  {0} x {1}".format([int(tex_size.x), int(tex_size.y)])


func _on_ToolButton_toggled(button_pressed: bool) -> void:
	if mask2d:
		mask2d.is_debug = button_pressed


func _on_CaptureButton_button_down() -> void:
	if mask2d:
		mask2d.capture_mask()


func _on_SwitchTextureButton_button_down() -> void:
	if mask2d:
		var img_file := mask2d.get_image_file()
		var st = load(img_file)
		if st != null:
			if not mask2d.texture is StreamTexture or mask2d.texture.resource_path != img_file:
				mask2d.texture = st
				print("Successfully switched to 'StreamTexture'")
			else:
				print("Texture type already 'StreamTexture'")
				return
			return
		printerr("StreamTexture not available")
