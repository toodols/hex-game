local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)

type Entity = types.Entity
type World = types.World
type HexCell = types.HexCell
type AnimationState = types.AnimationState

local registry: { [string]: ClientEntityBehavior } = {}
type ClientEntityBehavior = {
	-- self is possibly nil so ui can create a model from entity type alone
	-- i don't like this behavior and i think a fake entity should be created instead
	model: Instance | (self: Entity?, world: World) -> Instance,

	-- this happens before the model is parented to workspace
	init: (self: Entity, world: World) -> (),

	-- subset of `update`, override to replace the default built animation
	status_changed: (self: Entity, world: World, old: Entity) -> (),

	neighbor_changed: (self: Entity, world: World) -> (),

	-- called before `self` is replaced by `new` in `world`
	update: (self: Entity, world: World, old: Entity) -> (),

	on_destroy: (self: Entity, world: World) -> (),
	on_hidden: (self: Entity, world: World) -> (),

	animate: ((self: Entity, world: World, animation_state: AnimationState) -> ())?,

	-- turn_start: (self: Entity, world: World, cell: HexCell) -> (),
}
local transparency = {
	blueprint = 0.7,
	scaffold = 0.3,
	complete = 0,
}

function with_defaults(t: any)
	return {
		model = t.model,
		init = t.init or function() end,
		neighbor_changed = t.neighbor_changed or function() end,

		status_changed = t.status_changed or function(self: Entity, world: World, old: Entity)
			local instance = world.entity_instance_map[self.id]
			if instance then
				for _, v in instance:GetDescendants() do
					if v:IsA "BasePart" then
						v.Transparency = transparency[self.status]
					end
				end
			end
		end,
		on_destroy = t.on_destroy or function(self: Entity, world: World)
			local instance: Instance = world.entity_instance_map[self.id]
			if instance then
				instance:Destroy()
			end
		end,
		on_hidden = t.on_hidden or function(self: Entity, world: World)
			local instance: Instance = world.entity_instance_map[self.id]
			if instance then
				instance:Destroy()
			end
		end,
		animate = t.animate,
		update = t.update or function(self: Entity, world: World, old: Entity)
			if self.type ~= self.type then
				-- oh no
			end
			-- if not util.deep_equal(self.queued_decisions, self.queued_decisions) then
			-- 	if
			-- 		util.table_find_pred(self.queued_decisions, function(action)
			-- 			return action.type == "deconstruct"
			-- 		end)
			-- 	then
			-- 	end
			-- end
		end,
	}
end

return { registry = registry, with_defaults = with_defaults, transparency = transparency }
