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

type SerializeTarget = server_types.SerializeTarget
type SerializationContext = server_types.SerializationContext

function serialize_entity(
	world: World,
	se_ctx: SerializationContext,
	serialize_target: SerializeTarget,
	entity: Entity
): Entity?
	if serialize_target.team == nil then
		return entity
	end

	local value
	local team_cache = get_cache(se_ctx, { team = serialize_target.team })
	if team_cache.entities[entity.id] ~= nil then
		return team_cache.entities[entity.id]
	end
	if visibility.entity_visibility(world, serialize_target, entity) then
		local team_data = world.teams[serialize_target.team]
		assert(team_data, "no team")
		local to_copy = entity
		local copy = {}
		for k, v in to_copy do
			if k == "server_data" then
			elseif k == "queued_decisions" then
				if
					team_mod.is_allied(world, entity.owner, serialize_target.team)
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
		if entity.server_data.parent ~= nil and entity.server_data.child_relationship == "disguise" then
			local host = world.entities[entity.server_data.parent]
			if not team_mod.is_allied(world, host.owner, serialize_target.team) then
				copy.active = true
			end
		end
		if entity.server_data.always_visible or entity.server_data.always_visible_for[serialize_target.team] then
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
