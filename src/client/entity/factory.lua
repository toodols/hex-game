local ReplicatedStorage = game:GetService "ReplicatedStorage"
local registry_mod = require(script.Parent.registry)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)

type Entity = types.Entity
type HexGrid = types.HexGrid

local model = asset_server.load "Entities/Factory"

registry_mod.registry["factory"] = registry_mod.with_defaults {
	model = model,
	update = function(self: Entity, grid: HexGrid, old: Entity) end,
	init = function(self: Entity, grid: HexGrid) end,
}

return {}
