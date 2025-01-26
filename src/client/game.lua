local Debris = game:GetService "Debris"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"
local RunService = game:GetService "RunService"

local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local items_mod = require(ReplicatedStorage.Shared.items)
local client_entity_mod = require(script.Parent.entity)
local cells_mod = require(ReplicatedStorage.Shared.cells)

local into_vec3 = hex_grid_mod.into_vec3
local encode_coord = hex_grid_mod.encode_coord
local decode_coord = hex_grid_mod.decode_coord

type Entity = types.Entity
type HexGrid = types.HexGrid
type HexCell = types.HexCell
type EntityId = types.EntityId
type TeamId = types.TeamId
type CubicCoordinate = types.CubicCoordinate
type EncodedCoordinate = types.EncodedCoordinate
type GridUpdate = types.GridUpdate
type PartialHexGrid = types.PartialHexGrid
type Item = types.Item

function color_cell(grid: HexGrid, cell: HexCell)
	local instance = grid.cell_instance_map[hex_grid_mod.encode_coord(cell.coordinate)]
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
		local color = (grid.teams[cell.owner].color :: any).color
		tween_color(color)
	else
		if cell.buildable_for_team then
			tween_color(Color3.fromRGB(202, 202, 202))
		else
			tween_color(Color3.fromRGB(155, 155, 155))
		end
	end
end

function update_neighbors(grid: HexGrid, coordinates: { CubicCoordinate })
	local neighbor_set = {}
	for _, coord in coordinates do
		neighbor_set[encode_coord(coord)] = coord
		for _, neighbor_coord in hex_grid_mod.neighbors_eq(coord, 1) do
			neighbor_set[encode_coord(neighbor_coord)] = coord
		end
	end
	for encoded_neighbor_coord, coord in neighbor_set do
		local neighbor_cell = grid:get_cell(decode_coord(encoded_neighbor_coord))
		if neighbor_cell then
			for neighbor_entity_id in neighbor_cell.entities do
				local neighbor_entity = grid.entities[neighbor_entity_id]
				if not neighbor_entity then
					print("missing", neighbor_entity_id)
				end
				local client_behavior = client_entity_mod.registry[neighbor_entity.type]
				client_behavior.neighbor_changed(neighbor_entity, grid)
			end
		end
	end
end

function create_cell_instance(grid: HexGrid, cell: HexCell)
	local instance = cells_mod.cell_models[cell.type]:Clone()
	instance.Parent = grid.cell_instance_root
	instance:PivotTo(CFrame.new(into_vec3(cell.coordinate) * 4.542 / 2))
	-- for debugging purposes
	instance.Name = hex_grid_mod.encode_coord(cell.coordinate)
	grid.cell_instance_map[hex_grid_mod.encode_coord(cell.coordinate)] = instance
	color_cell(grid, cell)
	grid.instance_cell_map[instance] = hex_grid_mod.encode_coord(cell.coordinate)
	return instance
end

function render_grid(grid: HexGrid)
	destroy_grid_instances(grid)
	local entity_folder = Instance.new "Folder"
	entity_folder.Parent = workspace
	grid.entity_instance_root = entity_folder
	entity_folder.Name = "Entities"
	local cell_folder = Instance.new "Folder"
	cell_folder.Parent = workspace
	cell_folder.Name = "Cells"
	grid.cell_instance_root = cell_folder

	-- create cell instances
	for _, cell in grid.cells do
		create_cell_instance(grid, cell)
	end

	-- first pass for entity update
	for _, entity in grid.entities do
		client_entity_mod.update_entity_client(grid, nil, entity)
	end
end

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
function animate_cell_removal(instance: Model)
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA "BasePart" then
			TweenService:Create(descendant, TweenInfo.new(0.5), {
				CFrame = descendant.CFrame + Vector3.new(0, 3, 0),
			}):Play()
		end
	end
end

function start_animations(grid: HexGrid)
	local animation_states = {}
	return RunService.Heartbeat:Connect(function()
		-- remove animation states for entities that are gone
		local new_animation_states = {}
		for entity_id in grid.entities do
			new_animation_states[entity_id] = animation_states[entity_id]
		end
		animation_states = new_animation_states
		for entity_id, entity in grid.entities do
			local behavior = client_entity_mod.registry[entity.type]
			if behavior.animate then
				if not animation_states[entity_id] then
					animation_states[entity_id] = { type = "idle", step = 0 }
				end
				animation_states[entity_id].step += 1
				behavior.animate(entity, grid, animation_states[entity_id])
			end
		end
	end)
end

function destroy_grid_instances(grid: HexGrid)
	grid.cell_instance_map = {}
	grid.entity_instance_map = {}
	if grid.cell_instance_root then
		grid.cell_instance_root:Destroy()
	end
	if grid.entity_instance_root then
		grid.entity_instance_root:Destroy()
	end
end

