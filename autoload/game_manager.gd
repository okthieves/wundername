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

#region DEBUG INPUT COMMANDS
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_merlin"):
		set_player_name("Merlin")
		GameManager.add_card("connection_fire_blood")
	if event.is_action_pressed("debug_show_stats"):
		print(GameManager.get_player_name())
		print(GameManager.get_inventory())
		print(GameManager.get_stat("hp"))
		print(GameManager.get_stat("luck"))
		print(GameManager.get_stat("resilience"))
		print(GameManager.get_stat("speed"))
		print(GameManager.get_stat("modifiers"))
		print(GameManager.get_card_instances("deck"))
#endregion

#region SAVE DATA

## Primary save data dictionary.
## Stores all persistent player and world information.
## This structure is intended to be serializable for save/load.
var save_data := {
	# ─────────────────────────────
	# PLAYER STATE
	# ─────────────────────────────
	"player": {

		# ─────────────────────────────
		# IDENTITY (rarely changes)
		# ─────────────────────────────
		"identity": {
			"name": "Traveler",
			"element_affinity": "neutral",
			"tags": []  # semantic traits: ["human", "resonant", "marked"]
		},

		# ─────────────────────────────
		# STATS (frequently read, sometimes modified)
		# ─────────────────────────────
		"stats": {
			"hp": 100,
			"max_hp": 100,
			"speed": 1.0,
			"luck": 0,
			"resilience": 0,

			# Temporary or conditional modifiers
			# e.g. { "speed": +0.2, "luck": -1 }
			"modifiers": {}
		},

		# ─────────────────────────────
		# INVENTORY SYSTEMS
		# ─────────────────────────────
		"inventory": {
			"items": {}, # { item_id : amount }   
		
		# ─────────────────────────────
		# CARD SYSTEM (Phase 2)
		# ─────────────────────────────
			"cards": {
				"owned": [],        # ALL cards the player has ever obtained
				"deck": [],         # playable cards (subset of owned)
				"hand": [],
				"discard": [],
				"memory": [],       # permanent narrative cards (subset of owned)
				"connections": []   # active connection cards (subset of owned)
},
		},
		# ─────────────────────────────
		# BOARD POSITION (turn-based layer)
		# ─────────────────────────────
		"position": {
			"board_id": "level_0",
			"cell": Vector2i(0, 0)
		},

		# ─────────────────────────────
		# PROGRESS FLAGS
		# ─────────────────────────────
		"progress": {
			"boards_visited": [],
			"npcs_met": {},       # { npc_id : true }
			"secrets_found": {}   # { secret_id : true }
		}
	},

	# ─────────────────────────────
	# WORLD STATE
	# ─────────────────────────────
	"world": {
		"visited_tiles": {},     # { Vector2i : true }
		"quests": {},            # { quest_id : state }
		"time_of_day": "morning",
		"level_name": "level_0",

		# Side-scroll persistence (Phase 1 minimal)
		"sidescroll": {
			"active_scene": "",
			"spawn_point": "default",
			"scene_state": {}   # { scene_id : { position, flags } }
		}
	}
}

#endregion

#region PLAYER NAME | ELEMENT AFFINITY | TAGS

func get_player_name() -> String:
	return save_data["player"]["identity"]["name"]

func set_player_name(new_name: String):
	save_data["player"]["identity"]["name"] = new_name

func get_element_affinity() -> String:
	return save_data["player"]["identity"]["element_affinity"]

func set_element_affinity(affinity: String):
	save_data["player"]["identity"]["element_affinity"] = affinity

func add_player_tag(tag: String):
	var tags = save_data["player"]["identity"]["tags"]
	if not tags.has(tag):
		tags.append(tag)

func has_player_tag(tag: String) -> bool:
	return save_data["player"]["identity"]["tags"].has(tag)

#endregion

#region PLAYER STAT MANAGEMENT

## Heals the player by a given amount.
## Health is clamped between 0 and max HP.
## @param amount Amount of HP to restore.
func player_heal(amount: int):
	var stats = save_data["player"]["stats"]

	stats["hp"] = clamp(
		stats["hp"] + amount,
		0,
		stats["max_hp"]
	)

	print("Player healed. HP =", stats["hp"])
	
func get_stat(stat_name: String):
	return save_data["player"]["stats"].get(stat_name, null)
	
func set_stat(stat_name: String, value):
	if not save_data["player"]["stats"].has(stat_name):
		push_warning("Attempted to set unknown stat: %s" % stat_name)
		return

	save_data["player"]["stats"][stat_name] = value

