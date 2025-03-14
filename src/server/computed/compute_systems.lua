local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)

type HexGrid = types.HexGrid
type CubicCoordinate = types.CubicCoordinate
type EncodedCoordinate = types.EncodedCoordinate

function compute_systems(grid: HexGrid)
	local systems: { { CubicCoordinate } } = {}
	local visited: { [EncodedCoordinate]: { CubicCoordinate } } = {}

	for encoded_initial_coord in grid.cells do
		if visited[encoded_initial_coord] then
			continue
		end
		-- find any unvisited coords
		local initial_coord = hex_grid_mod.decode_coord(encoded_initial_coord)
		local initial_entity = grid:query_entity({
			coordinate = initial_coord,
			type = "vertex",
			status = "complete",
			is_destroyed = false,
		})[1]

		if initial_entity then
			local system_visited = {}
			table.insert(systems, {})
			local visitable_stack: { CubicCoordinate } = { initial_coord }
			local visitable_stack_map: { [EncodedCoordinate]: true } = {}

			-- a DFS on connected neighbors, then mark those as visited
			while #visitable_stack > 0 do
				local coord = table.remove(visitable_stack)
				local encoded_coord = hex_grid_mod.encode_coord(coord)
				local ent = grid:query_entity({
					type = "vertex",
					status = "complete",
					is_destroyed = false,
					coordinate = coord,
					owner = initial_entity.owner,
				})[1]
				local cell = grid:get_cell(coord)

				if ent and not system_visited[encoded_coord] and not visited[encoded_coord] then
					if ent.owner == initial_entity.owner then
						table.insert(systems[#systems], coord)
						local portals = {}
						if cell.type == "portal" and cell.portal.open then
							portals = cell.portal.group
						end
						for _, portal in portals do
							local encoded_neighbor_coord = hex_grid_mod.encode_coord(portal)
							if
								not visited[encoded_neighbor_coord] and not visitable_stack_map[encoded_neighbor_coord]
							then
								table.insert(visitable_stack, portal)
								visitable_stack_map[encoded_neighbor_coord] = true
							end
						end
						for _, neighbor in hex_grid_mod.neighbors_eq(coord, 1) do
							local encoded_neighbor_coord = hex_grid_mod.encode_coord(neighbor)
							if not visitable_stack_map[encoded_neighbor_coord] then
								table.insert(visitable_stack, neighbor)
								visitable_stack_map[encoded_neighbor_coord] = true
							end
						end

						visited[encoded_coord] = systems[#systems]
					end
					system_visited[encoded_coord] = true
				end

				visitable_stack_map[encoded_coord] = nil
			end
		end
	end

	-- convert system from a collection of connected coordinates to a collection of connected entities
	local entities_set = {}
	local result = {}
	for _, system in systems do
		local system_entities_set = {}
		local cells = {}
		for _, coord in system do
			local cell = grid:get_cell(coord)
			assert(cell, "cell not found")
			cells[hex_grid_mod.encode_coord(coord)] = cell
			for entity_id in cell.entities do
				if grid.entities[entity_id].status == "complete" then
					entities_set[entity_id] = true
					system_entities_set[entity_id] = true
				end
			end
		end
		local entities = {}
		for entity_id in system_entities_set do
			entities[entity_id] = grid.entities[entity_id]
		end

		table.insert(result, { entities = entities, cells = cells })
	end

	for entity_id, entity in grid.entities do
		if not entities_set[entity_id] then
			-- cells is empty because individual entities do not have a vertex and cells only count vertex
			table.insert(result, { entities = { [entity_id] = true }, cells = {} })
		end
	end

	return result
end

return {
	compute_systems = compute_systems,
}
