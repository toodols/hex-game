local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local visibility = require(ServerScriptService.Server.visibility)
local team_mod = require(ReplicatedStorage.Shared.team)

type World = types.World
type Entity = types.Entity
type TeamId = types.TeamId

function serialize_entity_for_team(world: World, entity: Entity, team: TeamId): Entity?
	local team_data = world.teams[team]
	assert(team_data, "no team")
	if visibility.entity_visibility(world, entity, team) then
		local to_copy = entity
		local copy = {}
		for k, v in to_copy do
			if k == "server_data" then
			elseif k == "queued_decisions" then
				if team_mod.is_allied(world, entity.owner, team) then
					copy[k] = v
				else
					copy[k] = {}
				end
			else
				copy[k] = v
			end
		end
		if entity.server_data.is_disguise_of then
			local host = world.entities[entity.server_data.is_disguise_of]
			if not team_mod.is_allied(world, host.owner, team) then
				copy.active = true
			end
		end
		if entity.server_data.always_visible or entity.server_data.always_visible_for[team] then
			copy.always_visible = true
		end
		return copy :: Entity
	end
	return nil
end

return {
	serialize_entity_for_team = serialize_entity_for_team,
}
