local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local client_game_mod = require(ReplicatedStorage.Client.game)
local server_entity_mod = require(ServerScriptService.Server.entity)
local client_entity_mod = require(ReplicatedStorage.Client.entity)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local game_ui = require(ReplicatedStorage.Client.ui.game)
local presets = require(ServerScriptService.Server.presets)
local cleanup = require(ServerScriptService.Server.cleanup).cleanup

local tests = {}

function tests.render_world()
	local world = presets.my_map()
	client_game_mod.render_world(world)
	client_game_mod.step_animations(world)
	client_game_mod.destroy_world_instances(world)
	cleanup(world)
end

function tests.render_ui()
	local world = presets.my_map()
	local ui = game_ui.init_ui(world, Instance.new "ScreenGui")

	ui.destroy()
	cleanup(world)
end

function tests.all_entities_are_registered()
	for entity_type in shared_entity_mod.registry do
		if not client_entity_mod.registry[entity_type] then
			error(("Missing client entity for %s"):format(entity_type))
		end
		if not server_entity_mod.registry[entity_type] then
			error(("Missing server entity for %s"):format(entity_type))
		end
	end
	for entity_type in client_entity_mod.registry do
		if not shared_entity_mod.registry[entity_type] then
			error(("Missing shared entity for %s"):format(entity_type))
		end
		if not server_entity_mod.registry[entity_type] then
			error(("Missing server entity for %s"):format(entity_type))
		end
	end
	for entity_type in server_entity_mod.registry do
		if not shared_entity_mod.registry[entity_type] then
			error(("Missing shared entity for %s"):format(entity_type))
		end
		if not client_entity_mod.registry[entity_type] then
			error(("Missing client entity for %s"):format(entity_type))
		end
	end
end

return tests
