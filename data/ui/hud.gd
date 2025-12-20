## Heads-up display controller for the Wunderpal device.
## Manages UI visibility, tab switching, inventory display,
## tooltips, and integration with the GameManager.
extends Control
class_name HUD


func _process(_delta):
	update_debug_state_label()
	
func update_debug_state_label():
	var state_name = GameManager.GameState.keys()[GameManager.state]
	debug_state_label.text = "STATE: " + state_name

	match GameManager.state:
		GameManager.GameState.BOARD:
			debug_state_label.modulate = Color.LIGHT_GREEN
		GameManager.GameState.MENU_OPEN:
			debug_state_label.modulate = Color.YELLOW
		GameManager.GameState.SIDESCROLL:
			debug_state_label.modulate = Color.ORANGE

#region GENERAL NODE REFERENCES
## Root Control node for the Wunderpal UI.
@onready var wunderpal = $Wunderpal

## AnimationPlayer responsible for opening/closing the Wunderpal.
@onready var wunder_anim = $Wunderpal/AnimationPlayer

## Container holding the SubViewport used for side-scrolling scenes.
## Exists even when no scene is loaded.
@onready var ss_container := $Wunderpal/Frame/ScreenArea/GameViewportContainer

## SubViewport used to load and display side-scrolling gameplay scenes.
@onready var ss_viewport := $Wunderpal/Frame/ScreenArea/GameViewportContainer/GameViewport

@onready var debug_state_label: Label = $DebugStateLabel

var active_sidescroll: Node = null
#endregion


#region TAB STATE AND REFERENCES

@onready var inventory_root := $Wunderpal/Frame/ScreenArea/MENU_HUB
## Name of the currently active Wunderpal tab.
var current_tab : String = ""

## Inventory list UI (grid of items).
@onready var inventory_list = $Wunderpal/Frame/ScreenArea/MENU_HUB/Inventory_List

## Inventory detail panel (selected item information).
@onready var inventory_detail = $Wunderpal/Frame/ScreenArea/MENU_HUB/Inventory_Detail

## Quest list UI.
@onready var quest_list     = $Wunderpal/Frame/ScreenArea/MENU_HUB/Quest_List

## Quest detail panel.
@onready var quest_detail = $Wunderpal/Frame/ScreenArea/MENU_HUB/Quest_Detail

## Skill list UI.
@onready var skill_list     = $Wunderpal/Frame/ScreenArea/MENU_HUB/Skill_List

## Skill detail panel.
@onready var skill_detail = $Wunderpal/Frame/ScreenArea/MENU_HUB/Skill_Detail
#endregion


#region TAB BUTTON REFERENCES

## Inventory tab button.
@onready var btn_inventory = $Wunderpal/Frame/ScreenArea/MENU_HUB/Tabs/Btn_Inventory

## Quests tab button.
@onready var btn_quests = $Wunderpal/Frame/ScreenArea/MENU_HUB/Tabs/Btn_Quests

## Skills tab button.
@onready var btn_skills = $Wunderpal/Frame/ScreenArea/MENU_HUB/Tabs/Btn_Skills

## Mapping of tab names to their corresponding buttons.
## Used for simplified tab switching logic.
@onready var tab_buttons = {
	"inventory": $Wunderpal/Frame/ScreenArea/MENU_HUB/Tabs/Btn_Inventory,
	"quests": $Wunderpal/Frame/ScreenArea/MENU_HUB/Tabs/Btn_Quests,
	"skills": $Wunderpal/Frame/ScreenArea/MENU_HUB/Tabs/Btn_Skills
}
#endregion


#region TOOLTIP REFERENCES

## Tooltip root control.
@onready var tooltip: Control = $Tooltip

## Label displaying the item name in the tooltip.
@onready var tooltip_name: Label = $Tooltip/VBoxContainer/NameLabel

## Label displaying the item description in the tooltip.
@onready var tooltip_desc: Label = $Tooltip/VBoxContainer/DescLabel
#endregion


#region READY

