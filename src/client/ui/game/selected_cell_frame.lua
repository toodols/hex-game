local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ContextActionService = game:GetService "ContextActionService"
local RunService = game:GetService "RunService"

local React = require(ReplicatedStorage.Packages.react)

local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local cells_mod = require(ReplicatedStorage.Shared.cells)
local deposit_mod = require(ReplicatedStorage.Shared.deposit)

local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local hooks = require(ReplicatedStorage.Client.ui.hooks)
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local ui_types = require(ReplicatedStorage.Client.ui.types)
local KeybindLabel = require(ReplicatedStorage.Client.ui.keybind_label).KeybindLabel

local EntityInformation = require(script.Parent.entity_information).EntityInformation
local CoordinateLabel = require(script.Parent.coordinate_label).CoordinateLabel

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
			local entity = world.entities[entity_id]
			local config = world.entity_configurations[entity.type]
			if config.internal then
				continue
			end
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

	local function get_previous()
		if uncompressed_entity.current == nil then
			return best_uncompressed_entity(world, entities_from_cells(world, props_ref.current.selected_cells))
		else
			local current_idx = table.find(entities_ref.current, uncompressed_entity.current)
			if current_idx == nil then
				return best_uncompressed_entity(world, entities_from_cells(world, props_ref.current.selected_cells))
			end
			return entities_ref.current[(current_idx - 2 + #entities_ref.current) % #entities_ref.current + 1]
		end
	end
	local function get_next()
		if uncompressed_entity.current == nil then
			return best_uncompressed_entity(world, entities_from_cells(world, props_ref.current.selected_cells))
		else
			local current_idx = table.find(entities_ref.current, uncompressed_entity.current)
			if current_idx == nil then
				return best_uncompressed_entity(world, entities_from_cells(world, props_ref.current.selected_cells))
			else
				return entities_ref.current[(current_idx % #entities_ref.current) + 1]
			end
		end
	end

	local next_entity = get_next()
	local previous_entity = get_previous()

	-- React.useEffect(function()
	-- 	if RunService:IsClient() then
	-- 		ContextActionService:BindAction("next_entity", function(action_name, input_state, input_object)
	-- 			if input_state == Enum.UserInputState.Begin then
	-- 				uncompressed_entity.current = get_next()
	-- 				force_update(nil)
	-- 			end
	-- 		end, false, Enum.KeyCode.RightBracket)

	-- 		ContextActionService:BindAction("previous_entity", function(action_name, input_state, input_object)
	-- 			if input_state == Enum.UserInputState.Begin then
	-- 				uncompressed_entity.current = get_previous()
	-- 				force_update(nil)
	-- 			end
	-- 		end, false, Enum.KeyCode.LeftBracket)

	-- 		return function()
	-- 			ContextActionService:UnbindAction "build"
	-- 		end
	-- 	end
	-- 	return function() end
	-- end, {})

	local deposit_type = nil
	if #props.selected_cells == 1 then
		deposit_type = deposit_mod.get_deposit_type(world, props.selected_cells[1])
	end
	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(-250, 250, 20, -20),
		Size = UDim2.new(0, 250, 0, 300),
		[React.Tag] = "align-br list-v list-bc",
	}, {
		Content = React.createElement(
			"Frame",
			{
				LayoutOrder = 2,
				[React.Tag] = "background container-v align-cc list-v list-pad-5 pad-5",
			},
			util.table_from_entries(util.table_map(entities_ref.current, function(entity_id, idx)
				return {
					entity_id,
					React.createElement(EntityInformation, {
						entity_id = entity_id,
						LayoutOrder = idx,
						compressed = uncompressed_entity.current ~= entity_id,
						is_next = entity_id == next_entity,
						is_previous = entity_id == previous_entity,
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

		Header = React.createElement("Frame", {
			LayoutOrder = 1,
			[React.Tag] = "header",
		}, {
			BuildButton = if #props.selected_cells == 1
				then React.createElement("ImageButton", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.9,
					ClipsDescendants = true,
					[React.Event.MouseButton1Click] = function()
						toggle_submenu { type = "build", cell = props.selected_cells[1] }
					end,
					[React.Tag] = "align-cr",
					Size = UDim2.new(0, 89, 0, 40),
				}, {
					KeybindLabel = React.createElement(KeybindLabel, {
						action_id = "construct",
						AnchorPoint = Vector2.new(1, 1),
						Position = UDim2.new(1, 0, 1, 0),
						action = function(action_name, input_state, input_object)
							if input_state == Enum.UserInputState.Begin then
								toggle_submenu { type = "build", cell = props.selected_cells[1] }
							end
						end,
					}),
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
						Image = "rbxassetid://6034275725",
						ImageTransparency = 0.9,
						Position = UDim2.new(0.135, 0, -0.375, 0),
						Size = UDim2.new(0, 100, 0, 100),
					}),

					Image2 = React.createElement("ImageLabel", {
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						Image = "rbxassetid://6034275725",
						Position = UDim2.new(0.292, 0, 0, 0),
						Size = UDim2.new(0, 42, 0, 40),
					}),
				})
				else nil,

			Container = React.createElement("Frame", {
				[React.Tag] = "container list-h list-cl",
			}, {

				Coordinate = if #props.selected_cells == 1
					then React.createElement(CoordinateLabel, { coordinate = props.selected_cells[1] })
					else nil,

				Title = React.createElement("TextLabel", {
					Text = if #props.selected_cells == 1
						then if deposit_type
							then deposit_mod.deposit_names[deposit_type]
							else cells_mod.cell_names[world:get_cell(props.selected_cells[1]).type]
						else `{#props.selected_cells} Cells Selected`,
					[React.Tag] = "title",
				}),

				Corner = React.createElement(Corner),
			}),
		}),
	})
end

return {
	SelectedCellFrame = SelectedCellFrame,
}
