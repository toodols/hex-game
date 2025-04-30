local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ContextActionService = game:GetService "ContextActionService"
local UserInputService = game:GetService "UserInputService"

local React = require(ReplicatedStorage.Packages.react)
local coords = require(ReplicatedStorage.Shared.coords)
local ReactRoblox = require(ReplicatedStorage.Packages["react-roblox"])
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local ui_types = require(ReplicatedStorage.Client.ui.types)

local themes = require(script.Parent.themes)
local hooks = require(script.Parent.hooks)
local context_mod = require(script.Parent.context)
local util_components = require(script.Parent.util_components)

local Recipes = require(script.recipes).Recipes
local BuildingsFrame = require(script.buildings_frame).BuildingsFrame
local PlayerList = require(script.player_list).PlayerList
local Research = require(script.research).Research
local TopCenter = require(script.top_center).TopCenter
local SelectedCellFrame = require(script.selected_cell_frame).SelectedCellFrame
local TileAlerts = require(script.tile_alerts).TileAlerts
local ItemFilters = require(script.item_filters).ItemFilters
local EntityInformation = require(script.entity_information).EntityInformation
local SettingsMenu = require(script.settings_menu).SettingsMenu

local MainContext = context_mod.MainContext
local Corner = util_components.Corner

local client_interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

