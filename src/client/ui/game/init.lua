local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ContextActionService = game:GetService "ContextActionService"
local UserInputService = game:GetService "UserInputService"

local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local React = require(ReplicatedStorage.Packages.react)
local ReactRoblox = require(ReplicatedStorage.Packages["react-roblox"])
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)

local ui_types = require(ReplicatedStorage.Client.ui.types)
local themes = require(script.Parent.themes)
local hooks = require(script.Parent.hooks)
local context_mod = require(script.Parent.context)
local MainContext = context_mod.MainContext
local Recipes = require(script.recipes).Recipes
local BuildingsFrame = require(script.buildings_frame).BuildingsFrame
local PlayerList = require(script.player_list).PlayerList
local Research = require(script.research).Research
local TopCenter = require(script.top_center).TopCenter
local SelectedCellFrame = require(script.selected_cell_frame).SelectedCellFrame

local util_components = require(script.Parent.util_components)
local Corner = util_components.Corner

type HexGrid = types.HexGrid
type CubicCoordinate = types.CubicCoordinate
type Entity = types.Entity
type EntityId = types.EntityId
type GridUpdate = types.GridUpdate
type SelectionMode = ui_types.SelectionMode

function Main(props: { grid: HexGrid, selection_mode_stack: { SelectionMode }, update_highlights: () -> () })
	local submenu, set_submenu = React.useState {}
	hooks.use_immediate_effect(function()
		set_submenu {}
	end, { props })

	local selection_mode = props.selection_mode_stack[#props.selection_mode_stack]

	return React.createElement(MainContext.Provider, {
		value = {
			grid = props.grid,
			selection_mode_stack = props.selection_mode_stack,
			update_highlights = props.update_highlights,
		},
	}, {
		MainGui = React.createElement("ScreenGui", {
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			IgnoreGuiInset = true,
		}, {
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
			}),
			TopCenter = React.createElement(TopCenter),
			BottomCenter = React.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 0, 1, -20),
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
				SelectedCellFrame = selection_mode.type == "select_cells" and React.createElement(SelectedCellFrame, {
					selected_cells = util.table_map(util.table_keys(selection_mode.selected), function(k)
						return hex_grid_mod.decode_coord(props.grid.instance_cell_map[k])
					end),
					toggle_submenu = function(menu)
						set_submenu(function(current)
							return if util.deep_equal(current, menu) then {} else menu
						end)
					end,
				}),
				Recipes = submenu.type == "recipes" and React.createElement(Recipes, {
					entity_id = submenu.entity_id,
					on_close = function()
						set_submenu {}
					end,
				}),
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
						Size = UDim2.fromOffset(40, 40),
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
						}),

						Corner = React.createElement(Corner),
					}
				),
			}),
		}),
	})
end

