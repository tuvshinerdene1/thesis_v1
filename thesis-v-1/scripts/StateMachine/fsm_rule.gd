class_name FSMRule
extends Resource

@export var conditions: Array[String] = []
@export var actions: Array[String] = []
@export var target_state_name: String = "" # if left empty or matches current, it loops
