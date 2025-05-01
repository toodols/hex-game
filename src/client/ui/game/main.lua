local ReplicatedStorage = game:GetService "ReplicatedStorage"

local React = require(ReplicatedStorage.Packages.react)

local types = require(ReplicatedStorage.Shared.types)
local coords = require(ReplicatedStorage.Shared.coords)
local util = require(ReplicatedStorage.Shared.util)

local ui_types = require(ReplicatedStorage.Client.ui.types)
local hooks = require(ReplicatedStorage.Client.ui.hooks)
local themes = require(ReplicatedStorage.Client.ui.themes)
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext

local TileAlerts = require(ReplicatedStorage.Client.ui.game.tile_alerts).TileAlerts
local Research = require(ReplicatedStorage.Client.ui.game.research).Research
local PlayerList = require(ReplicatedStorage.Client.ui.game.player_list).PlayerList
local SettingsMenu = require(ReplicatedStorage.Client.ui.game.settings_menu).SettingsMenu
local TopCenter = require(ReplicatedStorage.Client.ui.game.top_center).TopCenter
local BuildingsFrame = require(ReplicatedStorage.Client.ui.game.buildings_frame).BuildingsFrame
local SelectedCellFrame = require(ReplicatedStorage.Client.ui.game.selected_cell_frame).SelectedCellFrame
local EntityInformation = require(ReplicatedStorage.Client.ui.game.entity_information).EntityInformation
local Recipes = require(ReplicatedStorage.Client.ui.game.recipes).Recipes
local ItemFilters = require(ReplicatedStorage.Client.ui.game.item_filters).ItemFilters

local Corner = util_components.Corner

type World = types.World
type SelectionMode = ui_types.SelectionMode

