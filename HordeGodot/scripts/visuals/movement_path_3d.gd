class_name MovementPath3D
extends Node3D

var path_mesh: MeshInstance3D
var arrow_marker: Node3D
var active: bool = false
var anim_time: float = 0.0

var mat_move: StandardMaterial3D
var mat_attack: StandardMaterial3D

func _ready():
	_init_materials()
	
	path_mesh = MeshInstance3D.new()
	path_mesh.name = "PathMesh"
	add_child(path_mesh)
	
	arrow_marker = Node3D.new()
	arrow_marker.name = "ArrowMarker"
	add_child(arrow_marker)
	
	visible = false

func _init_materials():
	mat_move = StandardMaterial3D.new()
	mat_move.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_move.albedo_color = Color(0.25, 0.85, 0.35, 0.85)
	
	mat_attack = StandardMaterial3D.new()
	mat_attack.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_attack.albedo_color = Color(0.95, 0.25, 0.15, 0.95)

func _process(delta: float):
	if visible and active:
		anim_time += delta
		# Subtle pulsation of target marker
		if arrow_marker:
			arrow_marker.position.y = 0.3 + sin(anim_time * 6.0) * 0.12

func show_path(start_pos: Vector3, end_pos: Vector3, is_attack: bool = false):
	if arrow_marker == null:
		_ready()
	visible = true
	active = true
	
	# Clear old marker
	for child in arrow_marker.get_children():
		child.queue_free()
		
	var dir = end_pos - start_pos
	var dist = dir.length()
	var mid = (start_pos + end_pos) * 0.5
	
	# Create road path beam
	var box = BoxMesh.new()
	box.size = Vector3(0.4, 0.06, dist * 0.82)
	path_mesh.mesh = box
	path_mesh.material_override = mat_attack if is_attack else mat_move
	path_mesh.position = Vector3(mid.x, 0.1, mid.z)
	path_mesh.rotation.y = atan2(dir.x, dir.z)
	
	# Create Target Marker at destination (Floating Diamond / Ring)
	var marker_mesh = MeshInstance3D.new()
	var t_mesh = TorusMesh.new()
	t_mesh.inner_radius = 0.55
	t_mesh.outer_radius = 0.75
	t_mesh.rings = 12
	t_mesh.ring_segments = 4
	marker_mesh.mesh = t_mesh
	marker_mesh.material_override = mat_attack if is_attack else mat_move
	
	arrow_marker.position = Vector3(end_pos.x, 0.3, end_pos.z)
	arrow_marker.add_child(marker_mesh)

func hide_path():
	visible = false
	active = false
