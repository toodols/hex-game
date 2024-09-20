local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)

type Entity = types.Entity
type HexGrid = types.HexGrid
type HexCell = types.HexCell
type AnimationState = types.AnimationState

local registry: { [string]: ClientEntityBehavior } = {}
type ClientEntityBehavior = {
	model: Instance,

	-- this happens before the model is parented to workspace
	init: (self: Entity, grid: HexGrid) -> (),

	-- subset of `update`, override to replace the default built animation
	status_changed: (self: Entity, grid: HexGrid, old: Entity) -> (),

	neighbor_changed: (self: Entity, grid: HexGrid) -> (),

	-- called before `self` is replaced by `new` in `grid`
	update: (self: Entity, grid: HexGrid, old: Entity) -> (),

	on_destroy: (self: Entity, grid: HexGrid) -> (),
	on_hidden: (self: Entity, grid: HexGrid) -> (),

	animate: ((self: Entity, grid: HexGrid, animation_state: AnimationState) -> ())?,

	-- turn_start: (self: Entity, grid: HexGrid, cell: HexCell) -> (),
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

		status_changed = t.status_changed or function(self: Entity, grid: HexGrid, old: Entity)
			local instance = grid.entity_instance_map[self.id]
			if instance then
				for _, v in instance:GetDescendants() do
					if v:IsA "BasePart" then
						v.Transparency = transparency[self.status]
					end
				end
			end
		end,
		on_destroy = t.on_destroy or function(self: Entity, grid: HexGrid)
			local instance: Instance = grid.entity_instance_map[self.id]
			if instance then
				instance:Destroy()
			end
		end,
		on_hidden = t.on_hidden or function(self: Entity, grid: HexGrid)
			local instance: Instance = grid.entity_instance_map[self.id]
			if instance then
				instance:Destroy()
			end
		end,
		animate = t.animate,
		update = t.update or function(self: Entity, grid: HexGrid, old: Entity)
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
