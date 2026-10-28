extends Node3D
class_name GridCharacter


signal movement_finished
#Cardomal directions 
enum Direction {NORTH, EAST, SOUTH, WEST}
# direction vectors mapped to Vector2i ( X= columns, Y = rows)
const DIRECTION_VECTORS = {
	Direction.NORTH : Vector2i(0, -1),
	Direction.EAST: Vector2i(1, 0),
	Direction.SOUTH: Vector2i(0, 1),
	Direction.WEST: Vector2i(-1, 0)
}
# rotation angles in degrees for each cardinal direction
const DIRECTION_ANGLES = {
	Direction.NORTH: 180.0,
	Direction.EAST: 90.0,
	Direction.SOUTH: 0.0,
	Direction.WEST: 270.0
}

@export var step_duration: float = 0.3
@onready var visual_pivot: Node3D = $VisualPivot
@onready var mesh_instance: MeshInstance3D = $VisualPivot/Model

# Grid position tracking
var grid_position: Vector2i = Vector2i.ZERO
var current_direction: Direction = Direction.EAST
var is_moving: bool = false

func initialize_at_grid(start_grid_pos: Vector2i, start_dir: Direction = Direction.EAST, tile_size: float = 1.0):
	grid_position = start_grid_pos
	current_direction = start_dir
	var size_y = mesh_instance.mesh.get_aabb().size.y * mesh_instance.scale.y
	
	# snap position and rotation in 3d world space
	global_position = Vector3(grid_position.x * tile_size,size_y/2 , grid_position.y*tile_size)
	visual_pivot.rotation_degrees.y = DIRECTION_ANGLES[current_direction]
	
#-----------------------------
# CORE API FUNCTIONS 
#-----------------------------
func move_forward(tile_size: float = 1.0) -> void:
	if is_moving:
		return
	var dir_vector = DIRECTION_VECTORS[current_direction]
	grid_position += dir_vector
	var target_world_pos = Vector3(grid_position.x * tile_size, global_position.y, grid_position.y * tile_size)
	is_moving = true
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_world_pos, step_duration)
	tween.finished.connect(func():
		is_moving = false
		movement_finished.emit()
	)

func turn_left() -> void:
	if is_moving:
		return
	# cycle direction counter-clockwise
	current_direction = (current_direction - 1 + 4) % 4 as Direction
	_animate_rotation()

func turn_right() -> void:
	if is_moving:
		return
	# cycle direction clockwise
	current_direction = (current_direction + 1) % 4 as Direction
	_animate_rotation()

#-----------------------------
# SENSOR & HELPER FUNCTIONS
#-----------------------------
func get_front_grid_position() -> Vector2i:
	return grid_position + DIRECTION_VECTORS[current_direction]
	
func _animate_rotation() -> void:
	is_moving = true
	var target_angle = DIRECTION_ANGLES[current_direction]
	var tween = create_tween()
	tween.tween_property(visual_pivot, "rotation_degrees:y", target_angle, step_duration * 0.8 )
	tween.finished.connect(func(): 
		is_moving = false
		movement_finished.emit()
	)
	
