extends Node2D


onready var icon := $icon
onready var terrain := $Terrain
onready var viewport_container := $Viewport/ViewportContainer
onready var viewport := viewport_container.get_node("Viewport")
onready var particle := $Mask2DParticle
onready var draw_canvas_cbx := $Gui/VBoxContainer/DrawCanvasCbx
onready var draw_custom_canvas_cbx := $Gui/VBoxContainer/DrawCustomCanvasCbx
onready var draw_with_viewport_texture_cbx := $Gui/VBoxContainer/DrawWithViewportTextureCbx

var image: Image
var btn_group := ButtonGroup.new()


func _ready() -> void:
	draw_canvas_cbx.group = btn_group
	draw_custom_canvas_cbx.group = btn_group
	draw_with_viewport_texture_cbx.group = btn_group

	image = icon.texture.get_data()


func _process(_delta: float) -> void:
	if btn_group.get_pressed_button().name in [draw_canvas_cbx.name, draw_custom_canvas_cbx.name]:
		icon.global_position = get_global_mouse_position()
	else:
		particle.global_position = get_global_mouse_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.is_action_pressed("ui_click"):
				match btn_group.get_pressed_button().name:
					draw_canvas_cbx.name:
						call_deferred("_draw_canvas")
					draw_custom_canvas_cbx.name:
						call_deferred("_draw_custom_canvas")
					draw_with_viewport_texture_cbx.name:
						particle.restart()
						particle.emitting = true
						call_deferred("_draw_with_viewport_texture")


func _draw_canvas() -> void:
	terrain.get_node("Mask2D").emit_signal("draw_canvas", image, icon.global_position)


func _draw_custom_canvas() -> void:
	var canvas = Sprite.new()
	var timer = Timer.new()
	var tween = Tween.new()
	terrain.add_child(canvas)
	canvas.add_child(timer)
	canvas.add_child(tween)
	timer.start(2)
	timer.connect("timeout", self, "_on_Timer_timeout", [canvas, tween])
	terrain.get_node("Mask2D").emit_signal("draw_custom_canvas", image, icon.global_position, canvas)


func _draw_with_viewport_texture() -> void:
	if particle.emitting:
		var particle_viewport: CPUParticles2D = particle.duplicate()
		viewport.add_child(particle_viewport)
		particle_viewport.restart()
		particle_viewport.position = (viewport.size / 2)

		yield(VisualServer,"frame_post_draw")
		yield(get_tree().create_timer(0.1), "timeout")
		var viewport_image: Image = viewport.get_texture().get_data()
		terrain.get_node("Mask2D").emit_signal("draw_canvas", viewport_image, get_global_mouse_position())
		particle_viewport.queue_free()


func _on_Timer_timeout(canvas: Sprite, tween: Tween) -> void:
	tween.interpolate_property(canvas, "modulate:a", canvas.modulate.a, 0.0, 0.5, Tween.TRANS_BACK, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	canvas.queue_free()


func _on_Button_button_down() -> void:
	terrain.get_node("Mask2D").emit_signal("reset_canvas")
