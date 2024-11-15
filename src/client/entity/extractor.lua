local ReplicatedStorage = game:GetService "ReplicatedStorage"
local registry_mod = require(script.Parent.registry)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local types = require(ReplicatedStorage.Shared.types)

type Entity = types.Entity
type HexGrid = types.HexGrid

local model = asset_server.load "Entities/Extractor"
registry_mod.registry.extractor = registry_mod.with_defaults {
	model = model,
}
return {}
