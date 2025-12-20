extends Node2D

var test_slots := {
	Vector2i(0,0): "normal",
	Vector2i(1,0): "interact",
	Vector2i(2,0): "blocked",
	Vector2i(1,1): "shop"
}

var player_cell := Vector2i(1,0)
const CELL_SIZE := 6


func _draw():
	for cell in test_slots.keys():
		var pos = Vector2(cell) * CELL_SIZE
		var color = get_color(test_slots[cell])
		draw_rect(Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE)), color)

	# player
	var p = Vector2(player_cell) * CELL_SIZE + Vector2(CELL_SIZE/2, CELL_SIZE/2)
	draw_circle(p, 3, Color.WHITE)

func get_color(slot_type: String) -> Color:
	match slot_type:
		"normal":
			return Color(0.35, 0.45, 0.6)      # muted blue
		"interact":
			return Color(0.8, 0.6, 0.25)       # warm amber
		"blocked":
			return Color(0.2, 0.2, 0.2)        # dark / dead
		"shop":
			return Color(0.3, 0.7, 0.4)        # green
		"battle":
			return Color(0.75, 0.25, 0.25)     # red
		_:
			return Color(0.4, 0.4, 0.4)        # fallback
