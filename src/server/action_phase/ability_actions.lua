local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)

local util = require(ReplicatedStorage.Shared.util)

local abilities = require(ServerScriptService.Server.abilities).abilities

type World = types.World
type Entity = types.Entity
type EntityAction = types.EntityAction

function handle_ability_actions(world: World)
	for _, interaction in
		util.table_extract(world.action_queue, function(value)
			return (value.type == "ability")
		end)
	do
		local entity = world.entities[interaction.entity_id]
		local config = world.entity_configurations[entity.type]
		local ability = config.abilities[interaction.ability_id]
		if abilities[ability.type] == nil then
			error("Unknown ability type " .. ability.type)
		end
		abilities[ability.type](world, entity, ability, interaction)
	end
end

return {
	handle_ability_actions = handle_ability_actions,
}
