extends Node3D

@onready var grid_manager: GridManager = $GridManager
@onready var character: GridCharacter = $Character
@onready var fsm_runner: FSMRunner = $FSMRunner

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
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
		[1, 0, 0, 0, 0, 0, 0, 0, 1, 1],
		[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 0, 0, 0, 0, 0, 0, 1, 1],
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	]
	
	grid_manager.load_level(test_level, character)
	
	await get_tree().create_timer(1.0).timeout
	
	var states = _create_test_fsm()
	
	fsm_runner.character = character
	fsm_runner.grid_manager = grid_manager
	fsm_runner.load_fsm(states, "StateMove")
	fsm_runner.start()
	
func _create_test_fsm() -> Array[FSMState]:
	# --- State 1: Move Forward State ---
	var state_move = FSMState.new()
	state_move.state_name = "StateMove"
	
	# Rule 1: If front is clear -> move forward, stay in "StateMove" (empty target means loop current state)
	var rule_move = FSMRule.new()
	rule_move.conditions = ["front_is_clear"]
	rule_move.actions = ["move"]
	rule_move.target_state_name = "StateMove"
	state_move.rules.append(rule_move)
	
	# Rule 2: If front is NOT clear (hit a tree) -> transition to StateTurn
	var rule_blocked = FSMRule.new()
	rule_blocked.conditions = ["front_is_tree"]
	rule_blocked.actions = [] # No actions, just transition
	rule_blocked.target_state_name = "StateTurn"
	state_move.rules.append(rule_blocked)
	
	
	# --- State 2: Turn State ---
	var state_turn = FSMState.new()
	state_turn.state_name = "StateTurn"
	
	# Rule 1: Turn right and go back to StateMove
	var rule_turn = FSMRule.new()
	rule_turn.conditions = [] # Always execute if reached
	rule_turn.actions = ["turn_right"]
	rule_turn.target_state_name = "StateMove"
	state_turn.rules.append(rule_turn)
	
	return [state_move, state_turn]
	
func _setup_camera():
	if get_viewport().get_camera_3d() != null:
		return
	
	var camera = Camera3D.new()
	add_child(camera)
	
	camera.global_position = Vector3(4.0, 12.0, 14.0)
	camera.look_at(Vector3(4.0, 0.0, 4.0), Vector3.UP)
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
	environment.background_color = Color(0.602, 0.834, 0.953, 1.0)
	
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(1.0, 1.0, 1.0, 1.0)
	environment.ambient_light_energy = 0.6
	
	env_node.environment = environment