function Main(props: { world: World, selection_mode_stack: { SelectionMode } })
	local submenu, set_submenu = React.useState {}
	hooks.use_immediate_effect(function()
		set_submenu {}
	end, { props })

	local settings_open, set_settings_open = React.useState(false)

	local _, force_update = React.useReducer(function(x)
		return x + 1
	end, 0)

	local selection_mode = props.selection_mode_stack[#props.selection_mode_stack]

	local quest_effects = util.table_flat(util.table_map(util.table_keys(props.world.quests), function(quest_id)
		local quest = props.world.quests[quest_id]
		return quest.current_stage_data.effects
	end))

	return React.createElement(MainContext.Provider, {
		value = {
			world = props.world,
			selection_mode_stack = props.selection_mode_stack,
			quest_effects = quest_effects,
			force_update = force_update,
			submenu = submenu,
			set_submenu = set_submenu,
		},
	}, {
		TileAlerts = React.createElement(TileAlerts),

		Research = submenu.type == "research" and React.createElement(Research, {
			entity_id = submenu.entity_id,
			on_close = function()
				set_submenu {}
			end,
		}),

		Center = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 1, 0),
		}, {
			PlayerList = React.createElement(PlayerList),
			SettingsMenu = if settings_open then React.createElement(SettingsMenu) else nil,
		}),
		TopCenter = React.createElement(TopCenter),
		BottomCenter = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 1, -20),
			Size = UDim2.new(1, 0, 1, 0),
			Active = false,
			ZIndex = 2,
		}, {
			BuildingsFrame = submenu.type == "build" and React.createElement(BuildingsFrame, {
				cell = submenu.cell,
			}),
		}),
		BottomLeft = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 20, 1, -20),
		}, {
			HorizontalLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			}),
		}, {
			CancelButton = React.createElement(
				"TextButton",
				themes.theme_button {
					Visible = selection_mode.type == "select_some_cell_attack"
						or selection_mode.type == "select_direction",
					Text = "Cancel",
					Size = UDim2.new(0, 100, 0, 30),
					BackgroundColor3 = Color3.fromRGB(13, 13, 13),
					BackgroundTransparency = 0.2,
					[React.Event.MouseButton1Click] = function()
						props.selection_mode_stack[#props.selection_mode_stack] = nil
						force_update()
					end,
				},
				{
					Corner = React.createElement(Corner),
				}
			),
			SelectedCellFrame = if selection_mode.type == "select_cells"
				then React.createElement(SelectedCellFrame, {
					selected_cells = util.table_map(util.table_keys(selection_mode.selected), function(encoded_coord)
						return coords.decode_coord(encoded_coord)
					end),
				})
				else nil,
			OneEntityFrame = if selection_mode.type == "show_one_entity"
				then React.createElement("Frame", {
					AnchorPoint = Vector2.new(0, 1),
					BackgroundTransparency = 1,
					Position = UDim2.new(-250, 250, 20, -20),
					Size = UDim2.new(0, 250, 0, 300),
				}, {

					VerticalLayout = React.createElement("UIListLayout", {
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Bottom,
					}),
					Corner = React.createElement(Corner),
					Header = React.createElement(
						"Frame",
						themes.theme_solid {
							LayoutOrder = 1,
							Size = UDim2.new(1, 0, 0, 40),
						},
						{
							Corner = React.createElement(Corner),
							BackButton = React.createElement(
								"TextButton",
								themes.theme_button {
									Text = "Back",
									Size = UDim2.new(1, 0, 1, 0),
									[React.Event.MouseButton1Click] = function()
										props.selection_mode_stack[#props.selection_mode_stack] = nil
										force_update()
									end,
								}
							),
						}
					),
					Content = React.createElement(
						"Frame",
						themes.theme_background {
							AnchorPoint = Vector2.new(0.5, 0.5),
							AutomaticSize = Enum.AutomaticSize.Y,
							LayoutOrder = 2,
							Position = UDim2.new(0.5, 0, 0.5, 0),
							Size = UDim2.new(1, 0, 0, 0),
						},
						{
							VerticalLayout = React.createElement("UIListLayout", {
								Padding = UDim.new(0, 4),
								SortOrder = Enum.SortOrder.LayoutOrder,
							}),
							Padding = React.createElement("UIPadding", {
								PaddingBottom = UDim.new(0, 4),
								PaddingLeft = UDim.new(0, 4),
								PaddingRight = UDim.new(0, 4),
								PaddingTop = UDim.new(0, 4),
							}),
						},
						{
							Info = React.createElement(EntityInformation, {
								entity_id = selection_mode.entity_id,
								compressed = false,
								on_compress = function() end,
								on_select = function() end,
								toggle_submenu = function(menu)
									set_submenu(function(current)
										return if util.deep_equal(current, menu) then {} else menu
									end)
								end,
							}),
						}
					),
				})
				else nil,
			Recipes = if submenu.type == "recipes"
				then React.createElement(Recipes, {
					entity_id = submenu.entity_id,
					on_close = function()
						set_submenu {}
					end,
				})
				else nil,
			ItemFilters = if submenu.type == "item_filters"
				then React.createElement(ItemFilters, {
					entity_id = submenu.entity_id,
				})
				else nil,
		}),
	}, {
		BottomRight = React.createElement("Frame", {
			AnchorPoint = Vector2.new(1, 1),
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -20, 1, -20),
		}, {

			HorizontalLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			}),

			Settings = React.createElement(
				"Frame",
				themes.theme_solid {
					LayoutOrder = 1,
					Size = UDim2.new(0, 40, 0, 40),
				},
				{
					ImageButton = React.createElement("ImageButton", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Image = "rbxassetid://4062402439",
						ImageColor3 = Color3.fromRGB(255, 255, 255),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						Size = UDim2.new(1, -10, 1, -10),
						[React.Event.MouseButton1Click] = function()
							set_settings_open(not settings_open)
						end,
					}),

					Corner = React.createElement(Corner),
				}
			),
		}),
	})
end

return {
	Main = Main,
}
