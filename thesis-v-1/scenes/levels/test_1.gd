extends Node3D

@onready var grid_manager: GridManager = $GridManager
@onready var character: GridCharacter = $Character
@onready var command_runner: CommandRunner = $CommandRunner

func _ready():
	_setup_camera()
	_setup_lighting()
	# 1. hardcoded test level
	var test_level = LevelData.new()
	test_level.level_name = "Test Level 1"
	test_level.start_position = Vector2i(1,1)
	test_level.start_direction = GridCharacter.Direction.EAST
	
	# 0 = empty, 1 = tree/obstacle, 2 = leaf
	test_level.grid_data = [
		[1, 1, 1, 1, 1],
		[1, 0, 0, 2, 1],
		[1, 0, 0, 0, 1],
		[1, 0, 0, 0, 1],
		[1, 1, 1, 1, 1]
	]
	
	grid_manager.load_level(test_level, character)
	var test_commands: Array[String] = [
		"move",
		"turn_right",
		"move",
		"turn_left",
		"move"
	]
	
	await get_tree().create_timer(1.0).timeout
	
	command_runner.character = character
	command_runner.grid_manager = grid_manager
	command_runner.load_program(test_commands)
	command_runner.run_program()
	
func _setup_camera():
	if get_viewport().get_camera_3d() != null:
		return
	
	var camera = Camera3D.new()
	add_child(camera)
	
	camera.global_position = Vector3(2.0, 7.0, 6.0)
	camera.look_at(Vector3(2.0, 0.0, 2.0), Vector3.UP)
	camera.make_current()
	
func _setup_lighting():
	# 1.directional sun light
	var sun = DirectionalLight3D.new()
	add_child(sun)
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-45.0, 45.0, 0.0)
	sun.light_energy = 1.2
	
	# 2. world environment for ambient light and soft sky color
	var env_node = WorldEnvironment.new()
	add_child(env_node)
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.53, 0.81, 0.92)
	
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.85, 0.95)
	environment.ambient_light_energy = 0.6
	
	env_node.environment = environment
