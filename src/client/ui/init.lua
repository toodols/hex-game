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
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local cells_mod = require(ReplicatedStorage.Shared.cells)

local ui_types = require(script.types)
local themes = require(script.themes)
local hooks = require(script.hooks)
local context_mod = require(script.context)
local MainContext = context_mod.MainContext
local Recipes = require(script.recipes).Recipes
local Corner = require(script.corner).Corner
local BuildingsFrame = require(script.buildings_frame).BuildingsFrame
local EntityInformation = require(script.entity_information).EntityInformation
local Container = require(script.container).Container
local PlayerList = require(script.player_list).PlayerList
local Research = require(script.research).Research
local TopCenter = require(script.top_center).TopCenter

type HexGrid = types.HexGrid
type CubicCoordinate = types.CubicCoordinate
type Entity = types.Entity
type EntityId = types.EntityId
type GridUpdate = types.GridUpdate
type SelectionMode = ui_types.SelectionMode

function all_pad(padding: UDim)
	return {
		PaddingBottom = padding,
		PaddingLeft = padding,
		PaddingRight = padding,
		PaddingTop = padding,
	}
end

function CoordinateLabel(props: { coordinate: CubicCoordinate })
	return React.createElement(
		"TextButton",
		themes.theme_description {
			LayoutOrder = 1,
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromOffset(0, 20),
			Text = ("%s, %s, %s"):format(unpack(props.coordinate)),
		},
		{
			Corner = React.createElement(Corner),

			SidePad = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 5),
				PaddingRight = UDim.new(0, 5),
			}),
		}
	)
end

function best_uncompressed_entity(grid: HexGrid, entities: { EntityId })
	local candidate_uncompressed_entity: EntityId?
	local candidate_uncompressed_entity_layer: number?
	for _, entity_id in entities do
		local entity = grid.entities[entity_id]
		if not entity or entity.is_destroyed then
			continue
		end
		if
			shared_entity_mod.registry[entity.type].layer == shared_entity_mod.layer.building
			or not candidate_uncompressed_entity_layer
		then
			candidate_uncompressed_entity = entity_id
			candidate_uncompressed_entity_layer = shared_entity_mod.registry[entity.type].layer
		end
	end
	return candidate_uncompressed_entity
end

