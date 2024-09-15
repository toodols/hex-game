local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local cells_mod = require(ReplicatedStorage.Shared.cells)

local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local hooks = require(ReplicatedStorage.Client.ui.hooks)
local themes = require(ReplicatedStorage.Client.ui.themes)
local EntityInformation = require(script.Parent.entity_information).EntityInformation
local CoordinateLabel = require(script.Parent.coordinate_label).CoordinateLabel
local util_components = require(ReplicatedStorage.Client.ui.util_components)

local Corner = util_components.Corner

type CubicCoordinate = types.CubicCoordinate
type HexGrid = types.HexGrid
type EntityId = types.EntityId
type GridUpdate = types.GridUpdate

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
					Position = UDim2.new(1, 0, 0.5, 0),
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
						Position = UDim2.new(0.292, 0, 0, 0),
						Size = UDim2.fromOffset(42, 40),
					}),
				}),

				Container = React.createElement("Frame", themes.theme_container {}, {
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

return {
	SelectedCellFrame = SelectedCellFrame,
}
