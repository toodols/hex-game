local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ContextActionService = game:GetService "ContextActionService"
local RunService = game:GetService "RunService"

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
local ui_types = require(ReplicatedStorage.Client.ui.types)

local Corner = util_components.Corner

type CubicCoordinate = types.CubicCoordinate
type World = types.World
type EntityId = types.EntityId
type WorldUpdate = types.WorldUpdate
type Submenu = ui_types.Submenu

function best_uncompressed_entity(world: World, entities_set: { [EntityId]: true })
	local candidate_uncompressed_entity: EntityId?
	local candidate_uncompressed_entity_layer: number?
	for entity_id in entities_set do
		local entity = world.entities[entity_id]
		if not entity or entity.is_destroyed then
			continue
		end
		if
			world.entity_configurations[entity.type].layer == shared_entity_mod.LAYER.building
			or not candidate_uncompressed_entity_layer
		then
			candidate_uncompressed_entity = entity_id
			candidate_uncompressed_entity_layer = world.entity_configurations[entity.type].layer
		end
	end
	return candidate_uncompressed_entity
end

function entities_from_cells(world: World, selected_cells: { CubicCoordinate })
	local entities_set = {}
	for _, coord in selected_cells do
		local cell = world:get_cell(coord)
		for entity_id in cell.entities do
			entities_set[entity_id] = true
		end
	end
	return entities_set
end

function SelectedCellFrame(props: { selected_cells: { CubicCoordinate } })
	local context = React.useContext(MainContext)
	local world = context.world

	local _, force_update = React.useReducer(function(x)
		return x + 1
	end, 0)

	local props_ref = React.useRef(props)
	props_ref.current = props

	local entities_set = entities_from_cells(world, props.selected_cells)
	local entities_ref = React.useRef(nil)
	entities_ref.current = util.table_keys(entities_set)
	table.sort(entities_ref.current, function(a, b)
		local a_layer = world.entity_configurations[world.entities[a].type].layer
		local b_layer = world.entity_configurations[world.entities[b].type].layer
		return a_layer > b_layer
	end)

	local uncompressed_entity = React.useRef(best_uncompressed_entity(world, entities_set))
	local gradient_ref = React.useRef(nil)
	local toggle_submenu = function(menu: Submenu)
		context.set_submenu(function(current)
			return if util.deep_equal(current, menu) then {} else menu
		end)
	end

	hooks.use_immediate_effect(function()
		local new_entities = entities_from_cells(world, props.selected_cells)
		if not new_entities[uncompressed_entity.current] then
			local best = best_uncompressed_entity(world, new_entities)
			uncompressed_entity.current = best
		end
	end, { props })

	React.useEffect(function()
		local cleanup = world.world_update_signal.listen(function(updates: { WorldUpdate })
			if
				uncompressed_entity.current == nil
				or not world.entities[uncompressed_entity.current]
				or world.entities[uncompressed_entity.current].is_destroyed
			then
				uncompressed_entity.current =
					best_uncompressed_entity(world, entities_from_cells(world, props_ref.current.selected_cells))
			end
			force_update(nil)
		end)
		return cleanup
	end, {})

	React.useEffect(function()
		if RunService:IsClient() then
			ContextActionService:BindAction("build", function(action_name, input_state, input_object)
				if input_state == Enum.UserInputState.Begin then
					toggle_submenu { type = "build", cell = props_ref.current.selected_cells[1] }
				end
			end, false, Enum.KeyCode.B)

			ContextActionService:BindAction("next_entity", function(action_name, input_state, input_object)
				if input_state == Enum.UserInputState.Begin then
					if uncompressed_entity.current == nil then
						uncompressed_entity.current = best_uncompressed_entity(
							world,
							entities_from_cells(world, props_ref.current.selected_cells)
						)
					else
						local current_idx = table.find(entities_ref.current, uncompressed_entity.current)
						current_idx = (current_idx % #entities_ref.current) + 1
						uncompressed_entity.current = entities_ref.current[current_idx]
					end
					force_update(nil)
				end
			end, false, Enum.KeyCode.RightBracket)

			ContextActionService:BindAction("previous_entity", function(action_name, input_state, input_object)
				if input_state == Enum.UserInputState.Begin then
					if uncompressed_entity.current == nil then
						uncompressed_entity.current = best_uncompressed_entity(
							world,
							entities_from_cells(world, props_ref.current.selected_cells)
						)
					else
						local current_idx = table.find(entities_ref.current, uncompressed_entity.current)
						current_idx = (current_idx - 2 + #entities_ref.current) % #entities_ref.current + 1
						uncompressed_entity.current = entities_ref.current[current_idx]
					end
					force_update(nil)
				end
			end, false, Enum.KeyCode.LeftBracket)

			return function()
				ContextActionService:UnbindAction "build"
			end
		end
		return function() end
	end, {})

	return React.createElement("Frame", {
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
			util.table_from_entries(util.table_map(entities_ref.current, function(entity_id, idx)
				return {
					entity_id,
					React.createElement(EntityInformation, {
						entity_id = entity_id,
						LayoutOrder = idx,
						compressed = uncompressed_entity.current ~= entity_id,
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

				BuildButton = if #props.selected_cells == 1
					then React.createElement("ImageButton", {
						AnchorPoint = Vector2.new(1, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 0.9,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						ClipsDescendants = true,
						[React.Event.MouseButton1Click] = function()
							toggle_submenu { type = "build", cell = props.selected_cells[1] }
						end,
						Position = UDim2.new(1, 0, 0.5, 0),
						Size = UDim2.new(0, 89, 0, 40),
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
							Position = UDim2.new(0.135, 0, -0.375, 0),
							Size = UDim2.new(0, 100, 0, 100),
						}),

						Image2 = React.createElement("ImageLabel", {
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Image = "rbxassetid://6034275725",
							Position = UDim2.new(0.292, 0, 0, 0),
							Size = UDim2.new(0, 42, 0, 40),
						}),
					})
					else nil,

				Container = React.createElement("Frame", themes.theme_container {}, {
					ListLayout = React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),

					Coordinate = if #props.selected_cells == 1
						then React.createElement(CoordinateLabel, { coordinate = props.selected_cells[1] })
						else nil,

					Title = React.createElement(
						"TextLabel",
						themes.theme_title {
							Text = if #props.selected_cells == 1
								then cells_mod.cell_names[world:get_cell(props.selected_cells[1]).type]
								else `{#props.selected_cells} Cells Selected`,
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