## Initializes HUD connections, tab button callbacks,
## default state, and Wunderpal positioning.
func _ready():
	GameManager.toggle_wunderpal_requested.connect(_on_toggle_wunderpal)
	GameManager.hud = self

	tab_buttons["inventory"].pressed.connect(func():
		show_tab("inventory")
	)
	tab_buttons["quests"].pressed.connect(func():
		show_tab("quests")
	)
	tab_buttons["skills"].pressed.connect(func():
		show_tab("skills")
	)

	# Set default tab on startup
	show_tab("inventory")
	
	setup_wunderpal()
	
	tooltip.visible = false

#endregion


#region WUNDERPAL STATE VARIABLES

## Whether the Wunderpal is currently open.
var is_wunderpal_open := false

## Y-position of the Wunderpal when fully open.
var wunderpal_open_offset := 0

## Y-position of the Wunderpal when fully closed (off-screen).
var wunderpal_closed_offset := 0

## Duration (in seconds) of the open/close animation.
var slide_duration := 0.35

#endregion


#region WUNDERPAL INITIAL SETUP

## Calculates open and closed positions for the Wunderpal
## and initializes it in the closed state.
func setup_wunderpal():
	if wunderpal == null:
		push_warning("Wunderpal is NULL — did you forget to register nodes?")
		return

	# Open position = current Y offset
	wunderpal_open_offset = wunderpal.position.y

	# Closed position = pushed off-screen downward
	wunderpal_closed_offset = wunderpal_open_offset + wunderpal.size.y

	wunderpal.position.y = wunderpal_closed_offset
	wunderpal.visible = false

	print(
		"[HUD] Wunderpal initialized",
		"open =", wunderpal_open_offset,
		"closed =", wunderpal_closed_offset
	)

#endregion


#region WUNDERPAL TOGGLE

## Toggles the Wunderpal open or closed based on current state.
func toggle_wunderpal():
	slide_wunderpal(!is_wunderpal_open)

#endregion


#region WUNDERPAL SLIDE / ANIMATION

## Opens or closes the Wunderpal with animation.
## Updates game state and input routing accordingly.
## @param open Whether the Wunderpal should be opened.
func slide_wunderpal(open: bool):
		# Do not allow menu logic during side-scroll
	if GameManager.state == GameManager.GameState.SIDESCROLL:
		return
	is_wunderpal_open = open
	GameManager.state = GameManager.GameState.MENU_OPEN if open else GameManager.GameState.BOARD
	
	# Disable SubViewport input while menu is open
	ss_viewport.gui_disable_input = open
	
	if open:
		exit_sidescroll_mode()
		wunderpal.visible = true
		show_tab("inventory") # Ensure a valid default screen
		inventory_list.populate_inventory(GameManager.save_data["player"]["inventory"]["items"])
		wunder_anim.play("open_wunderpal")
	else:
		wunder_anim.play("close_wunderpal")
		await wunder_anim.animation_finished
		wunderpal.visible = false

#endregion


#region SIGNAL RECEIVER

## Handles Wunderpal toggle requests from the GameManager.
func _on_toggle_wunderpal():
	toggle_wunderpal()

#endregion


#region WUNDERPAL SCREENS & HELPERS
## Displays the requested tab and hides all others.
## @param tab_name Name of the tab to show.
func show_tab(tab_name: String):
	current_tab = tab_name

	_hide_all_screens()
	
	match tab_name:
		"inventory":
			inventory_list.visible = true
			inventory_list.populate_inventory(GameManager.save_data["player"]["inventory"]["items"])
		"quests":
			quest_list.visible = true
		"skills":
			skill_list.visible = true

## Hides all Wunderpal screens and disables mouse input
## for the SubViewport container.
func _hide_all_screens():
	ss_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_list.visible = false
	inventory_detail.visible = false
	quest_list.visible = false
	quest_detail.visible = false
	skill_list.visible = false
	skill_detail.visible = false
#endregion


#region TOOLTIP

