local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local registry_mod = require(script.Parent.registry)
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local researches_mod = require(ReplicatedStorage.Shared.researches)

type ActionState = server_types.ActionState
type Entity = types.Entity
type HexGrid = types.HexGrid

registry_mod.registry.extractor = registry_mod.with_defaults {
	autogenerates_vertex = true,
	built_on = { "bar_deposit", "vit_deposit", "rad_deposit", "tar_deposit" },
	init = function(self: Entity, grid: HexGrid)
		self.should_output = 0
	end,
	tick = function(self: Entity, grid: HexGrid, action_state: ActionState)
		local config = grid.entity_configurations[self.type]
		if self.status == "complete" and self.enabled and self.owner ~= grid.neutral_team then
			local cell = grid:get_cell(self.primary_coordinate)

			-- local cell_researches = researches_mod.get_cell_researches(grid, cell, self.owner)
			local is_boosted = false
			-- if cell_researches.extractor_boost then
			-- 	for entity_id in cell.server_data.influences do
			-- 		local entity = grid.entities[entity_id]
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
					table.insert(grid.action_queue, {
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
