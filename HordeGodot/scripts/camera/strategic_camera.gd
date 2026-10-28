class_name StrategicCamera
extends Node3D

@export var pan_speed: float = 18.0
@export var zoom_speed: float = 3.5
@export var min_zoom: float = 6.0
@export var max_zoom: float = 24.0
@export var default_zoom: float = 14.0
@export var pitch_angle: float = 54.0

var camera: Camera3D
var target_position: Vector3 = Vector3(0, 0, 0)
var target_zoom: float = 14.0
var current_zoom: float = 14.0

var is_dragging: bool = false
var drag_start_mouse_pos: Vector2 = Vector2.ZERO
var drag_start_cam_pos: Vector3 = Vector3.ZERO

func _ready():
	target_zoom = default_zoom
	current_zoom = default_zoom
	_setup_camera()

func _setup_camera():
	camera = Camera3D.new()
	camera.name = "MainCamera3D"
	camera.current = true
	camera.fov = 42.0
	camera.near = 0.5
	camera.far = 200.0
	add_child(camera)
	
	rotation_degrees.x = -pitch_angle
	_update_camera_transform()

func _process(dt: float):
	_handle_keyboard_pan(dt)
	
	# Smoothly interpolate position and zoom
	position = position.lerp(target_position, clamp(dt * 10.0, 0.0, 1.0))
	current_zoom = lerp(current_zoom, target_zoom, clamp(dt * 12.0, 0.0, 1.0))
	_update_camera_transform()

func _update_camera_transform():
	if camera:
		camera.position = Vector3(0, 0, current_zoom)

func _handle_keyboard_pan(dt: float):
	if is_dragging:
		return
		
	var move_vec = Vector2.ZERO
	if Input.is_action_pressed("camera_pan_up"):
		move_vec.y -= 1.0
	if Input.is_action_pressed("camera_pan_down"):
		move_vec.y += 1.0
	if Input.is_action_pressed("camera_pan_left"):
		move_vec.x -= 1.0
	if Input.is_action_pressed("camera_pan_right"):
		move_vec.x += 1.0
		
	if move_vec != Vector2.ZERO:
		move_vec = move_vec.normalized()
		var pan_factor = (current_zoom / default_zoom) * pan_speed * dt
		target_position.x += move_vec.x * pan_factor
		target_position.z += move_vec.y * pan_factor
		
		# Clamp within bounds of map
		target_position.x = clamp(target_position.x, -14.0, 16.0)
		target_position.z = clamp(target_position.z, -16.0, 14.0)

func _unhandled_input(event: InputEvent):
	# Mouse Wheel Zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_zoom = clamp(target_zoom - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_zoom = clamp(target_zoom + zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_dragging = true
				drag_start_mouse_pos = event.position
				drag_start_cam_pos = target_position
			else:
				is_dragging = false
				
	# Mouse Drag Panning
	elif event is InputEventMouseMotion and is_dragging:
		var delta_mouse = event.position - drag_start_mouse_pos
		var drag_factor = 0.022 * (current_zoom / default_zoom)
		target_position.x = drag_start_cam_pos.x - delta_mouse.x * drag_factor
		target_position.z = drag_start_cam_pos.z - delta_mouse.y * drag_factor * 1.2
		
		target_position.x = clamp(target_position.x, -14.0, 16.0)
		target_position.z = clamp(target_position.z, -16.0, 14.0)

func focus_on(target_pos: Vector3, new_zoom: float = -1.0):
	target_position = Vector3(target_pos.x, 0, target_pos.z)
	if new_zoom > 0:
		target_zoom = clamp(new_zoom, min_zoom, max_zoom)
