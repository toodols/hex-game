local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local visibility = require(ServerScriptService.Server.visibility)
local team_mod = require(ReplicatedStorage.Shared.team)
local server_types = require(ServerScriptService.Server.types)
local get_cache = require(script.Parent.get_cache).get_cache

type World = types.World
type Entity = types.Entity
type TeamId = types.TeamId

type SerializeFor = server_types.SerializeFor
type SerializationContext = server_types.SerializationContext

function serialize_entity(
	world: World,
	se_ctx: SerializationContext,
	serialize_for: SerializeFor,
	entity: Entity
): Entity?
	if serialize_for.team == nil then
		return entity
	end

	local value
	local team_cache = get_cache(se_ctx, { team = serialize_for.team })
	if team_cache.entities[entity.id] ~= nil then
		return team_cache.entities[entity.id]
	end
	if visibility.entity_visibility(world, serialize_for, entity) then
		local team_data = world.teams[serialize_for.team]
		assert(team_data, "no team")
		local to_copy = entity
		local copy = {}
		for k, v in to_copy do
			if k == "server_data" then
			elseif k == "queued_decisions" then
				if
					team_mod.is_allied(world, entity.owner, serialize_for.team)
					or team_data.server_data.visibility == "perfect"
				then
					copy[k] = v
				else
					copy[k] = {}
				end
			else
				copy[k] = v
			end
		end
		if entity.server_data.subject_of ~= nil and entity.server_data.subject_type == "disguise" then
			local host = world.entities[entity.server_data.subject_of]
			if not team_mod.is_allied(world, host.owner, serialize_for.team) then
				copy.active = true
			end
		end
		if entity.server_data.always_visible or entity.server_data.always_visible_for[serialize_for.team] then
			copy.always_visible = true
		end
		value = copy :: Entity
		team_cache.entities[entity.id] = value
	end
	return value
end

return {
	serialize_entity = serialize_entity,
}
