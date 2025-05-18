local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local entity_mod = require(ReplicatedStorage.Client.entity)

type Entity = types.Entity
type World = types.World

entity_mod.registry.infinite_source = entity_mod.with_defaults {
	model = asset_server.load "Entities/InfiniteSource",
}

entity_mod.registry.phony = entity_mod.with_defaults {
	model = asset_server.load "Entities/Phony",
}

entity_mod.registry.laboratory = entity_mod.with_defaults {
	model = asset_server.load "Entities/Laboratory",
}

entity_mod.registry.obelisk = entity_mod.with_defaults {
	model = asset_server.load "Entities/Obelisk",
}

entity_mod.registry.witness = entity_mod.with_defaults {
	model = asset_server.load "Entities/Witness",
}

entity_mod.registry.suggestion = entity_mod.with_defaults {
	model = asset_server.load "Entities/Suggestion",
}

entity_mod.registry.impression = entity_mod.with_defaults {
	model = asset_server.load "Entities/Impression",
}

entity_mod.registry.taunt = entity_mod.with_defaults {
	model = asset_server.load "Entities/Taunt",
}

entity_mod.registry.heart = entity_mod.with_defaults {
	model = asset_server.load "Entities/Heart",
}

entity_mod.registry.barrier = entity_mod.with_defaults {
	model = asset_server.load "Entities/Barrier",
}

entity_mod.registry.generator = entity_mod.with_defaults {
	model = asset_server.load "Entities/Generator",
}

entity_mod.registry.solution = entity_mod.with_defaults {
	model = asset_server.load "Entities/Solution",
}

entity_mod.registry.proxy = entity_mod.with_defaults {
	model = asset_server.load "Entities/Proxy",
}

entity_mod.registry.factory = entity_mod.with_defaults {
	model = asset_server.load "Entities/Factory",
}

entity_mod.registry.extractor = entity_mod.with_defaults {
	model = asset_server.load "Entities/Extractor",
}

entity_mod.registry.fountain = entity_mod.with_defaults {
	model = asset_server.load "Entities/Fountain",
}

entity_mod.registry.terminal = entity_mod.with_defaults {
	model = asset_server.load "Entities/Terminal",
}

return {}