type World = types.World
type CubicCoordinate = types.CubicCoordinate
type Entity = types.Entity
type EntityId = types.EntityId
type WorldUpdate = types.WorldUpdate
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
					selected_cells = util.table_map(util.table_keys(selection_mode.selected), function(k)
						return coords.decode_coord(props.world.instance_cell_map[k])
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

function init_ui(world: World, root_instance_: ScreenGui?)
	local root_instance = root_instance_
	if root_instance == nil then
		root_instance = Instance.new "ScreenGui"
		root_instance.Name = "MainGui"
		root_instance.ResetOnSpawn = false
		root_instance.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		root_instance.IgnoreGuiInset = true
		root_instance.Parent = Players.LocalPlayer:WaitForChild "PlayerGui"
	end
	local root = ReactRoblox.createRoot(root_instance)
	local selection_mode_stack: { SelectionMode } = {
		{
			type = "select_cells",
			selected = {},
		},
	}

	local cell_instances_select = Instance.new "Model"
	cell_instances_select.Parent = world.cell_instance_root
	cell_instances_select.Name = "Highlights"

	local cell_instances_hover = Instance.new "Model"
	cell_instances_hover.Parent = world.cell_instance_root
	cell_instances_hover.Name = "HighlightsHover"

	local hover_highlight: Highlight = Instance.new "Highlight"
	hover_highlight.Parent = cell_instances_hover
	hover_highlight.Adornee = cell_instances_hover
	hover_highlight.FillTransparency = 1
	hover_highlight.FillColor = Color3.fromRGB(0, 255, 0)

	local selected_highlight: Highlight = Instance.new "Highlight"
	selected_highlight.Adornee = cell_instances_select
	selected_highlight.Parent = cell_instances_select
	selected_highlight.FillTransparency = 0.9
	selected_highlight.OutlineTransparency = 0.5
	selected_highlight.FillColor = Color3.fromRGB(0, 255, 0)

	local cursor_instance: Instance? = nil
	local old_cursor_instance = nil
	local shift_select_type: "drag_include" | "drag_exclude" | "drag_unknown" | "off" = "off"

	local function refresh_highlight(highlight: Highlight, selected: { [Instance]: true })
		highlight.Adornee = nil :: any
		for _, instance in (highlight.Parent :: any):GetChildren() do
			if instance:IsA "Highlight" then
				continue
			end
			if not selected[instance] then
				instance.Parent = world.cell_instance_root
			end
		end
		for instance in selected do
			instance.Parent = highlight.Parent
		end
		highlight.Adornee = highlight.Parent
	end

	local function update_selected()
		refresh_highlight(hover_highlight, {})
		local selection_mode = selection_mode_stack[#selection_mode_stack]
		if selection_mode.type == "select_cells" then
			-- update selected_highlight again
			refresh_highlight(selected_highlight, selection_mode.selected)
			if
				shift_select_type ~= "off"
				and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
				and cursor_instance ~= old_cursor_instance
				and cursor_instance ~= nil
			then
				if shift_select_type == "drag_unknown" then
					if selection_mode.selected[cursor_instance] then
						shift_select_type = "drag_exclude"
					else
						shift_select_type = "drag_include"
					end
				end
				if shift_select_type == "drag_include" then
					selection_mode.selected[cursor_instance] = true
				elseif shift_select_type == "drag_exclude" then
					selection_mode.selected[cursor_instance] = nil
				end

				root:render(React.createElement(Main, {
					world = world,
					selection_mode_stack = selection_mode_stack,
				}))

				refresh_highlight(selected_highlight, selection_mode.selected)
			end
			if cursor_instance then
				refresh_highlight(hover_highlight, { [cursor_instance] = true })
			end

			if selection_mode.selected[cursor_instance] then
				hover_highlight.FillTransparency = 0.92
			else
				hover_highlight.FillTransparency = 1
			end
		elseif selection_mode.type == "select_direction" then
			refresh_highlight(selected_highlight, selection_mode.candidates :: any)
			if selection_mode.candidates[cursor_instance] then
				hover_highlight.FillTransparency = 0.92
				refresh_highlight(hover_highlight, selection_mode.candidates[cursor_instance])
			end
			root:render(React.createElement(Main, {
				world = world,
				selection_mode_stack = selection_mode_stack,
			}))
		elseif selection_mode.type == "select_some_cell" then
			refresh_highlight(selected_highlight, selection_mode.candidates :: any)
			if cursor_instance and selection_mode.candidates[cursor_instance] then
				hover_highlight.FillTransparency = 0.92
				refresh_highlight(hover_highlight, { [cursor_instance] = true })
			end
			root:render(React.createElement(Main, {
				world = world,
				selection_mode_stack = selection_mode_stack,
			}))
		elseif selection_mode.type == "show_cells" then
			refresh_highlight(selected_highlight, selection_mode.cells :: any)
		end
	end

	local render_stepped_connection
	if RunService:IsClient() then
		local mouse = Players.LocalPlayer:GetMouse()
		-- on render
		render_stepped_connection = RunService.RenderStepped:Connect(function()
			local raycast_params = RaycastParams.new()
			raycast_params.FilterType = Enum.RaycastFilterType.Include
			raycast_params.FilterDescendantsInstances = { world.cell_instance_root }
			local unit_ray = mouse.UnitRay

			local raycast_result = workspace:Raycast(unit_ray.Origin, unit_ray.Direction * 1000, raycast_params)

			hover_highlight.Adornee = nil :: any
			old_cursor_instance = cursor_instance
			cursor_instance = nil

			if raycast_result then
				cursor_instance = raycast_result.Instance
				while cursor_instance and not world.instance_cell_map[cursor_instance] do
					cursor_instance = cursor_instance.Parent
				end
			end
			update_selected()
		end)

		-- on select
		ContextActionService:BindAction("select_cell", function(_action_name, input_state, _input_object)
			if input_state == Enum.UserInputState.Begin then
				local selection_mode = selection_mode_stack[#selection_mode_stack]
				if selection_mode.type == "select_cells" then
					shift_select_type = "drag_unknown"
					if cursor_instance then
						if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
							if selection_mode.selected[cursor_instance] then
								shift_select_type = "drag_exclude"
							else
								shift_select_type = "drag_include"
							end
							if selection_mode.selected[cursor_instance] then
								selection_mode.selected[cursor_instance] = nil
							else
								selection_mode.selected[cursor_instance] = true
							end
						else
							selection_mode.selected = { [cursor_instance] = true }
						end
						-- update selected
						root:render(React.createElement(Main, {
							world = world,
							selection_mode_stack = selection_mode_stack,
						}))
						refresh_highlight(selected_highlight, selection_mode.selected)
						client_interaction_remote:FireServer {
							{
								type = "tutorial_report_selection",
								selected = util.table_map(util.table_keys(selection_mode.selected), function(instance)
									return coords.decode_coord(world.instance_cell_map[instance])
								end),
							},
						}
					end
				elseif selection_mode.type == "select_direction" or selection_mode.type == "select_some_cell" then
					if selection_mode.candidates[cursor_instance] then
						selection_mode.on_selected(cursor_instance)
						selection_mode_stack[#selection_mode_stack] = nil
					end
					root:render(React.createElement(Main, {
						world = world,
						selection_mode_stack = selection_mode_stack,
					}))
				end
			elseif input_state == Enum.UserInputState.End then
				shift_select_type = "off"
			end
		end, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)
	end

	root:render(React.createElement(Main, {
		world = world,
		selection_mode_stack = selection_mode_stack,
	}))

	return {
		root = root,
		update = function()
			root:render(React.createElement(Main, {
				world = world,
				selection_mode_stack = selection_mode_stack,
			}))
		end,
		selection_mode_stack = selection_mode_stack,
		destroy = function()
			if RunService:IsClient() then
				render_stepped_connection:Disconnect()
				ContextActionService:UnbindAction "select_cell"
				root:unmount()
			end
		end,
	}
end

return {
	init_ui = init_ui,
}
