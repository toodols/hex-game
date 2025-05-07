local ReplicatedStorage = game:GetService "ReplicatedStorage"
local coords = require(ReplicatedStorage.Shared.coords)
local types = require(ReplicatedStorage.Shared.types)
type World = types.World

-- a presence prevents enemy teams from building on that cell
function compute_presence(world: World)
	local neutral_team = world.neutral_team
	for _, cell in world.cells do
		local owner
		for entity_id in cell.entities do
			local entity = world.entities[entity_id]
			if entity.incorporeal then
				continue
			end
			if entity.owner ~= neutral_team and entity.status ~= "blueprint" and not entity.is_destroyed then
				owner = entity.owner
			end

			-- neutral barrier imposes a presence
			if entity.owner == neutral_team and entity.type == "barrier" then
				owner = neutral_team
			end
		end
		cell.owner = owner
	end
	for _, cell in world.cells do
		local presence = {}
		for _, coord in coords.neighbors_leq(cell.coordinate, 1) do
			local neighbor = world:get_cell(coord)
			-- teams impose a presence in r<=1
			-- neutral teams impose a presence in r=0
			if
				neighbor
				and neighbor.owner
				and (neighbor.owner ~= neutral_team or coords.coords_eq(cell.coordinate, coord))
			then
				presence[neighbor.owner] = true
			end
		end
		-- if not util.deep_equal(presence, cell.server_data.presence) then
		-- if mark_dirty then
		-- 	cell.server_data.dirty = true
		-- end
		-- end

		cell.server_data.presence = presence
	end
end

return {
	compute_presence = compute_presence,
}
