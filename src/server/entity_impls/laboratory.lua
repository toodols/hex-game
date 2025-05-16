local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local types = require(ReplicatedStorage.Shared.types)
local coords = require(ReplicatedStorage.Shared.coords)
local server_types = require(ServerScriptService.Server.types)
local researches_mod = require(ReplicatedStorage.Shared.researches)
local entity_mod = require(ServerScriptService.Server.entity)

type Entity = types.Entity
type World = types.World
type ActionState = server_types.ActionState

local research_item = researches_mod.research_item

entity_mod.registry.laboratory = entity_mod.with_defaults {
	autogenerates_vertex = true,
	tick = function(self: Entity, world: World, action_state: ActionState) end,
	influences = function(self: Entity, world: World)
		local config = world.entity_configurations[self.type]
		local neighbors = coords.neighbors_leq(self.primary_coordinate, config.range)
		for _, coord in neighbors do
			local cell = world:get_cell(coord)
			if cell then
				cell.influences[self.id] = true
			end
		end
	end,
	init = function(self: Entity, world: World)
		self.researches = {
			queue = {},
			states = {
				-- turret = research_item {
				-- 	coord = { -1, 0, 1 },
				-- 	id = "turret",
				-- },
				proxy = research_item {
					coord = { -1, 1, 0 },
					id = "proxy",
				},
				fountain = research_item {
					coord = { 1, 0, -1 },
					id = "fountain",
				},
				heart = research_item {
					coord = { 0, -1, 1 },
					id = "heart",
				},
				vault = research_item {
					coord = { 1, -1, 0 },
					id = "vault",
				},
				taunt = research_item {
					coord = { 0, 1, -1 },
					id = "taunt",
				},
			},
		}
	end,
}

return {}
