# level_2.gd (level script)
extends Node3D

@onready var grid_manager: GridManager = $GridManager
@onready var character: GridCharacter = $Character
@onready var fsm_runner: FSMRunner = $FSMRunner
@onready var fsm_editor: Control = $FsmEditor

var player_states: Array[FSMState] = []
var player_start_state_name: String = ""

var win_layer: CanvasLayer
var win_center: CenterContainer
var win_panel: PanelContainer
var win_label: Label
var retry_button: Button
var next_level_button : Button


var level_camera: Camera3D
var default_camera_pos := Vector3(4.0, 12.0, 14.0)
var default_camera_look_at := Vector3(4.0, -1.0, 8.0)
var camera_orbit_tween: Tween


func _ready():
	_setup_camera()
	_setup_lighting()
	_setup_grid()
	_setup_win_ui()

	fsm_editor.fsm_executed.connect(_on_fsm_executed)
	fsm_runner.level_completed.connect(_on_level_completed)
	fsm_runner.level_failed.connect(_on_level_failed)
	
func _setup_win_ui() -> void:
	win_layer = CanvasLayer.new()
	win_layer.layer = 20
	add_child(win_layer)

	# Let clicks pass through empty screen space; toggle visibility with the popup
	win_center = CenterContainer.new()
	win_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	win_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_center.visible = false
	win_layer.add_child(win_center)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.14, 0.16, 0.2, 0.96)
	panel_style.border_color = Color(0.35, 0.78, 0.45, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 28
	panel_style.content_margin_right = 28
	panel_style.content_margin_top = 22
	panel_style.content_margin_bottom = 22

	win_panel = PanelContainer.new()
	win_panel.add_theme_stylebox_override("panel", panel_style)
	win_panel.custom_minimum_size = Vector2(360, 150)
	win_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	win_center.add_child(win_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	win_panel.add_child(vbox)

	win_label = Label.new()
	win_label.text = "Level Complete!"
	win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	win_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(win_label)

	retry_button = Button.new()
	retry_button.text = "Edit FSM & Retry"
	retry_button.custom_minimum_size = Vector2(180, 40)
	retry_button.pressed.connect(_on_retry_pressed)
	vbox.add_child(retry_button)
	
	next_level_button = Button.new()
	next_level_button.text = "Next Level"
	next_level_button.custom_minimum_size = Vector2(180, 40)
	next_level_button.pressed.connect(_on_next_level_pressed)
	vbox.add_child(next_level_button)

func _setup_camera():
	if get_viewport().get_camera_3d() != null:
		level_camera = get_viewport().get_camera_3d()
		return
	var camera := Camera3D.new()
	add_child(camera)
	level_camera = camera

	_reset_camera_to_default()
	camera.make_current()

func _reset_camera_to_default() -> void:
	if camera_orbit_tween and camera_orbit_tween.is_valid():
		camera_orbit_tween.kill()
	if level_camera == null:
		return
	level_camera.global_position = default_camera_pos
	level_camera.look_at(default_camera_look_at, Vector3.UP)

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

func _setup_grid():
	var test_level = LevelData.new()
	test_level.level_name = "Test Level 1"
	test_level.start_position = Vector2i(1,1)
	test_level.start_direction = GridCharacter.Direction.EAST
	test_level.grid_data = [
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
		[1, 0, 0, 0, 0, 1, 1, 1, 3, 1],
		[1, 1, 1, 1, 0, 1, 1, 1, 0, 1],
		[1, 1, 1, 1, 0, 1, 1, 1, 0, 1],
		[1, 1, 1, 1, 0, 0, 0, 0, 0, 1],
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	
	]
	grid_manager.load_level(test_level, character)
func _on_fsm_executed(states: Array[FSMState], start_state = ""):
	player_states = states
	player_start_state_name = start_state
	print("state data received in level script")

	_set_win_ui_visible(false)
	_reset_camera_to_default()
	if fsm_editor:
		fsm_editor.hide()

	fsm_runner.character = character
	fsm_runner.grid_manager = grid_manager
	fsm_runner.load_fsm(player_states, player_start_state_name)
	fsm_runner.start()

func _on_level_completed() -> void:
	if fsm_editor:
		fsm_editor.hide()
	_set_win_ui_visible(true, "Level Complete! Stopped on the coin.")
	_start_win_camera_orbit()

func _on_retry_pressed() -> void:
	_set_win_ui_visible(false)
	_reset_camera_to_default()
	_setup_grid()
	if fsm_editor:
		fsm_editor.show()
func _on_level_failed(reason: String) -> void:
	print("Run ended: ", reason)
	_set_win_ui_visible(false)
	if fsm_editor:
		fsm_editor.show()

func _set_win_ui_visible(should_show: bool, message: String = "") -> void:
	if message != "" and win_label != null:
		win_label.text = message
	if win_center != null:
		win_center.visible = should_show
		
func _start_win_camera_orbit(radius: float = 5.5, height_offset: float = 3.5, duration: float = 4.0) -> void:
	if level_camera == null or character == null:
		return

	if camera_orbit_tween and camera_orbit_tween.is_valid():
		camera_orbit_tween.kill()

	var target: Vector3 = character.global_position + Vector3(0.0, 0.75, 0.0)
	var start_offset: Vector3 = level_camera.global_position - target
	var start_angle: float = atan2(start_offset.z, start_offset.x)

	camera_orbit_tween = create_tween()
	camera_orbit_tween.set_loops() # Orbit continuously while win screen is up
	camera_orbit_tween.tween_method(
		func(angle: float):
			if level_camera == null or character == null:
				return
			var pivot: Vector3 = character.global_position + Vector3(0.0, 0.75, 0.0)
			var cam_pos := Vector3(
				pivot.x + cos(angle) * radius,
				pivot.y + height_offset,
				pivot.z + sin(angle) * radius
			)
			level_camera.global_position = cam_pos
			level_camera.look_at(pivot, Vector3.UP),
		start_angle,
		start_angle + TAU,
		duration
	)
func _on_next_level_pressed() -> void:
	_set_win_ui_visible(false)
	_reset_camera_to_default()
	# If LevelManager is an Autoload named "LevelManager", call it directly:
	if Engine.has_singleton("LevelManager") or has_node("/root/LevelManager"):
		get_node("/root/LevelManager").load_next_level()
