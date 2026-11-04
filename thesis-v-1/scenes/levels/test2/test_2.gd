extends Node3D

@onready var grid_manager: GridManager = $GridManager
@onready var character: GridCharacter = $Character
@onready var fsm_runner: FSMRunner = $FSMRunner
# Assuming you add your FSMEditor as a child node in your level scene (or instance it)
@onready var fsm_editor: Control = $FsmEditor

func _ready():
	_setup_camera()
	_setup_lighting()
	
	# 1. Hardcoded test level setup
	var test_level = LevelData.new()
	test_level.level_name = "Test Level 1"
	test_level.start_position = Vector2i(1,1)
	test_level.start_direction = GridCharacter.Direction.EAST
	
	test_level.grid_data = [
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
		[1, 0, 2, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 0, 3, 0, 0, 0, 0, 0, 1],
		[1, 0, 0, 0, 1, 0, 0, 0, 0, 1],
		[1, 0, 0, 0, 0, 1, 0, 0, 0, 1],
		[1, 0, 0, 0, 0, 0, 1, 0, 0, 1],
		[1, 0, 0, 0, 0, 0, 0, 1, 0, 1],
		[1, 0, 0, 0, 0, 0, 0, 0, 1, 1],
		[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	]
	
	grid_manager.load_level(test_level, character)
	
	# 2. Configure the FSM Runner references
	fsm_runner.character = character
	fsm_runner.grid_manager = grid_manager
	
	# 3. Connect the editor's run signal or handle it directly
	# Assuming your FSMEditor has a method or signal when the player hits Play:
	if fsm_editor.has_signal("fsm_executed"):
		fsm_editor.fsm_executed.connect(_on_fsm_editor_run)
	else:
		# Alternatively, you can bind a button reference from the level script:
		pass

# This function receives the states built by the player in the UI
func _on_fsm_editor_run(states: Array[FSMState], start_state_name: String) -> void:
	# Hide editor UI so player can watch simulation
	fsm_editor.visible = false
	
	# Load and run the player's custom FSM!
	fsm_runner.load_fsm(states, start_state_name)
	fsm_runner.start()

func _setup_camera():
	if get_viewport().get_camera_3d() != null:
		return
	var camera = Camera3D.new()
	add_child(camera)
	camera.global_position = Vector3(4.0, 12.0, 14.0)
	camera.look_at(Vector3(4.0, 0.0, 4.0), Vector3.UP)
	camera.make_current()

func _setup_lighting():
	var sun = DirectionalLight3D.new()
	add_child(sun)
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-45.0, 45.0, 0.0)
	sun.light_energy = 1.2
	
	var env_node = WorldEnvironment.new()
	add_child(env_node)
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.602, 0.834, 0.953, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(1.0, 1.0, 1.0, 1.0)
	environment.ambient_light_energy = 0.6
	env_node.environment = environment
