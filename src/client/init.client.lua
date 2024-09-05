local Debris = game:GetService "Debris"
local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"

local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local items_mod = require(ReplicatedStorage.Shared.items)

local ui = require(script.ui)
local client_entity_mod = require(script.entity)
local cells_mod = require(ReplicatedStorage.Shared.cells)

-- apparently local x: RemoteEvent is the same as local x: Instance. Nice.
local get_hex_grid_data_remote = ReplicatedStorage:FindFirstChild "GetHexGridDataRemote" :: RemoteFunction
local grid_updates_remote = ReplicatedStorage:FindFirstChild "GridUpdatesRemote" :: RemoteEvent

local into_vec3 = hex_grid_mod.into_vec3
local encode_coord = hex_grid_mod.encode_coord
local decode_coord = hex_grid_mod.decode_coord

local billboard_template = asset_server.load "Billboards/TileActionsIndicator"

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

function color_tile(grid: HexGrid, cell: HexCell)
	local instance = grid.cell_instance_map[hex_grid_mod.encode_coord(cell.coordinate)]
	local player_team = grid:get_player_team(Players.LocalPlayer)
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
		tween_color(grid.teams[cell.owner].color.color)
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
			for _, neighbor_entity_id in neighbor_cell.entities do
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
-- update deconstruct gui for entities on this tile
function update_tile_deconstructs(grid: HexGrid, coordinate: CubicCoordinate)
	local thingy = util.table_fold(grid:get_cell(coordinate).entities, { deconstructs = 0 }, function(acc, cur)
		acc.deconstructs += if util.table_any(grid.entities[cur].queued_decisions, function(action)
				return action.type == "deconstruct"
			end)
			then 1
			else 0
		return acc
	end)

	local instance = grid.cell_instance_map[encode_coord(coordinate)]
	if thingy.deconstructs == 0 then
		local billboard = instance:FindFirstChild "TileActionsIndicator" :: any
		if billboard then
			billboard.Deconstruction.Visible = false
		end
	else
		local billboard = instance:FindFirstChild "TileActionsIndicator" :: any
		if not billboard then
			billboard = billboard_template:Clone()
			billboard.Parent = instance
		end
		billboard.Deconstruction.Visible = true
		billboard.Deconstruction.Amount.Text = tostring(thingy.deconstructs)
	end
end

function init(grid_data: PartialHexGrid)
	local grid = hex_grid_mod.new_grid_from_data(grid_data)

	local entity_folder = Instance.new "Folder"
	entity_folder.Parent = workspace
	grid.entity_instance_root = entity_folder
	entity_folder.Name = "Entities"
	local tile_folder = Instance.new "Folder"
	tile_folder.Parent = workspace
	tile_folder.Name = "Tiles"
	grid.cell_instance_root = tile_folder

	-- create cell instances
	for _, cell in grid.cells do
		local instance = cells_mod.cell_models[cell.type]:Clone()
		instance.Parent = tile_folder
		instance:PivotTo(CFrame.new(into_vec3(cell.coordinate) * 4.542 / 2))
		-- for debugging purposes
		instance.Name = hex_grid_mod.encode_coord(cell.coordinate)
		grid.cell_instance_map[hex_grid_mod.encode_coord(cell.coordinate)] = instance

		color_tile(grid, cell)
		grid.instance_cell_map[instance] = hex_grid_mod.encode_coord(cell.coordinate)
	end

	-- first pass for entity update
	for _, entity in grid.entities do
		client_entity_mod.update_entity_client(grid, nil, entity)
	end

	grid_updates_remote.OnClientEvent:Connect(function(updates: { GridUpdate })
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
			-- if update.type == "entity_add" then
			-- 	local entity = update.entity
			-- 	if grid.entities[entity.id] then
			-- 		error "Duplicate entity add. This is a bug"
			-- 	end
			-- 	grid.entities[entity.id] = entity

			-- 	for _, coord in entity.coordinates do
			-- 		local cell = grid:get_cell(coord)
			-- 		table.insert(cell.entities, entity.id)
			-- 	end

			-- 	init_entity_client(grid, entity)

			-- 	-- update neighbor
			-- 	client_entity_mod.registry[entity.type].init(entity, grid)
			-- 	update_neighbors(grid, entity.coordinates)
			-- elseif update.type == "entity_remove" then
			-- 	local entity = grid.entities[update.entity.id]
			-- 	for _, coord in entity.coordinates do
			-- 		local cell = grid:get_cell(coord)
			-- 		util.table_remove_needle(cell.entities, entity.id)
			-- 	end

			-- 	grid.entities[update.entity.id] = nil
			-- 	local instance: Instance = grid.entity_instance_map[entity.id]
			-- 	if instance then
			-- 		instance:Destroy()
			-- 	end
			-- 	grid.entity_instance_map[entity.id] = nil
			-- 	-- play_animation(instance)
			-- 	update_neighbors(grid, entity.coordinates)
			-- 	update_tile_deconstructs(grid, update.entity.primary_coordinate)
			if update.type == "entity_update" then
				-- should be fine if single threaded
				local old_entity = grid.entities[update.entity.id]
				grid.entities[update.entity.id] = update.entity
				-- first pass: populate grid.entities with the data
				table.insert(updated_entities, { old = old_entity, new = update.entity })
			elseif update.type == "turn_timer" then
				grid.turn_end_time = update.turn_end_time
				grid.turn_start_time = update.turn_start_time
			elseif update.type == "turn" then
				grid.highest_turn = update.turn
				grid.turn = update.turn
			elseif update.type == "cell_update" then
				grid.cells[hex_grid_mod.encode_coord(update.cell.coordinate)] = update.cell
			elseif update.type == "cells" then
				for encoded_coord, cell in update.cells do
					if grid.cells[encoded_coord].visible_for_team and not cell.visible_for_team then
						for _, entity_id in grid.cells[encoded_coord].entities do
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
					color_tile(grid, cell)
				end
			elseif update.type == "exchange" then
				-- local entity = grid.entities[update.entity_id]
				local entity_instance = grid.entity_instance_map[update.entity_id]
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
				instance.Amount.Text = table.concat((util.table_filter_nil {
					update.output_items
						and `<font color="#a3e5a0">{display("+", items_mod.into_counted_items(update.output_items))}</font>`,
					update.output_power and `<font color = "#a3e5a0">+{update.output_power} power</font>`,
					update.input_items and `<font color = "#e56b6b">{display("-", update.input_items)}</font>`,
					update.input_power and `<font color = "#e56b6b">-{update.input_power} power</font>`,
				}), "\n")
				TweenService:Create(instance, TweenInfo.new(4), {
					StudsOffsetWorldSpace = Vector3.new(0, 4, 0),
				}):Play()
				TweenService:Create(instance.Amount, TweenInfo.new(4), {
					TextTransparency = 1,
				}):Play()
				Debris:AddItem(instance, 5)
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
			-- elseif update.type == "grid" then
			elseif update.type == "turn_skips" then
				grid.needed_skips = update.needed_skips
				grid.current_skips = update.current_skips
			elseif update.type == "teams" then
				grid.teams = update.teams
				grid.coalitions = update.coalitions
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
			update_tile_deconstructs(grid, new_entity.primary_coordinate)
		end
		grid.grid_update_signal.send(updates)

		grid:purge_dead_entities()
	end)
	--
	ui.init_ui(grid)
	return grid
end

local grid_data = get_hex_grid_data_remote:InvokeServer()
local grid = init(grid_data)
