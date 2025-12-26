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

@onready var main_menu := $Wunderpal/Frame/ScreenArea/MENU_HUB/Main_Menu
@onready var main_menu_vbox := $Wunderpal/Frame/ScreenArea/MENU_HUB/Main_Menu/VBoxContainer
#endregion


#region PAGE ROUTER
@onready var page_host: Control = $Wunderpal/Frame/ScreenArea

var current_page_id: String = ""
var current_page: Control = null
var page_cache: Dictionary = {}

const PAGE_REGISTRY := {
	# "inventory": preload("res://scenes/ui/inventory.tscn"),
	# scaffolding (add later)
	# "cards": preload("res://data/ui/cards_page.tscn"),
	# "skills": preload("res://data/ui/skills_page.tscn"),
	# "runes": preload("res://data/ui/runes_page.tscn"),
	# "quests": preload("res://data/ui/quests_page.tscn"),
}

func open_page(page_id: String) -> void:
	# Ensure section exists
	if not WUNDERPAL_SECTIONS.has(page_id):
		push_warning("HUD.open_page(): Unknown page id: %s" % page_id)
		return

	# Open wunderpal if needed
	if not is_wunderpal_open:
		slide_wunderpal(true)

	# Switch logical section (legacy-safe)
	_show_legacy_tab(page_id)

	current_page_id = page_id

func _clear_current_page() -> void:
	if current_page and is_instance_valid(current_page):
		current_page.queue_free()

	current_page = null
	current_page_id = ""

func close_all_pages() -> void:
	current_page_id = ""
#endregion


#region WUNDERPAL SECTIONS
const WUNDERPAL_SECTIONS := {
	"inventory": {
		"label": "Inventory",
		"panel": "Inventory_List",
		"requires": null
	},
	"cards": {
		"label": "Cards",
		"panel": "Cards_Panel",
		"requires": null
	},
	"skills": {
		"label": "Skills",
		"panel": "Skill_List",
		"requires": null
	},
	"quests": {
		"label": "Quests",
		"panel": "Quest_List",
		"requires": null
	},
	"rune": {
		"label": "Rune",
		"panel": "Rune_Panel",
		"requires": "rune_tile"
	},
	"shop": {
		"label": "Shop",
		"panel": "Shop_Panel",
		"requires": "shop_tile"
	}
}
#endregion


#region PAGE STATE AND REFERENCES

@onready var inventory_root := $Wunderpal/Frame/ScreenArea/MENU_HUB
## Name of the currently active Wunderpal tab.
var current_tab : String = ""

## Inventory list UI (grid of items).
@onready var inventory_list = $Wunderpal/Frame/ScreenArea/MENU_HUB/Inventory_List

## Quest list UI.
@onready var quest_list     = $Wunderpal/Frame/ScreenArea/MENU_HUB/Quest_List

## Skill list UI.
@onready var skill_list     = $Wunderpal/Frame/ScreenArea/MENU_HUB/Skill_List


@onready var skill_grid: GridContainer = \
	$Wunderpal/Frame/ScreenArea/MENU_HUB/Skill_List/ScrollContainer/Grid

@onready var quest_grid: GridContainer = \
	$Wunderpal/Frame/ScreenArea/MENU_HUB/Quest_List/ScrollContainer/Grid

@onready var cards_grid: GridContainer = \
	$Wunderpal/Frame/ScreenArea/MENU_HUB/Cards_Panel/ScrollContainer/Grid
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

	
	setup_wunderpal()
	build_main_menu()
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

		if current_page_id == "":
			_show_legacy_tab("inventory")

		inventory_list.populate_inventory(
			GameManager.save_data["player"]["inventory"]["items"]
		)
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
## LEGACY: Displays the requested tab and hides all others.
## @param tab_name Name of the tab to show.
func _show_legacy_tab(tab_name: String):
	current_tab = tab_name
	_hide_all_screens()

	match tab_name:
		"inventory":
			inventory_list.visible = true
			inventory_list.populate_inventory(
				GameManager.save_data["player"]["inventory"]["items"]
			)

		"quests":
			quest_list.visible = true
			populate_empty_grid(quest_grid, 8)

		"skills":
			skill_list.visible = true
			populate_empty_grid(skill_grid, 12)

		"cards":
			$Wunderpal/Frame/ScreenArea/MENU_HUB/Cards_Panel.visible = true
			populate_empty_grid(cards_grid, 6)
		
		
		"rune", "shop":
			_show_placeholder(tab_name)
## Hides all Wunderpal screens and disables mouse input
## for the SubViewport container.
func _hide_all_screens():
	ss_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_list.visible = false
	# inventory_detail.visible = false
	quest_list.visible = false
	# quest_detail.visible = false
	skill_list.visible = false
	# skill_detail.visible = false
	var menu_hub := $Wunderpal/Frame/ScreenArea/MENU_HUB

	if menu_hub.has_node("Cards_Panel"):
		menu_hub.get_node("Cards_Panel").visible = false

	if menu_hub.has_node("Rune_Panel"):
		menu_hub.get_node("Rune_Panel").visible = false

	if menu_hub.has_node("Shop_Panel"):
		menu_hub.get_node("Shop_Panel").visible = false

