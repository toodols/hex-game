local ReplicatedStorage = game:GetService "ReplicatedStorage"
local registry_mod = require(script.Parent.registry)
local types = require(ReplicatedStorage.Shared.types)
local asset_server = require(ReplicatedStorage.Shared.asset_server)

type Entity = types.Entity
type HexGrid = types.HexGrid

local model = asset_server.load "Entities/Solution"

registry_mod.registry["solution"] = registry_mod.with_defaults {
	model = model,
}

return {}
