extends Node
class_name LevelManager

signal level_changed(level_index: int, level_path: String)

# Add your level scenes here in order (or populate in _ready())
@export var levels: Array[String] = [
	"res://level_1.tscn",
	"res://level_2.tscn"
]

var current_level_index: int = -1
var current_level_node: Node = null
var is_paused: bool = false

# UI references built via code
var ui_layer: CanvasLayer
var start_overlay: CenterContainer
var start_level_buttons_box: VBoxContainer

var pause_overlay: CenterContainer
var pause_status_label: Label


func _ready() -> void:
	# Allow pause menu buttons to work even when get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_show_start_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Only toggle pause while actively inside a level (and start menu isn't shown)
		if current_level_node != null and not start_overlay.visible:
			if is_paused:
				resume_game()
			else:
				pause_game()
			get_viewport().set_input_as_handled()


# =========================================================
# LEVEL LIFECYCLE
# =========================================================

func load_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		print("LevelManager: Invalid level index ", index)
		return

	resume_game()
	_clear_current_level()

	current_level_index = index
	var path: String = levels[index]
	var packed: PackedScene = load(path)
	if packed == null:
		print("LevelManager: Failed to load level scene at ", path)
		return

	current_level_node = packed.instantiate()
	add_child(current_level_node)

	# Connect to FSMRunner's level_completed signal if present in the level
	var runner: Node = _find_fsm_runner(current_level_node)
	if runner != null and runner.has_signal("level_completed"):
		if not runner.level_completed.is_connected(_on_current_level_completed):
			runner.level_completed.connect(_on_current_level_completed)

	start_overlay.visible = false
	pause_overlay.visible = false
	level_changed.emit(current_level_index, path)


func restart_level() -> void:
	if current_level_index >= 0:
		load_level(current_level_index)


func load_next_level() -> void:
	var next_idx: int = current_level_index + 1
	if next_idx < levels.size():
		load_level(next_idx)
	else:
		# All levels finished -> return to Start Menu
		_clear_current_level()
		_show_start_menu()


func _clear_current_level() -> void:
	if current_level_node != null:
		current_level_node.queue_free()
		current_level_node = null


func _find_fsm_runner(root: Node) -> Node:
	if root is FSMRunner:
		return root
	for child in root.get_children():
		var found: Node = _find_fsm_runner(child)
		if found != null:
			return found
	return null


func _on_current_level_completed() -> void:
	print("LevelManager: Level %d completed!" % (current_level_index + 1))


# =========================================================
# PAUSE & START MENU STATE
# =========================================================

func pause_game() -> void:
	if current_level_node == null or is_paused:
		return
	is_paused = true
	get_tree().paused = true
	pause_status_label.text = "Paused — Level %d" % (current_level_index + 1)
	pause_overlay.visible = true


func resume_game() -> void:
	is_paused = false
	get_tree().paused = false
	pause_overlay.visible = false


func return_to_start_menu() -> void:
	resume_game()
	_clear_current_level()
	current_level_index = -1
	_show_start_menu()


func _show_start_menu() -> void:
	resume_game()
	pause_overlay.visible = false
	_rebuild_level_buttons()
	start_overlay.visible = true


# =========================================================
# PURE-CODE UI CONSTRUCTION
# =========================================================

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 50
	add_child(ui_layer)

	_build_start_menu()
	_build_pause_menu()


func _make_panel_style(border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18, 0.96)
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	return style


func _make_button(text: String, min_size := Vector2(220, 42)) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	return btn


func _build_start_menu() -> void:
	start_overlay = CenterContainer.new()
	start_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_overlay.visible = false
	ui_layer.add_child(start_overlay)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.35, 0.75, 0.95, 1.0)))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	start_overlay.add_child(panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 16)
	root_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(root_vbox)

	var title := Label.new()
	title.text = "Kara 3D — FSM Puzzle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	root_vbox.add_child(title)

	var play_btn := _make_button("Play Level 1")
	play_btn.pressed.connect(func():
		if levels.size() > 0:
			load_level(0)
	)
	root_vbox.add_child(play_btn)

	var level_header := Label.new()
	level_header.text = "Select Level"
	level_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(level_header)

	start_level_buttons_box = VBoxContainer.new()
	start_level_buttons_box.add_theme_constant_override("separation", 8)
	root_vbox.add_child(start_level_buttons_box)

	var quit_btn := _make_button("Quit")
	quit_btn.pressed.connect(func():
		get_tree().quit()
	)
	root_vbox.add_child(quit_btn)

	_rebuild_level_buttons()


func _rebuild_level_buttons() -> void:
	for child in start_level_buttons_box.get_children():
		child.queue_free()

	for i in range(levels.size()):
		var lvl_idx := i
		var btn := _make_button("Level %d" % (lvl_idx + 1), Vector2(220, 36))
		btn.pressed.connect(func():
			load_level(lvl_idx)
		)
		start_level_buttons_box.add_child(btn)


func _build_pause_menu() -> void:
	pause_overlay = CenterContainer.new()
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_overlay.visible = false
	ui_layer.add_child(pause_overlay)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.95, 0.72, 0.25, 1.0)))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	pause_status_label = Label.new()
	pause_status_label.text = "Paused"
	pause_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_status_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(pause_status_label)

	var resume_btn := _make_button("Resume")
	resume_btn.pressed.connect(resume_game)
	vbox.add_child(resume_btn)

	var restart_btn := _make_button("Restart Level")
	restart_btn.pressed.connect(restart_level)
	vbox.add_child(restart_btn)

	var menu_btn := _make_button("Main Menu")
	menu_btn.pressed.connect(return_to_start_menu)
	vbox.add_child(menu_btn)
