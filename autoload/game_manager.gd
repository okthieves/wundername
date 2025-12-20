## Global game manager autoload.
## Acts as the central authority for save data, inventory,
## quests, world state, UI coordination, and high-level game state.
##
## This script persists across scenes and should contain
## global, non-scene-specific logic only.
extends Node


## Reference to the active HUD instance.
## Assigned by the HUD on initialization.
var hud: HUD


#region SAVE DATA

## Primary save data dictionary.
## Stores all persistent player and world information.
## This structure is intended to be serializable for save/load.
var save_data := {
	"player": {
		## Grid position of the player pawn on the board.
		"position": Vector2i(0, 0),

		## Current player health.
		"hp": 100,

		## Maximum player health.
		"max_hp": 100,

		## Player inventory.
		## Stored as { item_id : amount }.
		"inventory": {},

		## List of owned cards (future system).
		"cards": [],
	},
	"world": {
		## Tracks which board tiles have been visited.
		"visited_tiles": {},

		## Quest state mapping { quest_id : state }.
		"quests": {},

		## Current time-of-day state.
		"time_of_day": "morning",

		## Name of the currently loaded level.
		"level_name": "level_0",
	}
}

#endregion


#region PLAYER MANAGEMENT

## Heals the player by a given amount.
## Health is clamped between 0 and max HP.
## @param amount Amount of HP to restore.
func player_heal(amount: int):
	save_data["player"]["hp"] = clamp(
		save_data["player"]["hp"] + amount,
		0,
		save_data["player"]["max_hp"]
	)
	print("Player healed. HP =", save_data["player"]["hp"])

#endregion


#region INVENTORY

## Adds an item to the player's inventory.
## @param id Item ID from ItemDB.
## @param amount Number of items to add.
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


## Removes an item from the player's inventory.
## Automatically removes the entry if the count reaches zero.
## @param id Item ID from ItemDB.
## @param amount Number of items to remove.
## @return True if removal succeeded, false otherwise.
func remove_item(id: int, amount: int = 1) -> bool:
	var inv = save_data["player"]["inventory"]
	if not inv.has(id):
		return false

	inv[id] -= amount
	if inv[id] <= 0:
		inv.erase(id)

	return true


## Checks whether the player has at least a given amount of an item.
## @param id Item ID from ItemDB.
## @param amount Required amount.
## @return True if the player has enough of the item.
func has_item(id: int, amount: int = 1) -> bool:
	var inv = save_data["player"]["inventory"]
	return inv.has(id) and inv[id] >= amount


## Returns the player's inventory dictionary.
## Intended for read-only access by UI systems.
func get_inventory() -> Dictionary:
	return save_data["player"]["inventory"]

#endregion


#region QUESTS

## Sets the save state of a quest.
## @param quest_id Unique quest identifier.
## @param save_state Current quest state string.
func set_quest_state(quest_id: String, save_state: String):
	save_data["world"]["quests"][quest_id] = save_state


## Retrieves the current save state of a quest.
## Returns "not_started" if no state is recorded.
## @param quest_id Unique quest identifier.
## @return Quest state string.
func get_quest_state(quest_id: String) -> String:
	return save_data["world"]["quests"].get(quest_id, "not_started")

#endregion


#region TILE REGISTRATION

## Marks a board tile as visited.
## @param cell Grid position of the tile.
func visit_tile(cell: Vector2i):
	save_data["world"]["visited_tiles"][cell] = true


## Checks whether a board tile has been visited.
## @param cell Grid position of the tile.
## @return True if the tile has been visited.
func is_tile_visited(cell: Vector2i) -> bool:
	return save_data["world"]["visited_tiles"].get(cell, false)

#endregion


#region TIME AND DATE

## Sets the current time-of-day state.
## @param time_string Time-of-day identifier (e.g. "morning", "night").
func set_time(time_string: String):
	save_data["world"]["time_of_day"] = time_string


## Retrieves the current time-of-day state.
## @return Time-of-day identifier.
func get_time() -> String:
	return save_data["world"]["time_of_day"]

#endregion


#region GODOT NATIVE

## Called when the GameManager autoload is initialized.
## Performs initial setup and debug seeding.
func _ready():
	print("Game Manager Loaded")
	debug_seed_inventory()

#endregion


#region GAME STATE

## High-level game state enumeration.
## Used to control input routing and system behavior.
enum GameState {
	BOARD,       ## Board navigation and pawn movement
	SIDESCROLL,  ## Side-scrolling gameplay
	MENU_OPEN    ## UI menu (Wunderpal) is open
}

## Current active game state.
var state := GameState.BOARD

#endregion


#region SIGNALS

## Emitted when the Wunderpal should be toggled.
## Listened to by the HUD.
signal toggle_wunderpal_requested

#endregion


#region REQUEST WUNDERPAL TOGGLE

## Requests the HUD to toggle the Wunderpal UI.
## Does not directly manipulate UI state.
func request_toggle_wunderpal():
	emit_signal("toggle_wunderpal_requested")

#endregion


#region DEBUG SEED INVENTORY

## Populates the player's inventory with test items.
## Intended for development and debugging only.
func debug_seed_inventory():
	save_data["player"]["inventory"] = {
		1: 3,
		2: 1,
		3: 12
	}
	print("[GameManager] Debug inventory seeded")

#endregion
