local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ContextActionService = game:GetService "ContextActionService"
local TweenService = game:GetService "TweenService"
local Players = game:GetService "Players"

local React = require(ReplicatedStorage.Packages.react)

local types = require(ReplicatedStorage.Shared.types)
local coords = require(ReplicatedStorage.Shared.coords)
local util = require(ReplicatedStorage.Shared.util)

local ui_types = require(ReplicatedStorage.Client.ui.types)
local hooks = require(ReplicatedStorage.Client.ui.hooks)
local themes = require(ReplicatedStorage.Client.ui.themes)
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local context = require(ReplicatedStorage.Client.ui.context)
local MainContext = context.MainContext
local SettingsContext = context.SettingsContext

local TileAlerts = require(script.Parent.tile_alerts).TileAlerts
local Research = require(script.Parent.research).Research
local PlayerList = require(script.Parent.player_list).PlayerList
local SettingsMenu = require(script.Parent.settings_menu).SettingsMenu
local BuildingsFrame = require(script.Parent.buildings_frame).BuildingsFrame
local SelectedCellFrame = require(script.Parent.selected_cell_frame).SelectedCellFrame
local EntityInformation = require(script.Parent.entity_information).EntityInformation
local Recipes = require(script.Parent.recipes).Recipes
local ItemFilters = require(script.Parent.item_filters).ItemFilters
local Credits = require(script.Parent.credits).Credits
local Encyclopedia = require(script.Parent.encyclopedia).Encyclopedia
local TopCenter = require(script.Parent.top_center).TopCenter
local Conclusion = require(script.Parent.conclusion).Conclusion

local Corner = util_components.Corner

local local_player = Players.LocalPlayer

type World = types.World
type SelectionMode = ui_types.SelectionMode

function MenuIcon(props: { on_click: () -> (), label: string, icon: string })
	local ref = React.useRef(nil :: any)
	local layout_ref = React.useRef(nil :: any)
	return React.createElement(
		"TextButton",
		themes.theme_solid {
			Text = "",
			Size = UDim2.new(0, 40, 0, 40),
			ClipsDescendants = true,
			ref = ref,
			[React.Event.MouseButton1Click] = props.on_click,
			[React.Event.MouseEnter] = function()
				local width = layout_ref.current.AbsoluteContentSize.X
				TweenService:Create(ref.current, TweenInfo.new(0.2), {
					Size = UDim2.new(0, width, 0, 40),
				}):Play()
			end,
			[React.Event.MouseLeave] = function()
				TweenService:Create(ref.current, TweenInfo.new(0.2), {
					Size = UDim2.new(0, 40, 0, 40),
				}):Play()
			end,
		},
		{
			HorizontalLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,

				ref = layout_ref,
			}),
			Label = React.createElement(
				"TextLabel",
				themes.theme_label {
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.new(0, 0, 1, 0),
					Text = props.label,
					TextSize = 14,
					LayoutOrder = 1,
				},
				{
					Padding = React.createElement("UIPadding", {
						PaddingLeft = UDim.new(0, 5),
					}),
				}
			),
			Icon = React.createElement("Frame", {
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				Size = UDim2.new(0, 40, 0, 40),
				ClipsDescendants = true,
			}, {
				ImageButton = React.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Image = props.icon,
					ImageColor3 = Color3.fromRGB(255, 255, 255),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(1, -10, 1, -10),
				}),
			}),

			Corner = React.createElement(Corner),
		}
	)
end

function Main(props: { world: World, selection_mode_stack: { SelectionMode } })
	local submenu, set_submenu = React.useState {}
	hooks.use_immediate_effect(function()
		set_submenu {}
	end, { props })

	local settings_open, set_settings_open = React.useState(false)
	local credits_open, set_credits_open = React.useState(false)
	local encyclopedia_open, set_encyclopedia_open = React.useState(false)

	local _, force_update = React.useReducer(function(x)
		return x + 1
	end, 0)
	local players_visible, set_players_visible = React.useState(false)

	local selection_mode = props.selection_mode_stack[#props.selection_mode_stack]

	local quest_effects = util.table_flat(util.table_map(util.table_keys(props.world.quests), function(quest_id)
		local quest = props.world.quests[quest_id]
		return quest.current_stage_data.effects
	end))

	React.useEffect(function()
		if RunService:IsClient() then
			ContextActionService:BindAction("player_list", function(actionName, inputState, inputObject)
				if inputState == Enum.UserInputState.Begin then
					set_players_visible(true)
				elseif inputState == Enum.UserInputState.End then
					set_players_visible(false)
				end
			end, false, Enum.KeyCode.T)
		end
		return function()
			if RunService:IsClient() then
				ContextActionService:UnbindAction "player_list"
			end
		end
	end, {})

	React.useEffect(function()
		local cleanup = props.world.world_update_signal.listen(function(updates)
			for _, update in updates do
				if update.type == "player_data" then
					force_update(nil)
				end
			end
		end)
		return cleanup
	end, {})

	return React.createElement(
		MainContext.Provider,
		{
			value = {
				world = props.world,
				selection_mode_stack = props.selection_mode_stack,
				quest_effects = quest_effects,
				force_update = force_update,
				submenu = submenu,
				set_submenu = set_submenu,
			},
		},
		React.createElement(SettingsContext.Provider, {
			value = if local_player then props.world.player_data[tostring(local_player.UserId)].settings else nil,
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
				PlayerList = React.createElement(PlayerList, {
					visible = players_visible,
				}),
				SettingsMenu = if settings_open then React.createElement(SettingsMenu) else nil,
				Credits = if credits_open then React.createElement(Credits) else nil,
				Encyclopedia = if encyclopedia_open then React.createElement(Encyclopedia) else nil,
				Conclusion = React.createElement(Conclusion),
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
						Visible = selection_mode.type == "select_some_cell",
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
						selected_cells = util.table_map(
							util.table_keys(selection_mode.selected),
							function(encoded_coord)
								return coords.decode_coord(encoded_coord)
							end
						),
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

				VerticalLyaout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
				}),
				Encyclopedia = React.createElement(MenuIcon, {
					icon = "rbxassetid://6034509994",
					label = "Encyclopedia",
					on_click = function()
						set_encyclopedia_open(not encyclopedia_open)
					end,
				}),
				Players = React.createElement(MenuIcon, {
					icon = "rbxassetid://6035053279",
					label = "Players",
					on_click = function()
						set_players_visible(not players_visible)
					end,
				}),
				Settings = React.createElement(MenuIcon, {
					label = "Settings",
					icon = "rbxassetid://6031280882",
					on_click = function()
						set_settings_open(not settings_open)
					end,
				}),
				Credits = React.createElement(MenuIcon, {
					label = "<3",
					icon = "rbxassetid://6023426974",
					on_click = function()
						set_credits_open(not credits_open)
					end,
				}),
			}),
		})
	)
end

return {
	Main = Main,
}