function handle_updates(grid: HexGrid, updates: { GridUpdate })
	table.sort(updates, function(a, b)
		local order = {
			turn_timer = 1,
			turn = 1,
			cell_update = 1,
			cells = 1,
			entity_update = 3,
			exchange = 4,
			scout_attack = 4,
		}
		return (order[a.type] or 5) < (order[b.type] or 5)
	end)
	local updated_entities = {}

	for _, update in updates do
		if update.type == "entity_update" then
			-- should be fine if single threaded
			local old_entity = grid.entities[update.entity.id]
			grid.entities[update.entity.id] = update.entity
			table.insert(updated_entities, { old = old_entity, new = update.entity })
		elseif update.type == "turn_timer" then
			grid.turn_schedule = update.schedule
		elseif update.type == "turn" then
			grid.highest_turn = update.turn
			grid.turn = update.turn
		elseif update.type == "cell_update" then
			grid.cells[hex_grid_mod.encode_coord(update.cell.coordinate)] = update.cell
		elseif update.type == "cells" then
			for old_encoded_coord, old_cell in grid.cells do
				if not update.cells[old_encoded_coord] then
					local instance = grid.cell_instance_map[old_encoded_coord]
					grid.cell_instance_map[old_encoded_coord] = nil
					grid.instance_cell_map[instance] = nil
					animate_cell_removal(instance)
					Debris:AddItem(instance, 2)
					grid.cells[old_encoded_coord] = nil
				end
			end
			for encoded_coord, cell in update.cells do
				if not grid.cells[encoded_coord] then
					grid.cells[encoded_coord] = cell
					local instance = create_cell_instance(grid, cell)
					animate_cell_appearance(instance)
				end

				if grid.cells[encoded_coord].visible_for_team and not cell.visible_for_team then
					for entity_id in grid.cells[encoded_coord].entities do
						local entity = grid.entities[entity_id]
						local client_behavior = client_entity_mod.registry[entity.type]
						if client_behavior.on_hidden then
							client_behavior.on_hidden(entity, grid)
						end
						entity.is_destroyed = true
					end
				end
				grid.cells[encoded_coord] = cell
			end
			for _, cell in grid.cells do
				color_cell(grid, cell)
			end
		elseif update.type == "entity_event" then
			local event = update.event
			if event.event_type == "produced_items" or event.event_type == "consumed_items" then
				local entity_instance = grid.entity_instance_map[event.entity_id]
				local template = asset_server.load "Billboards/Exchange"
				local instance = template:Clone()
				instance.Parent = workspace
				instance.Adornee = entity_instance

				local function display(symbol: "+" | "-", items: { [Item]: number? }): string
					return table.concat(
						util.table_map(util.table_keys(items), function(k)
							return `{symbol}{items[k]} {items_mod.item_names[k]}`
						end),
						"\n"
					)
				end
				if event.event_type == "produced_items" then
					instance.Amount.Text = `<font color="#a3e5a0">{display("+", event.items)}</font>`
				elseif event.event_type == "consumed_items" then
					instance.Amount.Text = `<font color="#e56b6b">{display("-", event.items)}</font>`
				end
				TweenService:Create(instance, TweenInfo.new(4), {
					StudsOffsetWorldSpace = Vector3.new(0, 4, 0),
				}):Play()
				TweenService:Create(instance.Amount, TweenInfo.new(4), {
					TextTransparency = 1,
				}):Play()
				Debris:AddItem(instance, 5)
			end
		elseif update.type == "ability" then
			if update.ability_type == "scout_attack" or update.ability_type == "turret_attack" then
				local cell_instance = grid.cell_instance_map[hex_grid_mod.encode_coord(update.coordinate)]
				local entity_instance = grid.entity_instance_map[update.entity_id]
				local bullet = Instance.new "Part"
				bullet.Size = Vector3.new(0.5, 0.5, 0.5)
				bullet.CanCollide = false
				bullet.Anchored = true
				bullet.Material = Enum.Material.Neon
				bullet.Parent = workspace
				bullet:PivotTo(entity_instance:GetPivot())
				bullet.Anchored = true
				TweenService:Create(bullet, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {
					Position = cell_instance:FindFirstChild("Base").Position + Vector3.new(0, 2, 0),
				}):Play()
				Debris:AddItem(bullet, 0.3)
			end
		elseif update.type == "turn_skips" then
			grid.needed_skips = update.needed_skips
			grid.current_skips = update.current_skips
			-- grid.can_skip = update.can_skip
		elseif update.type == "teams" then
			grid.teams = update.teams
			grid.coalitions = update.coalitions
		elseif update.type == "quest_update" then
			grid.quests[update.quest.id] = update.quest
		end
	end

	-- second pass: create instances for these things
	for _, entry in updated_entities do
		local old_entity = entry.old
		local new_entity = entry.new
		client_entity_mod.update_entity_client(grid, old_entity, new_entity)
	end

	-- third pass: update neighbors and other stuff
	for _, entry in updated_entities do
		local new_entity = entry.new
		update_neighbors(grid, new_entity.coordinates)
	end
	grid.grid_update_signal.send(updates)

	grid:purge_dead_entities()
end

return {
	start_animations = start_animations,
	handle_updates = handle_updates,
	render_grid = render_grid,
	destroy_grid_instances = destroy_grid_instances,
}
