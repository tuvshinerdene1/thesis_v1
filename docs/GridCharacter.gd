# GridCharacter

`GridCharacter` is a base class that extends `Node3D` to handle grid-based movement, rotation, and position tracking for characters in a 3D Godot environment.

## Constants & Enums

### `Direction`
An enum representing the four cardinal directions.
* `NORTH`: `0`
* `EAST`: `1`
* `SOUTH`: `2`
* `WEST`: `3`

### `DIRECTION_VECTORS`
Maps each `Direction` to a 2D grid offset vector (`Vector2i`).
* `NORTH`: `Vector2i(0, -1)`
* `EAST`: `Vector2i(1, 0)`
* `SOUTH`: `Vector2i(0, 1)`
* `WEST`: `Vector2i(-1, 0)`

### `DIRECTION_ANGLES`
Maps each `Direction` to its corresponding Y-axis rotation angle in degrees.
* `NORTH`: `180.0`°
* `EAST`: `90.0`°
* `SOUTH`: `0.0`°
* `WEST`: `270.0`°

---

## Exported & Onready Variables

* **`step_duration`** (`float`, Default: `0.3`): The duration in seconds for movement and rotation tweens.
* **`visual_pivot`** (`Node3D`): Reference to the child node `$VisualPivot` responsible for rendering and rotating the mesh independently of the physical grid coordinate.

---

## State Variables

* **`grid_position`** (`Vector2i`): The current coordinates of the character on the grid (`X` = columns, `Y` = rows).
* **`current_direction`** (`Direction`): The direction the character is currently facing.
* **`is_moving`** (`bool`): A flag indicating whether the character is currently executing a movement or rotation animation.

---