function init_ui(grid)
	local nonce = 0
	local root = ReactRoblox.createRoot(Players.LocalPlayer.PlayerGui)
	local selection_mode_stack: { SelectionMode } = {
		{
			type = "select_cells",
			selected = {},
		},
	}

	local cell_instances_select = Instance.new "Model"
	cell_instances_select.Parent = grid.cell_instance_root
	cell_instances_select.Name = "Highlights"

	local cell_instances_hover = Instance.new "Model"
	cell_instances_hover.Parent = grid.cell_instance_root
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

	local mouse = Players.LocalPlayer:GetMouse()
	local cursor_instance: Instance? = nil
	local old_cursor_instance = nil
	local shift_select_type: "drag-include" | "drag-exclude" | "drag-unknown" | "off" = "off"

	local function refresh_highlight(highlight: Highlight, selected: { [Instance]: true })
		highlight.Adornee = nil :: any
		for _, instance in (highlight.Parent :: any):GetChildren() do
			if instance:IsA "Highlight" then
				continue
			end
			if not selected[instance] then
				instance.Parent = grid.cell_instance_root
			end
		end
		for instance in selected do
			instance.Parent = highlight.Parent
		end
		highlight.Adornee = highlight.Parent
	end

	local function update()
		if not cursor_instance then
			return
		end
		refresh_highlight(hover_highlight, {})
		local selection_mode = selection_mode_stack[#selection_mode_stack]
		if selection_mode.type == "select_cells" then
			-- update selected_highlight again
			refresh_highlight(selected_highlight, selection_mode.selected)
			if
				shift_select_type ~= "off"
				and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
				and cursor_instance ~= old_cursor_instance
			then
				if shift_select_type == "drag-unknown" then
					if selection_mode.selected[cursor_instance] then
						shift_select_type = "drag-exclude"
					else
						shift_select_type = "drag-include"
					end
				end
				if shift_select_type == "drag-include" then
					selection_mode.selected[cursor_instance] = true
				elseif shift_select_type == "drag-exclude" then
					selection_mode.selected[cursor_instance] = nil
				end

				nonce += 1
				root:render(React.createElement(Main, {
					nonce = nonce,
					grid = grid,
					update_highlights = update,
					selection_mode_stack = selection_mode_stack,
				}))

				-- selected_highlight.Adornee = nil :: any
				-- swap_out_children(cell_instances_select, grid.cell_instance_root, selected)
				-- selected_highlight.Adornee = cell_instances_select
				refresh_highlight(selected_highlight, selection_mode.selected)
			end

			refresh_highlight(hover_highlight, { [cursor_instance] = true })

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
			nonce += 1
			root:render(React.createElement(Main, {
				nonce = nonce,
				grid = grid,
				update_highlights = update,
				selection_mode_stack = selection_mode_stack,
			}))
		elseif selection_mode.type == "select_some_cell" then
			refresh_highlight(selected_highlight, selection_mode.candidates :: any)
			if selection_mode.candidates[cursor_instance] then
				hover_highlight.FillTransparency = 0.92
				refresh_highlight(hover_highlight, { [cursor_instance] = true })
			end
			nonce += 1
			root:render(React.createElement(Main, {
				nonce = nonce,
				grid = grid,
				update_highlights = update,
				selection_mode_stack = selection_mode_stack,
			}))
		end
	end

	-- on render
	local render_stepped_connection = RunService.RenderStepped:Connect(function()
		local raycast_params = RaycastParams.new()
		raycast_params.FilterType = Enum.RaycastFilterType.Include
		raycast_params.FilterDescendantsInstances = { grid.cell_instance_root }
		local unit_ray = mouse.UnitRay

		local raycast_result = workspace:Raycast(unit_ray.Origin, unit_ray.Direction * 1000, raycast_params)

		hover_highlight.Adornee = nil :: any
		old_cursor_instance = cursor_instance
		cursor_instance = nil

		if raycast_result then
			cursor_instance = raycast_result.Instance
			while cursor_instance and not grid.instance_cell_map[cursor_instance] do
				cursor_instance = cursor_instance.Parent
			end
			if cursor_instance then
				update()
			else
				error "unexpected"
			end
		else
			refresh_highlight(hover_highlight, {})
		end
	end)

	-- on select
	ContextActionService:BindAction("select_cell", function(_action_name, input_state, _input_object)
		if input_state == Enum.UserInputState.Begin then
			local selection_mode = selection_mode_stack[#selection_mode_stack]
			if selection_mode.type == "select_cells" then
				shift_select_type = "drag-unknown"
				if cursor_instance then
					if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
						if selection_mode.selected[cursor_instance] then
							shift_select_type = "drag-exclude"
						else
							shift_select_type = "drag-include"
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
					nonce += 1
					root:render(React.createElement(Main, {
						nonce = nonce,
						grid = grid,
						update_highlights = update,
						selection_mode_stack = selection_mode_stack,
					}))
					refresh_highlight(selected_highlight, selection_mode.selected)
				end
			elseif selection_mode.type == "select_direction" or selection_mode.type == "select_some_cell" then
				if selection_mode.candidates[cursor_instance] then
					selection_mode.on_selected(cursor_instance)
					selection_mode_stack[#selection_mode_stack] = nil
				end
				nonce += 1
				root:render(React.createElement(Main, {
					nonce = nonce,
					grid = grid,
					update_highlights = update,
					selection_mode_stack = selection_mode_stack,
				}))
			end
		elseif input_state == Enum.UserInputState.End then
			shift_select_type = "off"
		end
	end, false, Enum.UserInputType.MouseButton1)
	root:render(React.createElement(Main, {
		grid = grid,
		selection_mode_stack = selection_mode_stack,
		update_highlights = update,
		key = nonce,
	}))

	return {
		destroy = function()
			render_stepped_connection:Disconnect()
			ContextActionService:UnbindAction "select_cell"
		end,
	}
end

return {
	init_ui = init_ui,
}
