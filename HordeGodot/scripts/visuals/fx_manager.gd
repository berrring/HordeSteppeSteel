class_name FXManager
extends RefCounted

const ModelBuilder = preload("res://scripts/visuals/model_builder.gd")

# Spawns a subtle low-poly dust puff upon army arrival or marching
static func spawn_dust_puff(parent: Node3D, pos: Vector3):
	var dust_node = Node3D.new()
	dust_node.position = pos + Vector3(0, 0.1, 0)
	parent.add_child(dust_node)
	
	var mat_dust = ModelBuilder.get_mat("dirt_road")
	var ring = MeshInstance3D.new()
	var t_mesh = TorusMesh.new()
	t_mesh.inner_radius = 0.3
	t_mesh.outer_radius = 0.45
	t_mesh.rings = 8
	t_mesh.ring_segments = 4
	ring.mesh = t_mesh
	ring.material_override = mat_dust
	dust_node.add_child(ring)
	
	var tw = dust_node.create_tween()
	tw.tween_property(dust_node, "scale", Vector3(2.2, 1.0, 2.2), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ring, "material_override:albedo_color:a", 0.0, 0.45)
	tw.tween_callback(dust_node.queue_free)

# Spawns floating 3D text (e.g. "+50 Gold", "Captured!", "Fortified")
static func spawn_floating_text(parent: Node3D, pos: Vector3, text: String, color: Color = Color(1.0, 0.88, 0.3)):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.position = pos + Vector3(0, 1.5, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.font_size = 32
	lbl.outline_size = 8
	lbl.outline_modulate = Color(0.1, 0.05, 0.02)
	lbl.modulate = color
	parent.add_child(lbl)
	
	var tw = lbl.create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector3(0, 1.4, 0), 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.1)
	tw.tween_callback(lbl.queue_free)
