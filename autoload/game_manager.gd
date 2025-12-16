extends Node
# Game Manager Autoload

var hud: HUD


#region SAVE DATA
var save_data := {
	"player": {
		"position": Vector2i(0,0),
		"hp": 100,
		"max_hp": 100,
		"inventory": {},   # { item_id : amount },
		"cards": [],
	},
	"world": {
		"visited_tiles": {},
		"quests": {},
		"time_of_day": "morning",
		"level_name": "level_0",
	}
}
#endregion

#region PLAYER MANAGEMENT
func player_heal(amount: int):
	save_data["player"]["hp"] = clamp(
		save_data["player"]["hp"] + amount,
		0,
		save_data["player"]["max_hp"]
	)
	print("Player healed. HP =", save_data["player"]["hp"])
#endregion

#region INVENTORY
func add_item(id: int, amount: int = 1):
	if not ItemDB.ITEMS.has(id):
		push_error("Invalid item ID: %s" % id)
		return

	var inv = save_data["player"]["inventory"]

	if inv.has(id):
		inv[id] += amount
	else:
		inv[id] = amount

	print("Inventory now:", inv)

func remove_item(id: int, amount: int = 1) -> bool:
	var inv = save_data["player"]["inventory"]
	if not inv.has(id):
		return false

	inv[id] -= amount
	if inv[id] <= 0:
		inv.erase(id)

	return true

func has_item(id: int, amount: int = 1) -> bool:
	var inv = save_data["player"]["inventory"]
	return inv.has(id) and inv[id] >= amount

func get_inventory() -> Dictionary:
	return save_data["player"]["inventory"]
#endregion

#region QUEST
func set_quest_state(quest_id: String, save_state: String):
	save_data["world"]["quests"][quest_id] = save_state

func get_quest_state(quest_id: String) -> String:
	return save_data["world"]["quests"].get(quest_id, "not_started")
#endregion

#region TILE REGISTRATION
func visit_tile(cell: Vector2i):
	save_data["world"]["visited_tiles"][cell] = true

func is_tile_visited(cell: Vector2i) -> bool:
	return save_data["world"]["visited_tiles"].get(cell, false)
#endregion

#region TIME AND DATE
func set_time(time_string: String):
	save_data["world"]["time_of_day"] = time_string

func get_time() -> String:
	return save_data["world"]["time_of_day"]
#endregion

#region GODOT NATIVE
func _ready():
	print("Game Manager Loaded")
	debug_seed_inventory()
#endregion

#region GAMESTATE
enum GameState {
	BOARD,
	SIDESCROLL,
	MENU_OPEN
}

var state := GameState.BOARD
#endregion

#region SIGNALS
signal toggle_wunderpal_requested
#endregion

#region REQUEST WUNDERPAL TOGGLE
func request_toggle_wunderpal():
	emit_signal("toggle_wunderpal_requested")
#endregion

#region DEBUG SEED INVENTORY
func debug_seed_inventory():
	save_data["player"]["inventory"] = {
		1: 3,
		2: 1,
		3: 12
	}
	print("[GameManager] Debug inventory seeded")
#endregion