## Displays the tooltip for an inventory item.
## @param item_data Dictionary containing item name and description.
## @param pos Global mouse position for tooltip placement.
func show_tooltip(item_data: Dictionary, pos: Vector2):
	if GameManager.state == GameManager.GameState.SIDESCROLL:
		return
	tooltip.visible = true
	tooltip.global_position = pos + Vector2(16, 16)
	tooltip_name.text = item_data.name
	tooltip_desc.text = item_data.description

## Hides the currently visible tooltip.
func hide_tooltip():
	tooltip.visible = false
#endregion


#region SIDESCROLL OPEN AND CLOSE
func open_sidescroll(scene_path: String):
	print("HUD.open_sidescroll:", scene_path)

	if scene_path == "":
		return
	if GameManager.state == GameManager.GameState.SIDESCROLL:
		return

	# Clean up any existing scene
	if active_sidescroll and is_instance_valid(active_sidescroll):
		active_sidescroll.queue_free()
		active_sidescroll = null
		await get_tree().process_frame

	GameManager.set_state(GameManager.GameState.SIDESCROLL)
	GameManager.save_data["world"]["sidescroll"]["active_scene"] = scene_path
	GameManager.set_active_sidescroll(scene_path)
	
	
	# 🔑 FORCE Wunderpal visible (no animation logic here)
	wunderpal.visible = true
	wunderpal.position.y = wunderpal_open_offset
	is_wunderpal_open = true

	# UI rules for sidescroll
	enter_sidescroll_mode()
	set_inventory_interactive(false)
	set_tabs_enabled(false)

	# Load scene
	var scene = load(scene_path).instantiate()
	ss_viewport.add_child(scene)
	active_sidescroll = scene
	ss_container.visible = true
	ss_viewport.gui_disable_input = false

	await get_tree().process_frame
	
	# Restore player position
	var player = scene.get_node_or_null("SoulForm")
	if not player:
		push_warning("SoulForm missing in sidescroll scene")
		return

	var saved_pos := GameManager.get_sidescroll_position(scene_path)
	if saved_pos != Vector2.ZERO:
		player.global_position = saved_pos

func exit_sidescroll():
	if GameManager.state != GameManager.GameState.SIDESCROLL:
		return

	if active_sidescroll and is_instance_valid(active_sidescroll):
		var player = active_sidescroll.get_node_or_null("SoulForm")
		if player:
			GameManager.set_sidescroll_position(
				GameManager.save_data["world"]["sidescroll"]["active_scene"],
				player.global_position
			)
		
		active_sidescroll.queue_free()
		active_sidescroll = null
		await get_tree().process_frame
	
	
	ss_container.visible = false
	ss_viewport.gui_disable_input = true
	
	wunderpal.visible = false
	is_wunderpal_open = false
	
	set_inventory_interactive(true)
	set_tabs_enabled(true)

	GameManager.set_state(GameManager.GameState.BOARD)

## Inventory Interactability
func set_inventory_interactive(enabled: bool):
	var filter := Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

	inventory_root.mouse_filter = filter

	for child in inventory_root.get_children():
		if child is Control:
			child.mouse_filter = filter

func set_tabs_enabled(enabled: bool):
	for btn in tab_buttons.values():
		btn.disabled = not enabled

## Helper function for entering side scroll mode
func enter_sidescroll_mode():
	_hide_all_screens()
	tooltip.visible = false

	# Hide tabs
	for btn in tab_buttons.values():
		btn.visible = false
	
	# Show device + sidescroll viewport
	wunderpal.visible = true
	wunderpal.show() # extra force for sanity
	wunderpal.position.y = wunderpal_open_offset
	
	ss_container.visible = true
	ss_viewport.gui_disable_input = false

## Helper function for exiting side scroll mode
func exit_sidescroll_mode():
	# Restore tabs
	for btn in tab_buttons.values():
		btn.visible = true

	# Hide side-scroll container
	ss_container.visible = false
	ss_viewport.gui_disable_input = true
	# Default back to inventory tab
	show_tab("inventory")
#endregion
