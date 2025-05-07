local Debris = game:GetService "Debris"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"
local RunService = game:GetService "RunService"

local coords = require(ReplicatedStorage.Shared.coords)
local types = require(ReplicatedStorage.Shared.types)
local cells_mod = require(ReplicatedStorage.Shared.cells)
local world_mod = require(ReplicatedStorage.Shared.world)
local client_entity_mod = require(script.Parent.entity)
local visuals = require(script.Parent.visuals)

local into_vec3 = coords.into_vec3
local encode_coord = coords.encode_coord
local decode_coord = coords.decode_coord

type Entity = types.Entity
type World = types.World
type HexCell = types.HexCell
type EntityId = types.EntityId
type TeamId = types.TeamId
type CubicCoordinate = types.CubicCoordinate
type EncodedCoordinate = types.EncodedCoordinate
type WorldUpdate = types.WorldUpdate
type PartialWorld = types.PartialWorld
type Item = types.Item
type EntityEvent = types.EntityEvent

--- Paints, with animation, a cell based on its owner and visibility
function color_cell(world: World, cell: HexCell)
	local instance = world.cell_instance_map[coords.encode_coord(cell.coordinate)]
	local function tween_color(color: Color3)
		TweenService:Create(instance:FindFirstChild "Base", TweenInfo.new(), {
			Color = color,
		}):Play()
	end
	if not cell.visible_for_team then
		tween_color(Color3.fromRGB(70, 70, 70))
		return
	end
	-- tiles that are r=1 of a friendly tile and do not have an enemy presence
	if cell.owner then
		local color = (world.teams[cell.owner].color :: any).color
		tween_color(color)
	else
		if cell.buildable_for_team then
			tween_color(Color3.fromRGB(202, 202, 202))
		else
			tween_color(Color3.fromRGB(155, 155, 155))
		end
	end
end

--- Calls neighbor_changed on entities on all r=1 neighboring cells of the given coordinates <br>
--- Necessary for `vertex` entities to properly display connections to other vertices <br>
--- This uses a set to avoid adjacent cells calling .neighbor_changed twice on the same entity
function update_neighbors(world: World, coordinates: { CubicCoordinate })
	local neighbor_set = {}
	for _, coord in coordinates do
		neighbor_set[encode_coord(coord)] = coord
		for _, neighbor_coord in coords.neighbors_eq(coord, 1) do
			neighbor_set[encode_coord(neighbor_coord)] = coord
		end
	end
	for encoded_neighbor_coord, coord in neighbor_set do
		local neighbor_cell = world:get_cell(decode_coord(encoded_neighbor_coord))
		if neighbor_cell then
			for neighbor_entity_id in neighbor_cell.entities do
				local neighbor_entity = world.entities[neighbor_entity_id]
				if not neighbor_entity then
					warn("missing", neighbor_entity_id)
				end
				local client_behavior = client_entity_mod.registry[neighbor_entity.type]
				client_behavior.neighbor_changed(neighbor_entity, world)
			end
		end
	end
end

--- Create an instance for a single cell, as well as attaching necessary references
--- between this instance and the data-facing cell
function create_cell_instance(world: World, cell: HexCell): Model
	local instance = cells_mod.cell_models[cell.type]:Clone()
	instance.Parent = world.cell_instance_root
	instance:PivotTo(CFrame.new(into_vec3(cell.coordinate) * 4.542 / 2))
	instance.Name = coords.encode_coord(cell.coordinate) -- for debugging
	world.cell_instance_map[coords.encode_coord(cell.coordinate)] = instance
	color_cell(world, cell)
	world.instance_cell_map[instance] = coords.encode_coord(cell.coordinate)
	return instance
end

--- Does the initial render of the world provided by the server
--- - This creates an instance for every cell, and an instance for every entity
--- - This also happens to delete all preexisting instances/maps for the world
function render_world(world: World)
	destroy_world_instances(world)
	local entity_folder = Instance.new "Folder"
	entity_folder.Parent = workspace
	world.entity_instance_root = entity_folder
	entity_folder.Name = "Entities"
	local cell_folder = Instance.new "Folder"
	cell_folder.Parent = workspace
	cell_folder.Name = "Cells"
	world.cell_instance_root = cell_folder

	for _, cell in world.cells do
		create_cell_instance(world, cell)
	end

	for entity_id in world:active_entities() do
		local entity = world.entities[entity_id]
		client_entity_mod.update_entity_client(world, nil, entity)
	end
