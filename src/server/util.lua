local HttpService = game:GetService "HttpService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local coords = require(ReplicatedStorage.Shared.coords)

type World = types.World
type Entity = types.Entity
type CubicCoordinate = types.CubicCoordinate
type EncodedCoordinate = types.EncodedCoordinate
type ActionState = server_types.ActionState
type EntityId = types.EntityId

-- global id implies a local id but i haven't found a compelling use case for client-only entities because they need to be replicated to teams and coalitions
function new_global_id()
	return "(global)" .. HttpService:GenerateGUID()
end

function catch(fn, plr, data)
	local success, err = pcall(fn)
	if not success then
		print "failure"
		warn(
			("Data %s from %s produced an error %s. This incident will be reported"):format(
				HttpService:JSONEncode(data),
				plr.Name,
				err
			)
		)
	end
end

-- creates a set of all neighboring coordinates in r<=1
function get_neighbors_set(world: World, coordinates: { CubicCoordinate }): { [EncodedCoordinate]: CubicCoordinate }
	local neighbor_set = {}
	for _, coord in coordinates do
		neighbor_set[coords.encode_coord(coord)] = coord
		for _, neighbor_coord in coords.neighbors_eq(coord, 1) do
			neighbor_set[coords.encode_coord(neighbor_coord)] = coord
		end
	end
	return neighbor_set
end

local error_type = {
	-- can happen intentionally or unintentionally
	dismiss = 1,
	-- triggered because of lag or desync
	mistake = 2,
	-- triggered by exploits
	malice = 3,
}

return {
	new_global_id = new_global_id,
	catch = catch,
	error_type = error_type,
	get_neighbors_set = get_neighbors_set,
}