function SelectedCellFrame(props: { toggle_submenu: (submenu: any) -> (), selected_cells: { CubicCoordinate } })
	local context = React.useContext(MainContext)
	local grid = context.grid
	local entities = if props.selected_cells[1] then grid:get_cell(props.selected_cells[1]).entities else {}

	local _, force_update = React.useReducer(function(x)
		return x + 1
	end, 0)

	local props_ref = React.useRef(props)
	props_ref.current = props

	local uncompressed_entity = React.useRef(best_uncompressed_entity(grid, entities))
	local gradient_ref = React.useRef(nil)

	hooks.use_immediate_effect(function()
		local best = best_uncompressed_entity(
			grid,
			if props.selected_cells[1] then grid:get_cell(props.selected_cells[1]).entities else {}
		)
		uncompressed_entity.current = best
	end, { props })

	React.useEffect(function()
		local cleanup = grid.grid_update_signal.listen(function(updates: { GridUpdate })
			if
				uncompressed_entity.current == nil
				or not grid.entities[uncompressed_entity.current]
				or grid.entities[uncompressed_entity.current].is_destroyed
			then
				uncompressed_entity.current = best_uncompressed_entity(
					grid,
					if props_ref.current.selected_cells[1]
						then grid:get_cell(props_ref.current.selected_cells[1]).entities
						else {}
				)
			end
			force_update(nil)
		end)
		return cleanup
	end, {})

	if #props.selected_cells ~= 1 then
		return React.createElement(React.Fragment)
	end

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		Position = UDim2.new(-250, 250, 20, -20),
		Size = UDim2.fromOffset(250, 300),
	}, {
		VerticalLayout = React.createElement("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
		}),

		Corner = React.createElement(Corner),

		Content = React.createElement(
			"Frame",
			themes.theme_background {
				AnchorPoint = Vector2.new(0.5, 0.5),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 2,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 0),
			},
			{
				VerticalLayout = React.createElement("UIListLayout", {
					Padding = UDim.new(0, 4),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				Padding = React.createElement("UIPadding", all_pad(UDim.new(0, 4))),
			},
			util.table_from_entries(util.table_map(entities, function(entity_id)
				return {
					entity_id,
					React.createElement(EntityInformation, {
						entity_id = entity_id,
						compressed = uncompressed_entity.current ~= entity_id,
						toggle_submenu = props.toggle_submenu,
						on_select = function()
							uncompressed_entity.current = entity_id
							force_update(nil)
						end,
						on_compress = function()
							uncompressed_entity.current = nil
							force_update(nil)
						end,
					}),
				}
			end))
		),

		Header = React.createElement(
			"Frame",
			themes.theme_solid {
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 40),
			},
			{
				Corner = React.createElement(Corner),

				BuildButton = React.createElement("ImageButton", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.9,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					ClipsDescendants = true,
					[React.Event.MouseButton1Click] = function()
						props.toggle_submenu { type = "build", cell = props.selected_cells[1] }
					end,
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.fromOffset(89, 40),
				}, {
					Corner = React.createElement(Corner),

					Gradient = React.createElement("UIGradient", {
						Transparency = NumberSequence.new {
							NumberSequenceKeypoint.new(0, 1),
							NumberSequenceKeypoint.new(0.186, 0.331),
							NumberSequenceKeypoint.new(0.505, 0.369),
							NumberSequenceKeypoint.new(0.685, 1),
							NumberSequenceKeypoint.new(1, 1),
						},
					}),

					Stroke = React.createElement("UIStroke", {
						Color = Color3.fromRGB(170, 170, 170),
					}, {
						Gradient = React.createElement("UIGradient", {
							ref = gradient_ref,
							Transparency = NumberSequence.new {
								NumberSequenceKeypoint.new(0, 1),
								NumberSequenceKeypoint.new(0.443, 1),
								NumberSequenceKeypoint.new(0.649, 0.994),
								NumberSequenceKeypoint.new(1, 0),
							},
						}),
					}),

					Image1 = React.createElement("ImageLabel", {
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Image = "rbxassetid://6034275725",
						ImageTransparency = 0.9,
						Position = UDim2.fromScale(0.135, -0.375),
						Size = UDim2.fromOffset(100, 100),
					}),

					Image2 = React.createElement("ImageLabel", {
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Image = "rbxassetid://6034275725",
						Position = UDim2.fromScale(0.292, 0),
						Size = UDim2.fromOffset(42, 40),
					}),
				}),

				Container = React.createElement(Container, {}, {
					ListLayout = React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),

					Coordinate = React.createElement(CoordinateLabel, { coordinate = props.selected_cells[1] }),

					Title = React.createElement(
						"TextLabel",
						themes.theme_title {
							Text = cells_mod.cell_names[grid:get_cell(props.selected_cells[1]).type],
							TextSize = 23,
						},
						{
							SidePad = React.createElement("UIPadding", {
								PaddingLeft = UDim.new(0, 15),
								PaddingRight = UDim.new(0, 8),
							}),
						}
					),

					Corner = React.createElement(Corner),
				}),
			}
		),
	})
end

function Main(props: { grid: HexGrid, selection_mode_stack: { SelectionMode }, update_highlights: () -> () })
	local submenu, set_submenu = React.useState {}
	hooks.use_immediate_effect(function()
		set_submenu {}
	end, props)

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
					selected_cells = util.table_map(util.table_keys(selection_mode.selected), function(instance)
						return hex_grid_mod.decode_coord(props.grid.instance_cell_map[instance])
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
							Position = UDim2.fromScale(0.5, 0.5),
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
		for _, instance in highlight.Parent:GetChildren() do
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