end

--- Animates the appearance of a cell by moving it up from below the ground
function animate_cell_appearance(instance: Model)
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA "BasePart" then
			local old_cf = descendant.CFrame
			descendant.CFrame = old_cf - Vector3.new(0, 2, 0)
			TweenService:Create(descendant, TweenInfo.new(0.5), {
				CFrame = old_cf,
			}):Play()
		end
	end
end

--- Animates the removal of a cell by moving it down below the ground
function animate_cell_removal(instance: Model)
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA "BasePart" then
			TweenService:Create(descendant, TweenInfo.new(0.5), {
				CFrame = descendant.CFrame + Vector3.new(0, 3, 0),
			}):Play()
		end
	end
end

--- Performs one step of animation on all entity instances that are animatable
function step_animations(world: World)
	if world.animation_states == nil then
		world.animation_states = {}
	end
	assert(world.animation_states, "this should never error")

	-- remove animation states for entities that are no longer active
	local new_animation_states = {}
	for entity_id in world:active_entities() do
		new_animation_states[entity_id] = world.animation_states[entity_id]
	end
	world.animation_states = new_animation_states

	for entity_id, entity in world:active_entities() do
		local behavior = client_entity_mod.registry[entity.type]
		if behavior.animate then
			if not world.animation_states[entity_id] then
				world.animation_states[entity_id] = { type = "idle", step = 0 }
			end
			world.animation_states[entity_id].step += 1
			behavior.animate(entity, world, world.animation_states[entity_id])
		end
	end
end

function start_animations(world: World): RBXScriptConnection
	return RunService.Heartbeat:Connect(function()
		step_animations(world)
	end)
end

--- Removes all instances for this world
--- Necessary for cleanup during tests
function destroy_world_instances(world: World)
	world.cell_instance_map = {}
	world.entity_instance_map = {}
	if world.cell_instance_root then
		world.cell_instance_root:Destroy()
	end
	if world.entity_instance_root then
		world.entity_instance_root:Destroy()
	end
end

function hide_entities(world: World, old: HexCell)
	for entity_id in old.entities do
		local entity = world.entities[entity_id]
		if entity.always_visible then
			continue
		end
		local client_behavior = client_entity_mod.registry[entity.type]
		if client_behavior.on_hidden then
			client_behavior.on_hidden(entity, world)
		end
		entity.is_destroyed = true
	end
end

function handle_cells(world: World, update: WorldUpdate)
	assert(update.type == "cells", "not a cell update")

	-- remove entities from cells that are no longer visible
	for coord, cell in world.cells do
		for old_entity_id in cell.entities do
			if update.cells[coord] and not update.cells[coord].entities[old_entity_id] then
				local client_behavior = client_entity_mod.registry[world.entities[old_entity_id].type]
				client_behavior.on_hidden(world.entities[old_entity_id], world)
			end
		end
	end

	-- remove cells that no longer exist
	for old_encoded_coord, old_cell in world.cells do
		if update.cells[old_encoded_coord] then
			continue
		end
		local instance = world.cell_instance_map[old_encoded_coord]
		world.cell_instance_map[old_encoded_coord] = nil
		world.instance_cell_map[instance] = nil
		animate_cell_removal(instance)
		Debris:AddItem(instance, 2)
		world.cells[old_encoded_coord] = nil

		for entity_id in old_cell.entities do
			local entity = world.entities[entity_id]
			if entity and not entity.always_visible then
				local client_behavior = client_entity_mod.registry[entity.type]
				client_behavior.on_hidden(entity, world)
			end
		end
	end

	for encoded_coord, cell in update.cells do
		local old = world.cells[encoded_coord]
		-- add new cells
		if not old then
			-- old = cell
			local instance = create_cell_instance(world, cell)
			animate_cell_appearance(instance)
		end

		-- remove entities from cells that have changed to not visible
		if old and old.visible_for_team and not cell.visible_for_team then
			hide_entities(world, old)
		end

		if old and old.type ~= cell.type then
			local instance = world.cell_instance_map[encoded_coord]
			if instance then
				instance:Destroy()
			end
			local new_instance = create_cell_instance(world, cell)
			world.cell_instance_map[encoded_coord] = new_instance
			world.instance_cell_map[new_instance] = encoded_coord
		end

		world.cells[encoded_coord] = cell
	end
	for _, cell in world.cells do
		color_cell(world, cell)
	end
