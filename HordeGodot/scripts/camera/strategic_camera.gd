class_name StrategicCamera
extends Node3D

const PERSPECTIVE_FOV: float = 42.0

@export var pan_speed: float = 18.0
@export var zoom_speed: float = 3.5
@export var min_zoom: float = 6.0
@export var max_zoom: float = 24.0
@export var default_zoom: float = 14.0
@export var pitch_angle: float = 54.0

var camera: Camera3D
var target_position: Vector3 = Vector3.ZERO
# Both projections share an equivalent perspective distance, in world units.
var target_zoom: float = 14.0
var current_zoom: float = 14.0
var orthographic_distance: float = 14.0
var _applied_distance: float = 14.0

var is_dragging: bool = false
var drag_start_mouse_pos: Vector2 = Vector2.ZERO
var drag_start_cam_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	min_zoom = maxf(min_zoom, 1.0)
	max_zoom = maxf(max_zoom, min_zoom)
	default_zoom = clampf(default_zoom, min_zoom, max_zoom)
	target_zoom = default_zoom
	current_zoom = default_zoom
	target_position = position
	_setup_camera()

func _setup_camera() -> void:
	camera = Camera3D.new()
	camera.name = "MainCamera3D"
	camera.current = true
	camera.fov = PERSPECTIVE_FOV
	camera.near = 0.5
	camera.far = 200.0
	camera.position.z = current_zoom
	_applied_distance = current_zoom
	add_child(camera)
	rotation_degrees.x = -pitch_angle
	_update_camera_transform()

func _process(dt: float) -> void:
	_handle_keyboard_pan(dt)
	position = position.lerp(target_position, clampf(dt * 10.0, 0.0, 1.0))
	current_zoom = lerpf(current_zoom, target_zoom, clampf(dt * 12.0, 0.0, 1.0))
	_update_camera_transform()

func _update_camera_transform() -> void:
	if not is_instance_valid(camera):
		return
	camera.fov = PERSPECTIVE_FOV
	if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		# Match the perspective footprint at the tracked plane. Parallel rays
		# require changing size; the camera stays stationary while zooming.
		var offset_z: float = camera.position.z - _applied_distance
		camera.size = maxf(0.1, current_zoom + offset_z) * 2.0 * tan(deg_to_rad(PERSPECTIVE_FOV * 0.5))
	else:
		# Apply only the zoom delta so custom translation, rotation and lens
		# offsets survive. Returning after ortho zoom uses its equivalent dolly.
		camera.position.z += current_zoom - _applied_distance
		_applied_distance = current_zoom

func toggle_projection() -> void:
	if not is_instance_valid(camera):
		return
	if camera.projection == Camera3D.PROJECTION_PERSPECTIVE:
		orthographic_distance = camera.position.z
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_update_camera_transform()

func _handle_keyboard_pan(dt: float) -> void:
	if is_dragging:
		return
	var move_vec: Vector2 = Input.get_vector("camera_pan_left", "camera_pan_right", "camera_pan_up", "camera_pan_down")
	if move_vec != Vector2.ZERO:
		var pan_factor: float = (current_zoom / default_zoom) * pan_speed * dt
		target_position.x += move_vec.x * pan_factor
		target_position.z += move_vec.y * pan_factor
		_clamp_target()

func _clamp_target() -> void:
	target_position.x = clampf(target_position.x, -14.0, 16.0)
	target_position.z = clampf(target_position.z, -16.0, 14.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		toggle_projection()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_zoom = clampf(target_zoom - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_zoom = clampf(target_zoom + zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = event.pressed
			if is_dragging:
				drag_start_mouse_pos = event.position
				drag_start_cam_pos = target_position
	elif event is InputEventMouseMotion and is_dragging:
		var delta_mouse: Vector2 = event.position - drag_start_mouse_pos
		var drag_factor: float = 0.022 * (current_zoom / default_zoom)
		target_position.x = drag_start_cam_pos.x - delta_mouse.x * drag_factor
		target_position.z = drag_start_cam_pos.z - delta_mouse.y * drag_factor * 1.2
		_clamp_target()

func focus_on(target_pos: Vector3, new_zoom: float = -1.0) -> void:
	target_position = Vector3(target_pos.x, 0, target_pos.z)
	if new_zoom > 0:
		target_zoom = clampf(new_zoom, min_zoom, max_zoom)
