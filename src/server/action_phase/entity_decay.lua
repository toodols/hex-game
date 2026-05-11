local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_util = require(ServerScriptService.Server.util)
local util = require(ReplicatedStorage.Shared.util)
local entity_mod = require(ServerScriptService.Server.entity)

type World = types.World

--- Decays entities that are not connected. Requires systems to be created
function do_entity_decay(world: World)
	local decayable_entities = {}

	-- initially mark all decayable entities as decayable
	for _, entity in world:active_entities() do
		if
			world.global_configuration.decaying_enabled
			and entity.status ~= "blueprint"
			and entity.owner ~= world.capturable_team
			-- and entity.owner ~= world.neutral_team
			and entity.decayable
		then
			decayable_entities[entity.id] = true
		end
	end

	-- remove connected entities from decay
	for _, system in world.systems do
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
			if system.heart_type ~= nil then
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
			world:add_update {
				type = "entity_update",
				entity = entity,
			}
			if entity.decay >= 3 then
				if entity.type == "vertex" then
					world:add_update {
						type = "entity_event",
						event_type = "destroy",
						entity_id = entity.id,
						death_type = "decay",
					}
					entity_mod.remove_entity(world, entity)
				else
					entity.owner = world.capturable_team
					entity.decay = 0
					entity.is_decaying = false
				end
			end
		else
			if entity.is_decaying then
				entity.is_decaying = false
				entity.decay = 0
				world:add_update {
					type = "entity_update",
					entity = entity,
				}
			end
		end
	end
end

return {
	do_entity_decay = do_entity_decay,
}
