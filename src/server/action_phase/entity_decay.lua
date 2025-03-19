local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local server_util = require(ServerScriptService.Server.util)
local util = require(ReplicatedStorage.Shared.util)
local updates_mod = require(ServerScriptService.Server.updates)
local server_entity_mod = require(ServerScriptService.Server.entity)

type World = types.World
type ActionState = server_types.ActionState

--- Decays entities that are not connected. Requires systems to be created
function do_entity_decay(world: World, action_state: ActionState)
	local decayable_entities = {}

	-- initially mark all decayable entities as decayable
	for _, entity in world:active_entities() do
		if
			world.global_configuration.decaying_enabled
			and entity.status ~= "blueprint"
			and entity.owner ~= world.neutral_team
			and entity.decayable
		then
			decayable_entities[entity.id] = true
		end
	end

	-- remove connected entities from decay
	for _, system in action_state.systems do
		local has_heart = false
		for entity_id in system.entities do
			local entity = world.entities[entity_id]
			if entity.type == "heart" or entity.type == "infinite_source" then
				has_heart = true
			end
		end

		for neighbor in
			server_util.get_neighbors_set(
				world,
				util.table_flat(util.table_map(util.table_keys(system.entities), function(id)
					return world.entities[id].coordinates
				end))
			)
		do
			if world.cells[neighbor] then
				for entity_id in world.cells[neighbor].entities do
					local entity = world.entities[entity_id]
					if entity.status == "scaffold" then
						decayable_entities[entity_id] = false
					end
				end
			end
		end

		for entity_id in system.entities do
			if has_heart then
				decayable_entities[entity_id] = false
			end
		end
	end

	-- make them decay
	for entity_id, should_decay in decayable_entities do
		local entity = world.entities[entity_id]
		if entity == nil then
			warn("entity not found", entity_id)
			continue
		end

		if should_decay then
			entity.is_decaying = true
			entity.decay += 1
			updates_mod.add_update(world, {
				type = "entity_update",
				entity = entity,
			})
			if entity.decay >= 3 then
				if entity.type == "wires" then
					server_entity_mod.remove_entity(world, entity)
				else
					entity.owner = world.neutral_team
					entity.decay = 0
					entity.is_decaying = false
				end
			end
		else
			if entity.is_decaying then
				entity.is_decaying = false
				entity.decay = 0
				updates_mod.add_update(world, {
					type = "entity_update",
					entity = entity,
				})
			end
		end
	end
end

return {
	do_entity_decay = do_entity_decay,
}
