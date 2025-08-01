local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local types = require(ReplicatedStorage.Shared.types)
local world_mod = require(ReplicatedStorage.Shared.world)
local coords_mod = require(ReplicatedStorage.Shared.coords)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local router = require(ServerScriptService.Server.router)

type Interaction = types.Interaction
type World = types.World
type TeamData = types.TeamData
type CubicCoordinate = types.CubicCoordinate
type Entity = types.Entity
type Item = types.Item

type Memory = {
	-- where ai thinks the center of the base is
	-- this is (for now) the location of the actual heart entity
	home: CubicCoordinate,
	-- debt: { [Item]: number },
	debt: any,
}
type ConfigProfile = {}
type CandidateAction = {
	action: Interaction,
	score: number,
}

function find_closest(world: World, location: CubicCoordinate, distance: number, entity_query: any): Entity?
	for i = 1, distance do
		for _, cell in world_mod.coords_filter(world, coords_mod.neighbors_eq(location, i)) do
			local entity = world:query_entity(entity_query)[1]
			if entity then
				return entity
			end
		end
	end
	return nil
end

-- look for the closest bar deposit that is not occupied
function claim_bar_deposit(
	world: World,
	team: TeamData,
	config_profile: ConfigProfile,
	memory: Memory
): CandidateAction?
	local candidate
	local distance = math.huge
	if (memory.debt.bar or 0) > 0 then
		return nil
	end
	for _, deposit_coord in world_mod.coords_filter(world, coords_mod.neighbors_leq(memory.home, 10)) do
		if #world:query_entity { type = "deposit", deposit_type = "bar_deposit", coordinate = deposit_coord } > 0 then
			local cell = world:get_cell(deposit_coord)
			local has_building = false
			for entity_id in cell.entities do
				local entity = world.entities[entity_id]
				local config = world.entity_configurations[entity.type]
				if config.layer == shared_entity_mod.LAYER.building then
					has_building = true
					break
				end
			end
			if has_building then
				continue
			end

			-- find a vertex of the same team in range of 4
			local nearby_vertex_coord
			for _, coord in world_mod.bfs(world, deposit_coord, 4, team.id) do
				if #world:query_entity { coordinate = coord, type = "vertex", owner = team.id } > 0 then
					nearby_vertex_coord = coord
					break
				end
			end
			local path
			if nearby_vertex_coord == nil then
				print "no vertex found nearby, pathfinding:"
				path = world_mod.astar(world, memory.home, deposit_coord, team.id)
			else
				print "vertex was found within 4 tiles, pathfinding from there"
				path = world_mod.astar(world, nearby_vertex_coord, deposit_coord, team.id)
			end

			if not path then
				continue
			end

			local start_coord
			local dist
			for i, coord in path do
				local vertex = world:query_entity({ coordinate = coord, type = "vertex", owner = team.id })[1]
				if vertex == nil then
					dist = #path - i
					start_coord = coord
					break
				elseif vertex and vertex.status ~= "complete" then
					-- ai is already trying to build to that deposit, ignore.
					dist = math.huge
					start_coord = nil
					break
				end
			end

			if dist < distance then
				distance = dist
				if coords_mod.coords_eq(start_coord, deposit_coord) then
					candidate = {
						action = {
							type = "construct",
							entity_type = "extractor",
							coordinate = start_coord,
						},
						score = 100,
					}
				else
					candidate = {
						action = {
							type = "construct",
							entity_type = "vertex",
							coordinate = start_coord,
						},
						score = 50,
					}
				end
			end
		end
	end

	if candidate ~= nil then
		print("Best action", candidate)
	end
	return candidate
end

local actions = { claim_bar_deposit }

function decide(world: World, team: TeamData, config_profile: ConfigProfile, memory: any)
	local t0 = os.clock()
	local heart = world:query_entity({
		type = "heart",
		owner = team.id,
		query_global = true,
	})[1]
	memory.home = heart.primary_coordinate

	for i = 1, 10 do
		memory.debt = {}
		local blueprints = world:query_entity {
			status = "blueprint",
			owner = team.id,
			query_global = true,
		}
		for _, blueprint in blueprints do
			for item, amount in blueprint.cost do
				memory.debt[item] = (memory.debt[item] or 0) + amount - (blueprint.cost_fulfilled[item] or 0)
			end
		end
		print("Debt is now", memory.debt)
		local best_action = { action = nil, score = 0 }
		for _, action in actions do
			local candidate = action(world, team, config_profile, memory)
			if candidate and candidate.score > best_action.score then
				best_action = candidate
			end
		end
		if best_action.score > 0 then
			print("submitting", best_action.action)
			router.on_client_interaction(world, {
				player_team = team,
				data = { best_action.action },
			})
		else
			break
		end
	end
	print("finished ai step in", os.clock() - t0, "seconds")
end

return {
	decide = decide,
}
