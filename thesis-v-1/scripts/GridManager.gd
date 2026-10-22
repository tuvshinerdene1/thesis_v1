extends Node3D
class_name GridManager

@export var tile_size: float = 1.0

var tree_material: StandardMaterial3D
var leaf_material: StandardMaterial3D

var active_grid_objects: Dictionary = {}

func _ready():
	tree_material = StandardMaterial3D.new()
	tree_material.albedo_color = Color(0.55, 0.27, 0.07)
	
	leaf_material = StandardMaterial3D.new()
	leaf_material.albedo_color = Color(0.13, 0.7, 0.3)

func load_level(level: LevelData, character: GridCharacter):
	# clear previous level objects 
	for child in get_children():
		child.queue_free()
	active_grid_objects.clear()
	
	# parsing level data 
	for y in range(level.grid_data.size()):
		var row = level.grid_data[y]
		for x in range(row.size()):
			var cell_type = row[x]
			var grid_pos = Vector2i(x,y)
			var world_pos = Vector3(x * tile_size, tile_size*0.5, y * tile_size)
			
			if cell_type == 1: # Tree / obstacle
				_spawn_colored_cube(world_pos, tree_material)
				active_grid_objects[grid_pos] = "tree"
			elif cell_type == 2:
				_spawn_colored_cube(world_pos, leaf_material)
				active_grid_objects[grid_pos] = "leaf"
	# initialize character position from level data 
	character.initialize_at_grid(level.start_position, level.start_direction, tile_size)
	
	
func _spawn_tile_model(scene:PackedScene, pos:Vector3):
	if scene:
		var instance = scene.instantiate()
		add_child(instance)
		instance.global_position = pos

func _spawn_colored_cube(pos:Vector3, material: StandardMaterial3D):
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	
	box_mesh.size = Vector3(0.8, 0.8, 0.8)
	box_mesh.material = material
	
	mesh_instance.mesh = box_mesh
	add_child(mesh_instance)
	mesh_instance.global_position = pos	
		
#----------------
#Sensor API
#----------------
func is_tree_at(pos:Vector2i):
	return active_grid_objects.get(pos, "") == "tree"
	
func has_leaf_at(pos:Vector2i):
	return active_grid_objects.get(pos, "") == "leaf"
	
