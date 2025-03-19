local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local registry_mod = require(script.Parent.registry)
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local researches_mod = require(ReplicatedStorage.Shared.researches)

type ActionState = server_types.ActionState
type Entity = types.Entity
type World = types.World

registry_mod.registry.extractor = registry_mod.with_defaults {
	autogenerates_vertex = true,
	built_on = { "bar_deposit", "vit_deposit", "rad_deposit", "tar_deposit" },
	init = function(self: Entity, world: World)
		self.should_output = 0
	end,
	tick = function(self: Entity, world: World, action_state: ActionState)
		local config = world.entity_configurations[self.type]
		if self.status == "complete" and self.enabled and self.owner ~= world.neutral_team then
			local cell = world:get_cell(self.primary_coordinate)

			-- local cell_researches = researches_mod.get_cell_researches(world, cell, self.owner)
			local is_boosted = false
			-- if cell_researches.extractor_boost then
			-- 	for entity_id in cell.server_data.influences do
			-- 		local entity = world.entities[entity_id]
			-- 		if entity.type == "generator" and entity.status == "complete" and entity.owner == self.owner then
			-- 			is_boosted = true
			-- 		end
			-- 	end
			-- end

			-- prevent extractor from missing out on output because there is no power
			local function ok()
				self.should_output = ((self.should_output :: any) + 1)
					% (if is_boosted then 1 else config.cycles_to_output)
			end
			if self.should_output == 0 then
				local items
				if cell.type == "bar_deposit" then
					items = { "bar" }
				elseif cell.type == "vit_deposit" then
					items = { "vit" }
				elseif cell.type == "rad_deposit" then
					items = { "rad" }
				elseif cell.type == "tar_deposit" then
					items = { "tar" }
				elseif cell.type == "basic" then
					warn "Extractor is placed on a basic cell. This might be a bug"
				end
				if items then
					table.insert(world.action_queue, {
						type = "exchange",
						input_power = config.input_power,
						output_items = items,
						entity_id = self.id,
						on_success = function()
							ok()
						end,
					})
				end
			else
				ok()
			end
		end
	end,
}

return {}
