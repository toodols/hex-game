local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local MainContext = require(script.Parent.context).MainContext
local types = require(ReplicatedStorage.Shared.types)

type World = types.World
type Entity = types.Entity

function use_immediate_effect(callback, dependencies: { any })
	local ref = React.useRef(dependencies)

	for i, dependency in dependencies do
		if ref.current[i] ~= dependency then
			callback()
			break
		end
	end
	ref.current = dependencies
end

function use_synced_entity(entity_id)
	local context = React.useContext(MainContext)
	local entity: Entity, set_entity = React.useState(context.world.entities[entity_id])
	React.useEffect(function()
		local cleanup = context.world.world_update_signal.listen(function(updates)
			for _, update in updates do
				if update.type == "entity_update" and update.entity.id == entity_id then
					set_entity(update.entity)
					return
				end
			end
		end)
		return cleanup
	end, {})
	return entity, set_entity
end

return {
	use_immediate_effect = use_immediate_effect,
	use_synced_entity = use_synced_entity,
}