end

function handle_entity_event(world: World, event: EntityEvent)
	if event.event_type == "produced_items" or event.event_type == "consumed_items" then
		local entity_instance = world.entity_instance_map[event.entity_id]
		if not entity_instance then
			warn("entity not found", event.entity_id, "when handling event", event.event_type)
			return
		end

		visuals.used_item_text(event, entity_instance)

		if event.event_type == "produced_items" then
			visuals.produced_item_effect(event, entity_instance:GetPivot().Position)
		elseif event.event_type == "consumed_items" then
			visuals.consumed_item_effect(event, entity_instance:GetPivot().Position)
		end
	elseif event.event_type == "destroy" then
		local entity = world.entities[event.entity_id]
		local behavior = client_entity_mod.registry[entity.type]
		behavior.on_destroy(entity, world, event)
	end
end

--- Some events like entity_event depend on entity_update
--- In the future
function sort_updates(updates: { WorldUpdate })
	table.sort(updates, function(a, b)
		local order = {
			turn_timer = 1,
			turn = 1,
			cell_update = 1,
			cells = 1,
			entity_update = 3,
			exchange = 4,
			scout_attack = 4,
			entity_event = 4,
		}
		return (order[a.type] or 5) < (order[b.type] or 5)
	end)
end

--- This is the main function that handles when the client receives updates about the world from the server
--- This includes populating world.entities and world.cells and creating instances
function handle_updates(world: World, updates: { WorldUpdate })
	-- cannot mutate updates
	local updated_entities = {}

	for _, update in updates do
		print(update.type, update)
		if update.type == "turn_timer" then
			world.turn_schedule = update.schedule
		elseif update.type == "turn" then
			world.highest_turn = update.turn
			world.turn = update.turn
		elseif update.type == "cell_update" then
			world.cells[coords.encode_coord(update.cell.coordinate)] = update.cell
		elseif update.type == "cells" then
			handle_cells(world, update)
		elseif update.type == "turn_skips" then
			world.current_skips = update.current_skips
			world.needed_skips = update.needed_skips
		elseif update.type == "teams" then
			world.teams = update.teams
			world.coalitions = update.coalitions
		elseif update.type == "quest_update" then
			world.quests[update.quest.id] = update.quest
		end
	end

	-- populate entities and add new, old pair
	for _, update in updates do
		if update.type == "entity_update" then
			local old_entity = world.entities[update.entity.id]
			world.entities[update.entity.id] = update.entity
			if update.entity.active ~= false then
				table.insert(updated_entities, { old = old_entity, new = update.entity })
			end
		end
	end

	-- create the instances for the entities
	for _, entry in updated_entities do
		local old_entity = entry.old
		local new_entity = entry.new
		client_entity_mod.update_entity_client(world, old_entity, new_entity)
	end

	-- update neighbors and other stuff
	for _, entry in updated_entities do
		local new_entity = entry.new
		update_neighbors(world, new_entity.coordinates)
	end

	for _, update in updates do
		if update.type == "ability" then
			local cell_instance = world.cell_instance_map[coords.encode_coord(update.coordinate)]
			local entity_instance = world.entity_instance_map[update.entity_id]
			if update.ability_type == "scout_attack" or update.ability_type == "turret_attack" then
				visuals.scout_attack_effect(entity_instance, cell_instance)
			end
		end
	end

	for _, update in updates do
		if update.type == "entity_event" then
			handle_entity_event(world, update)
		end
	end

	world_mod.purge_destroyed_entities(world)
	world.world_update_signal.send(updates)
end

return {
	start_animations = start_animations,
	step_animations = step_animations,
	handle_updates = handle_updates,
	render_world = render_world,
	destroy_world_instances = destroy_world_instances,
}