func modify_stat(stat_name: String, delta):
	if not save_data["player"]["stats"].has(stat_name):
		push_warning("Attempted to modify unknown stat: %s" % stat_name)
		return

	save_data["player"]["stats"][stat_name] += delta
#endregion

#region INVENTORY

## Adds an item to the player's inventory.
## @param id Item ID from ItemDB.
## @param amount Number of items to add.

func add_item(id: int, amount: int = 1):
	var items = save_data["player"]["inventory"]["items"]
	items[id] = items.get(id, 0) + amount

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


func get_inventory_items() -> Dictionary:
	return save_data["player"]["inventory"]["items"]
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

func set_state(new_state: GameState):
	if state == new_state:
		return

	state = new_state
	print("[GameManager] State →", new_state)
	
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
	save_data["player"]["inventory"]["items"] = {
		1: 3,
		2: 1,
		3: 12
	}
	print("[GameManager] Debug inventory seeded")
#endregion


#region SIDESCROLL PERSISTENCE

func set_active_sidescroll(scene_id: String):
	save_data["world"]["sidescroll"]["active_scene"] = scene_id

func set_sidescroll_position(scene_id: String, pos: Vector2) -> void:
	save_data["world"]["sidescroll"]["scene_state"][scene_id] = {
		"player_pos": pos
	}

func get_sidescroll_position(scene_id: String) -> Vector2:
	var state = save_data["world"]["sidescroll"]["scene_state"]
	if state.has(scene_id):
		return state[scene_id].get("player_pos", Vector2.ZERO)
	return Vector2.ZERO

func clear_sidescroll_state(scene_id: String) -> void:
	save_data["world"]["sidescroll"]["scene_state"].erase(scene_id)

#endregion

#region SIDESCROLL SCENE REGISTRY
const SIDESCROLL_SCENES := {
	"station_test": "res://scenes/sidescroller/test_scene.tscn"
}

func has_sidescroll_scene(scene_id: String) -> bool:
	return SIDESCROLL_SCENES.has(scene_id)

func get_sidescroll_path(scene_id: String) -> String:
	if not has_sidescroll_scene(scene_id):
		push_error("Unknown sidescroll scene_id: %s" % scene_id)
		return ""
	return SIDESCROLL_SCENES[scene_id]

func enter_sidescroll(scene_id: String):
	if not has_sidescroll_scene(scene_id):
		return

	save_data["world"]["sidescroll"]["active_scene"] = scene_id
	set_state(GameState.SIDESCROLL)

	hud.open_sidescroll(scene_id)
	
func resolve_scene_path(scene_id: String) -> String:
	if not SIDESCROLL_SCENES.has(scene_id):
		push_error("Unknown scene_id: %s" % scene_id)
		return ""
	return SIDESCROLL_SCENES[scene_id]
#endregion


#region CARDS — OWNERSHIP (Phase 2)

func add_card(card_id: String) -> void:
	if not CardRegistry.has_card(card_id):
		push_error("Unknown card_id: %s" % card_id)
		return

	var cards = save_data["player"]["inventory"]["cards"]

	if not cards["owned"].has(card_id):
		cards["owned"].append(card_id)

	var card = CardRegistry.get_card(card_id)
	match card.type:
		"memory":
			if not cards["memory"].has(card_id):
				cards["memory"].append(card_id)

		"connection":
			if not cards["connections"].has(card_id):
				cards["connections"].append(card_id)

	print("[Cards] Added:", card_id)
func remove_card(card_id: String, pile := "deck") -> void:
	var cards = save_data["player"]["inventory"]["cards"]

	if not cards.has(pile):
		push_warning("Unknown card pile: %s" % pile)
		return

	cards[pile].erase(card_id)

func get_cards(pile := "deck") -> Array:
	return save_data["player"]["inventory"]["cards"].get(pile, [])

#endregion

#region CARDS — INSTANCE ADAPTER (Phase 2)

func build_card_instance(card_id: String) -> Dictionary:
	if not CardRegistry.has_card(card_id):
		push_error("Invalid card_id: %s" % card_id)
		return {}

	var base := CardRegistry.get_card(card_id)

	return {
		"id": card_id,
		"name": base.get("name", ""),
		"type": base.get("type", ""),
		"element": base.get("element", ""),
		"description": base.get("description", ""),
		"tags": base.get("tags", []).duplicate(),
		"stats": base.get("stats", {}).duplicate(),
		"flags": base.get("flags", {}).duplicate(),
		"meta": base.get("meta", {}).duplicate()
	}

func get_card_instances(pile := "deck") -> Array:
	var instances := []

	for card_id in get_cards(pile):
		instances.append(build_card_instance(card_id))

	return instances

#endregion