func _show_placeholder(section: String):
	for c in inventory_root.get_children():
		if c is Label and c.text.ends_with("(Coming Soon)"):
			c.queue_free()
	
	print("[HUD] Placeholder panel for:", section)

	# Simple visual confirmation for now
	var label := Label.new()
	label.text = section.capitalize() + " (Coming Soon)"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	inventory_root.add_child(label)
	label.visible = true

func show_section(section: String):
	
	if not WUNDERPAL_SECTIONS.has(section):
		push_warning("Unknown section: %s" % section)
		return

	if not _section_is_allowed(section):
		print("[Wunderpal] Section blocked:", section)
		return

	current_tab = section
	_hide_all_screens()

	var panel_name = WUNDERPAL_SECTIONS[section].panel

	if has_node("Wunderpal/Frame/ScreenArea/MENU_HUB/" + panel_name):
		var panel = get_node(
			"Wunderpal/Frame/ScreenArea/MENU_HUB/" + panel_name
		)
		panel.visible = true
	else:
		# fallback to legacy behavior
		push_warning("Panel missing for section: %s" % section)

func _section_is_allowed(section: String) -> bool:
	var rule = WUNDERPAL_SECTIONS[section]["requires"]

	if rule == null:
		return true

	match rule:
		"shop_tile":
			return GameManager.save_data["world"].get("active_shop_id", "") != ""
		"rune_tile":
			return GameManager.save_data["world"].get("on_rune_tile", false)

	return false

func clear_children(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()
		
func build_main_menu():
	clear_children(main_menu_vbox)

	for section_id in WUNDERPAL_SECTIONS.keys():
		var data = WUNDERPAL_SECTIONS[section_id]

		var btn := Button.new()
		btn.text = data.label
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_ALL

		btn.pressed.connect(func():
			open_page(section_id)
		)

		main_menu_vbox.add_child(btn)

func clear_active_panel() -> void:
	for c in $Wunderpal/Frame/ScreenArea/MENU_HUB.get_children():
		if c is Control:
			c.visible = false

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
func open_sidescroll(scene_id: String):
	print("HUD.open_sidescroll:", scene_id)

	if scene_id == "":
		return
	if GameManager.state == GameManager.GameState.SIDESCROLL:
		return

	# Clean up any existing scene
	if active_sidescroll and is_instance_valid(active_sidescroll):
		active_sidescroll.queue_free()
		active_sidescroll = null
		await get_tree().process_frame

	GameManager.set_state(GameManager.GameState.SIDESCROLL)
	GameManager.save_data["world"]["sidescroll"]["active_scene"] = scene_id
	GameManager.set_active_sidescroll(scene_id)
	
	
	# 🔑 FORCE Wunderpal visible (no animation logic here)
	wunderpal.visible = true
	wunderpal.position.y = wunderpal_open_offset
	is_wunderpal_open = true

	# UI rules for sidescroll
	enter_sidescroll_mode()
	set_inventory_interactive(false)

	# Load scene
	var path := GameManager.resolve_scene_path(scene_id)
	if path == "":
		return

	var scene = load(path).instantiate()
	
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

	var saved_pos := GameManager.get_sidescroll_position(scene_id)
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

	GameManager.set_state(GameManager.GameState.BOARD)

## Inventory Interactability
func set_inventory_interactive(enabled: bool):
	var filter := Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

	inventory_root.mouse_filter = filter

	for child in inventory_root.get_children():
		if child is Control:
			child.mouse_filter = filter


## Helper function for entering side scroll mode
func enter_sidescroll_mode():
	_hide_all_screens()
	tooltip.visible = false

	# Hide tabs
	
	# Show device + sidescroll viewport
	wunderpal.visible = true
	wunderpal.show() # extra force for sanity
	wunderpal.position.y = wunderpal_open_offset
	
	ss_container.visible = true
	ss_viewport.gui_disable_input = false

## Helper function for exiting side scroll mode
func exit_sidescroll_mode():

	# Hide side-scroll container
	ss_container.visible = false
	ss_viewport.gui_disable_input = true
	# Default back to inventory tab
	open_page("inventory")
#endregion

#region POPULATE EMPTY GRIDS

func populate_empty_grid(
	grid: GridContainer,
	slot_count: int = 16
) -> void:
	# Clear old slots
	for c in grid.get_children():
		c.queue_free()

	for i in range(slot_count):
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(48, 48)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_theme_stylebox_override(
			"panel",
			get_theme_stylebox("panel", "Panel")
		)
		grid.add_child(slot)
#endregion
