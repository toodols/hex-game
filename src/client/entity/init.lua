local ReplicatedStorage = game:GetService "ReplicatedStorage"
local registry_mod = require(script.registry)
local hex_grid = require(ReplicatedStorage.Shared.hex_grid)
local types = require(ReplicatedStorage.Shared.types)

type Entity = types.Entity
type HexGrid = types.HexGrid

require(script.vertex)
require(script.stockpile)
require(script.extractor)
require(script.scout)
require(script.factory)
require(script.generator)
require(script.laboratory)
require(script.turret)
require(script.infinite_source)
require(script.barrier)
require(script.obelisk)
require(script.proxy)
require(script.heart)
require(script.vault)
require(script.solution)
require(script.witness)
require(script.impression)
require(script.phony)
require(script.suggestion)
require(script.altar)

function create_model_from_entity(grid: HexGrid, entity: Entity): Model
	local client_behavior = registry_mod.registry[entity.type]
	local instance
	if type(client_behavior.model) == "function" then
		instance = client_behavior.model(entity, grid)
	else
		instance = client_behavior.model:Clone()
		local cell_instance = grid.cell_instance_map[hex_grid.encode_coord(entity.primary_coordinate)]
		instance:PivotTo(
			(cell_instance.Base.CFrame + Vector3.new(0, cell_instance.Base.Size.Y / 2, 0))
				* CFrame.Angles(0, math.pi / 3 * entity.rotation, 0)
		)
		grid.entity_instance_map[entity.id] = instance
		grid.instance_entity_map[instance] = entity.id
		if instance:IsA "BasePart" then
			instance.Transparency = registry_mod.transparency[entity.status]
		end
		for _, v in instance:GetDescendants() do
			if v:IsA "BasePart" then
				v.Transparency = registry_mod.transparency[entity.status]
			end
		end
	end

	return instance
end

function create_model_from_type(grid: HexGrid, entity_type: string): Model
	local client_behavior = registry_mod.registry[entity_type]
	if not client_behavior then
		error("Unknown entity type: " .. entity_type)
	end
	if type(client_behavior.model) == "function" then
		return client_behavior.model(nil, grid)
	else
		return client_behavior.model:Clone()
	end
end

function update_entity_client(grid: HexGrid, old: Entity?, new: Entity)
	local client_behavior = registry_mod.registry[new.type]
	if not client_behavior then
		error("Unknown entity type: " .. new.type)
	end
	if new.is_destroyed then
		client_behavior.on_destroy(new, grid)
		for _, coord in new.coordinates do
			local cell = grid:get_cell(coord)
			cell.entities[new.id] = nil
		end
	else
		if old then
			local instance = grid.entity_instance_map[new.id]
			local cell_instance = grid.cell_instance_map[hex_grid.encode_coord(new.primary_coordinate)]
			client_behavior.update(new, grid, old)
			instance:PivotTo(
				(cell_instance.Base.CFrame + Vector3.new(0, cell_instance.Base.Size.Y / 2, 0))
					* CFrame.Angles(0, math.pi / 3 * new.rotation, 0)
			)
			if old.status ~= new.status and not new.is_destroyed and instance then
				registry_mod.registry[old.type].status_changed(new, grid, old)
			end
		else
			local instance: Model
			if client_behavior.model then
				instance = create_model_from_entity(grid, new)
			end
			for _, coord in new.coordinates do
				local cell = grid:get_cell(coord)
				if cell.entities[new.id] == nil then
					cell.entities[new.id] = true
				end
			end
			client_behavior.init(new, grid)

			if instance then
				instance.Parent = grid.entity_instance_root
			end
		end
	end
end

return {
	registry = registry_mod.registry,
	update_entity_client = update_entity_client,
	create_model_from_entity = create_model_from_entity,
	create_model_from_type = create_model_from_type,
}
