local ReplicatedStorage = game:GetService "ReplicatedStorage"
local registry_mod = require(script.Parent.registry)
local types = require(ReplicatedStorage.Shared.types)
local asset_server = require(ReplicatedStorage.Shared.asset_server)

type Entity = types.Entity
type HexGrid = types.HexGrid

local model = asset_server.load "Entities/Phony"

registry_mod.registry.phony = registry_mod.with_defaults {
	model = model,
	update = function(self: Entity, grid: HexGrid, old: Entity)
		if self.disguise then
			if old.disguise then
				if old.disguise.id ~= self.disguise.id then
					-- different entity, delete old disguise and create new one
				end	
			else
				-- create new disguise
			end	
		elseif old.disguise then
			-- delete current disguise, replace with base phony model
		end	
	end,
	init = function(self: Entity, grid: HexGrid) end,
}

return {}
