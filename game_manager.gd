extends Node

var save_data := {
	"player": {
		"position": Vector2i(0,0),
		"hp": 100,
		"max_hp": 100,
		"inventory": [],
		"cards": [],
	},
	"world": {
		"visited_tiles": {},
		"quests": {},
		"time_of_day": "morning",
		"level_name": "level_0",
	}
}

func add_item(item_name: String):
	save_data["player"]["inventory"].append(item_name)
	print("Added item:", item_name)

func has_item(item_name: String) -> bool:
	return item_name in save_data["player"]["inventory"]

func set_quest_state(quest_id: String, state: String):
	save_data["world"]["quests"][quest_id] = state

func get_quest_state(quest_id: String) -> String:
	return save_data["world"]["quests"].get(quest_id, "not_started")

func visit_tile(cell: Vector2i):
	save_data["world"]["visited_tiles"][cell] = true

func is_tile_visited(cell: Vector2i) -> bool:
	return save_data["world"]["visited_tiles"].get(cell, false)

func set_time(time_string: String):
	save_data["world"]["time_of_day"] = time_string

func get_time() -> String:
	return save_data["world"]["time_of_day"]
